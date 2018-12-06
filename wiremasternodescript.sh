#/bin/bash

# This script was made by Aron Schatz. It is heavily inspired by Galactrum.

# Run it: wget https://cdn.rawgit.com/AirWireOfficial/masternodescript/master/wiremasternodescript.sh && chmod +x ./wiremasternodescript.sh && ./wiremasternodescript.sh && source ~/.bash_aliases

# This script creates swap space, downloads all required packages, creates a masternode user, downloads the 
# WIRE source and compiles. It then moves the binary to a system wide folder and installs a systemd script to have it autostart on boot. Aliases are created to always use the same conf directory. Use wire-cli to interact with the client.

# This script creates swap space, downloads all required packages, creates a masternode user, and downloads the 
# WIRE binaries. It then moves the binary to a system wide folder and installs a systemd script to have it autostart on boot. Aliases are created to always use the same conf directory. Use wire-cli to interact with the client.

clear

#Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'


UVER=18;

clear
cd ~
echo "**********************************************************************"
echo "* Ubuntu 18.04 or 16.04 (x64) is the required opearting system for   *"
echo "* this install.                                                      *"
echo "*                                                                    *"
echo "* WIRE script based masternode installation.                         *"
echo "*                                                                    *"
echo "* Need help? Join the WIRE Discord: https://discord.gg/2482aX        *"
echo "*                                                                    *"
echo "* Root or sudo access is required for installation!                  *"
echo "*                                                                    *"
echo "* S v1.1  W v1.3                              Created by Aron Schatz *"
echo "**********************************************************************"
echo && echo && echo

echo "Setting up initial environment..."

sudo apt-get -y -qq update
sudo apt-get -y -qq install dnsutils

clear

echo "**********************************************************************"
echo "* Ubuntu 18.04 or 16.04 (x64) is the required opearting system for   *"
echo "* this install.                                                      *"
echo "*                                                                    *"
echo "* WIRE script based masternode installation.                         *"
echo "*                                                                    *"
echo "* Need help? Join the WIRE Discord: https://discord.gg/2482aX        *"
echo "*                                                                    *"
echo "* Root or sudo access is required for installation!                  *"
echo "*                                                                    *"
echo "* S v1.1  W v1.3                              Created by Aron Schatz *"
echo "**********************************************************************"
echo && echo && echo

#Check LSB release
if [[ !($(lsb_release -d) == *16.04* || $(lsb_release -d) == *18.04*) ]]; then
    echo -e "${RED}This operating system is not Ubuntu 16.04 or 18.04. Aborting.${NC}"
    exit 1
fi

if [[ ($(lsb_release -d) == *16.04*) ]]; then
    UVER=16;
    echo "Detected Ubuntu 16.04..."    
else
    echo "Detected Ubuntu 18.04..."
fi
echo
sleep 1

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 18.04 or 16.04?"  >&2; exit 1; }

# Gather input from user
read -e -p "Enter Masternode Private Key (e.g. 87PUDuUHk114BW46LLtCn2wWUKyVSCt23rmEQsqTYvJqQjTZtaz) : " key
if [[ "$key" == "" ]]; then
    echo "WARNING: No private key entered, exiting!!!"
    echo && exit
fi


ip="$(dig @resolver1.opendns.com ANY myip.opendns.com +short)"
regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'

if [[ $ip =~ $regex ]]; then
    ip="[$ip]"
fi
read -e -p "The script detected this server IP as '${ip}'. Press enter if this is correct or manually enter the correct IP : " ipcheck
if [[ ! -z $ipcheck ]]; then
    ip=$ipcheck
fi



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

# Add Berkely PPA
echo && echo "Installing bitcoin PPA..."
sleep 1
sudo apt-get -y install software-properties-common
sudo apt-add-repository -y ppa:bitcoin/bitcoin
sudo apt-get -y update

# Install required packages
echo && echo "Installing base packages..."
sleep 1
sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Options::=--force-confdef -y install git libevent-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev libdb4.8-dev libdb4.8++-dev libminiupnpc-dev virtualenv python-pip dh-autoreconf pkg-config build-essential libssl-dev libzmq3-dev libgmp3-dev libminiupnpc-dev ufw unzip
sleep 1

# Update system 
echo && echo "Upgrading system..."
sleep 1
sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Options::=--force-confdef -y upgrade

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
echo && echo "Downloading v1.3 WIRE binary and installing"
sleep 1
if [[ ("$UVER" == "16") ]]; then
    wget https://github.com/AirWireOfficial/wire-core/files/2446021/wire-linux-16.04-1.3.0.0.zip
    unzip wire-linux-16.04-1.3.0.0.zip
else
    wget https://github.com/AirWireOfficial/wire-core/releases/download/1.3.0/wire-ubuntu-18.04.v1.3.tar.gz
    tar -xzvf ./wire-ubuntu-18.04.v1.3.tar.gz
fi

chmod +x ./wire-cli
chmod +x ./wired
chmod +x ./wire-tx

# Install WIRE
echo && echo "Installing WIRE..."
sleep 1
sudo mv ./wire-cli /usr/local/bin
sudo mv ./wired /usr/local/bin
sudo mv ./wire-tx /usr/local/bin

# Create config for WIRE
echo && echo "Configuring WIRE v1.3..."
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
addnode=51.158.72.177
addnode=51.15.224.33
addnode=51.15.254.91
addnode=159.69.188.123
addnode=95.216.166.46
addnode=95.216.191.165
addnode=95.216.188.154
addnode=x73pexnfmsnbhmea.onion:6520
addnode=fiyylquk6ujdl6io.onion:6520
addnode=5bozrozfrdmn6fws.onion:6520
addnode=ukbd5bedakhsc4wj.onion:6520
addnode=cssqmp3pl4ujm3zd.onion:6520
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
sleep 1

echo && echo "Setup has completed."

