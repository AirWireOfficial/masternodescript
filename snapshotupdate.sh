service wired stop
wget https://github.com/AirWireOfficial/wire-core/releases/download/1.3.0/snapshot.tar.gz
tar zxvf ./snapshot.tar.gz
rm -rf /home/masternode/.wire/blocks/
rm -rf /home/masternode/.wire/chainstate/
mv ./blocks/ /home/masternode/.wire/
mv ./chainstate/ /home/masternode/.wire/
chown -R masternode /home/masternode/.wire/
rm ./snapshot.tar.gz
service wired start
