# generate configurations
cryptogen generate --config=./crypto-config.yaml --output=crypto-config

SYS_CHANNEL="sys-channel"
CHANNEL_NAME="mainchannel"

# generate genesis block
configtxgen --profile OrdererGenesis -configPath . -channelID $SYS_CHANNEL -outputBlock ./genesis.block
# generate channel configuration block
configtxgen --profile Channel -configPath . -outputCreateChannelTx ./mainchannel.tx -channelID $CHANNEL_NAME

# generate anchore peers

# citizen
configtxgen --profile Channel -configPath . -outputAnchorPeersUpdate ./CitizenMSPanchors.tx -channelID $CHANNEL_NAME -asOrg CitizenMSP
# PCI
configtxgen --profile Channel -configPath . -outputAnchorPeersUpdate ./PCIMSPanchors.tx -channelID $CHANNEL_NAME -asOrg PCIMSP
# ICMR
configtxgen --profile Channel -configPath . -outputAnchorPeersUpdate ./ICMRMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ICMRMSP
# MOH
configtxgen --profile Channel -configPath . -outputAnchorPeersUpdate ./MOHMSPanchors.tx -channelID $CHANNEL_NAME -asOrg MOHMSP

# replace all the '\' to '/'
# https://stackoverflow.com/questions/59051684/failed-to-load-certificates-while-trying-to-create-channel-following-hyperledger
find ./crypto-config -type f -name "config.yaml" -exec sed -i 's/\\/\//g' {} \;
