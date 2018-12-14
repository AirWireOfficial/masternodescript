wire-cli stop
wget https://github.com/AirWireOfficial/wire-core/releases/download/1.3.0/snapshot.tar.gz
tar zxvf ./snapshot.tar.gz
rm -rf ~/.wire/blocks/
rm -rf ~/.wire/chainstate/
mv ./blocks/ ~/.wire/
mv ./chainstate/ ~/.wire/
rm ./snapshot.tar.gz
wired -daemon
