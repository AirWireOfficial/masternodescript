#/bin/bash
sudo pkill -f "wired"
sudo service wired stop
sleep 5
sudo rm /usr/local/bin/wired
sudo rm /usr/local/bin/wire-cli
sudo mv /home/masternode/.wire/wire.conf ./
sudo rm -rf /home/masternode/.wire/*
sudo mv ./wire.conf /home/masternode/.wire/
wget https://github.com/AirWireOfficial/wire-core/releases/download/1.4.2/wire-1.4.2-x86_64-linux-gnu.tar.gz
tar xvf ./wire-1.4.2-x86_64-linux-gnu.tar.gz
sudo mv ./wire-1.4.2/bin/wire-cli /usr/local/bin
sudo mv ./wire-1.4.2/bin/wired /usr/local/bin
wget https://github.com/AirWireOfficial/masternodescript/releases/download/snapshot/snapshot.tar.gz
tar zxvf ./snapshot.tar.gz
sudo mv ./blocks/ /home/masternode/.wire/
sudo mv ./chainstate/ /home/masternode/.wire/
sudo chown -R masternode /home/masternode/.wire/
rm ./snapshot.tar.gz
sudo service wired start
