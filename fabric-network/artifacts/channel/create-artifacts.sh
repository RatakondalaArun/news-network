source ./create-ca/scripts/utils.sh

# Delete existing artifacts
rm genesis.block mainchannel.tx
rm -rf ../../channel-artifacts/*

set -e
#Generate Crypto artifactes for organizations
# cryptogen generate --config=./crypto-config.yaml --output=./crypto-config/

# System channel
SYS_CHANNEL="sys-channel"

# channel name defaults to "mainchannel"
CHANNEL_NAME="mainchannel"

infoln $CHANNEL_NAME

infoln "Generate System Genesis block"
configtxgen -profile OrdererGenesis -configPath . -channelID $SYS_CHANNEL -outputBlock ./genesis.block
verifyResult $? "Failed Generate System Genesis block"

infoln "Generate channel configuration block"
configtxgen -profile BasicChannel -configPath . -outputCreateChannelTx ./mainchannel.tx -channelID $CHANNEL_NAME
verifyResult $? "Failed Generate channel configuration block"

infoln "Generating anchor peer update for Citizen"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./CitizenMSPanchors.tx -channelID $CHANNEL_NAME -asOrg CitizenMSP
verifyResult $? "Failed Generating anchor peer update for Citizen"

infoln "Generating anchor peer update for PCI"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./PCIMSPanchors.tx -channelID $CHANNEL_NAME -asOrg PCIMSP
verifyResult $? "Failed Generating anchor peer update for PCI"

infoln "Generating anchor peer update for ICMR"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./ICMRMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ICMRMSP
verifyResult $? "Failed Generating anchor peer update for ICMR"

infoln "Generating anchor peer update for MOH"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./MOHMSPanchors.tx -channelID $CHANNEL_NAME -asOrg MOHMSP
verifyResult $? "Failed Generating anchor peer update for MOH"

successln "Artifacts created Successfully"
