#/bin/bash

# This script updates script and manual based WIRE masternode installs.

UVER=18;
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

sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Options::=--force-confdef -y install unzip

# Download WIRE
echo && echo "Downloading v1.4 WIRE binary"
sleep 1
if [[ ("$UVER" == "16") ]]; then
    wget https://github.com/AirWireOfficial/wire-core/files/2800487/wire-linux.zip
    unzip wire-linux.zip
else
    wget https://github.com/AirWireOfficial/wire-core/releases/download/1.4.0/wire-linux-1.4-18.04.tar.gz
    tar -xzvf ./wire-linux-1.4-18.04.tar.gz
fi

chmod +x ./wire-cli
chmod +x ./wired
chmod +x ./wire-tx

echo && echo "Stopping WIRE daemon"


sudo service wired stop



sleep 5

echo && echo "Installing 1.4."

sudo mv ./wire-cli /usr/local/bin
sudo mv ./wired /usr/local/bin
sudo mv ./wire-tx /usr/local/bin

sudo service wired start

echo && echo "WIRE 1.4 Update complete. You need to restart the masternode from the personal wallet. THEN, you need to log back in and restart the wallet by using this command..."
echo && echo "sudo service wired restart"
