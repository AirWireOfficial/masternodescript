#/bin/bash

# This script was made by Aron Schatz. It is heavily inspired by Galactrum.

# Run it: wget https://cdn.rawgit.com/Social-Wallet-Inc/masternodescript/master/wiremasternodescript.sh && chmod +x ./wiremasternodescript.sh && ./wiremasternodescript.sh && source ~/.bash_aliases

# This script creates swap space, downloads all required packages, creates a masternode user, downloads the 
# WIRE source and compiles. It then moves the binary to a system wide folder and installs a systemd script to have it autostart on boot. Aliases are created to always use the same conf directory. Use wire-cli to interact with the client.

clear
cd ~
echo "**********************************************************************"
echo "* Ubuntu 16.04 is the required opearting system for this install.    *"
echo "*                                                                    *"
echo "* WIRE script based masternode installation.                         *"
echo "*                                                                    *"
echo "* Need help? Join the WIRE Discord: https://discord.gg/2482aX        *"
echo "*                                                                    *"
echo "* Root or sudo access is required for installation!                  *"
echo "*                                                                    *"
echo "*                                             Created by Aron Schatz *"
echo "**********************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                     !"
echo "! Please read each step before blindly hitting enter! !"
echo "!                                                     !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo
sleep 1

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Gather input from user
read -e -p "Enter Masternode Private Key (e.g. 87PUDuUHk114BW46LLtCn2wWUKyVSCt23rmEQsqTYvJqQjTZtaz) : " key
if [[ "$key" == "" ]]; then
    echo "WARNING: No private key entered, exiting!!!"
    echo && exit
fi
read -e -p "What is the this server's IP Address? : " ip
echo && echo "Pressing ENTER will use the default value for the next prompts."
echo && sleep 1
read -e -p "Add swap space? (Recommended) [Y/n] : " add_swap
if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
    read -e -p "Swap Size [2G] : " swap_size
    if [[ "$swap_size" == "" ]]; then
        swap_size="2G"
    fi
fi    

# Add swap if needed
if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
    if [ ! -f /swapfile ]; then
        echo && echo "Adding swap space..."
        sleep 1
        sudo fallocate -l $swap_size /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.vfs_cache_pressure=50
        echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
        echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    else
        echo && echo "WARNING: Swap file detected, skipping add swap!"
        sleep 1
    fi
fi


# Add masternode group and user
sudo groupadd masternode
sudo useradd -m -g masternode masternode

# Update system 
echo && echo "Upgrading system..."
sleep 1
sudo apt-get -y update
sudo apt-get -y upgrade

# Add Berkely PPA
echo && echo "Installing bitcoin PPA..."
sleep 1
sudo apt-get -y install software-properties-common
sudo apt-add-repository -y ppa:bitcoin/bitcoin
sudo apt-get -y update

# Install required packages
echo && echo "Installing base packages..."
sleep 1
sudo apt-get -y install git libevent-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev libdb4.8-dev libdb4.8++-dev libminiupnpc-dev virtualenv python-pip dh-autoreconf pkg-config build-essential libssl-dev libzmq3-dev libgmp3-dev libminiupnpc-dev ufw
sleep 1

# Configure Firewall

echo && echo "Configuring UFW..."
sleep 1
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 6520/tcp
echo "y" | sudo ufw enable
echo && echo "Firewall installed and enabled!"


# Download WIRE
echo && echo "Downloading latest WIRE source and compiling..."
sleep 1
git clone https://github.com/Social-Wallet-Inc/wire-core.git
cd wire-core
./autogen.sh
./configure
make
cd src
strip ./wire-cli
strip ./wired
strip ./wire-tx

# Install WIRE
echo && echo "Installing WIRE..."
sleep 1
sudo mv ./wire-cli /usr/local/bin
sudo mv ./wired /usr/local/bin
sudo mv ./wire-tx /usr/local/bin

# Create config for WIRE
echo && echo "Configuring WIRE v1.0..."
sleep 1
rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
rpcpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
sudo mkdir -p /home/masternode/.wire
sudo touch /home/masternode/.wire/wire.conf
echo '
rpcuser='$rpcuser'
rpcpassword='$rpcpassword'
rpcallowip=127.0.0.1
listen=1
server=1
daemon=0 # required for systemd
logtimestamps=1
maxconnections=256
externalip='$ip'
masternodeprivkey='$key'
masternode=1

#addnodes
addnode=108.61.95.114
addnode=45.77.193.238
addnode=45.32.133.67
addnode=108.160.134.29
addnode=207.148.86.107
addnode=45.63.114.212
addnode=45.32.22.184
addnode=108.61.23.114
addnode=104.156.254.203
addnode=63.211.111.86
addnode=144.202.78.8
addnode=104.156.225.63
addnode=173.199.71.62
addnode=108.160.138.246
addnode=45.77.0.247
addnode=45.76.152.225
addnode=144.202.8.219
addnode=149.28.168.14
addnode=108.61.224.93
addnode=45.77.189.225
addnode=45.76.232.61
addnode=45.77.56.227
addnode=149.28.37.186
addnode=217.69.7.75
addnode=202.182.107.213
' | sudo -E tee /home/masternode/.wire/wire.conf
sudo chown -R masternode:masternode /home/masternode/.wire

# Setup systemd service
echo && echo "Starting WIRE daemon..."
sleep 1
sudo touch /etc/systemd/system/wired.service
echo '[Unit]
Description=wired
After=network.target

[Service]
Type=simple
User=masternode
WorkingDirectory=/home/masternode
ExecStart=/usr/local/bin/wired -conf=/home/masternode/.wire/wire.conf -datadir=/home/masternode/.wire
ExecStop=/usr/local/bin/wire-cli -conf=/home/masternode/.wire/wire.conf -datadir=/home/masternode/.wire stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
' | sudo -E tee /etc/systemd/system/wired.service
sudo systemctl enable wired
sudo systemctl start wired



# Add alias to run wire-cli for this user

touch ~/.bash_aliases
echo "alias wire-cli='wire-cli -conf=/home/masternode/.wire/wire.conf -datadir=/home/masternode/.wire'" | tee -a ~/.bash_aliases
alias wire-cli='wire-cli -conf=/home/masternode/.wire/wire.conf -datadir=/home/masternode/.wire'
source ~/.bash_aliases

clear
echo "WIRE Masternode setup complete!"
echo && echo "Wait until the blockchain syncs before starting your masternode from the personal wallet."


source ~/.bash_aliases
