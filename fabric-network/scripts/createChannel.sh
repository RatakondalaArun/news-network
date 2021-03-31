# imports
source scripts/utils.sh

set -e

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_CITIZEN_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/ca.crt
export PEER0_PCI_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/ca.crt
export PEER0_ICMR_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/ca.crt
export PEER0_MOH_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/artifacts/channel/config/

export CHANNEL_NAME=mainchannel

setGlobalsForOrderer() {
    export CORE_PEER_LOCALMSPID="OrdererMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp
}

setGlobalsForPeer0Citizen() {
    export CORE_PEER_LOCALMSPID="CitizenMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_CITIZEN_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/citizen.example.com/users/Admin@citizen.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer0PCI() {
    export CORE_PEER_LOCALMSPID="PCIMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_PCI_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/pci.example.com/users/Admin@pci.example.com/msp
    export CORE_PEER_ADDRESS=localhost:8051
}

setGlobalsForPeer0ICMR() {
    export CORE_PEER_LOCALMSPID="ICMRMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ICMR_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/icmr.example.com/users/Admin@icmr.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
}

setGlobalsForPeer0MOH() {
    export CORE_PEER_LOCALMSPID="MOHMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MOH_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/crypto-config/peerOrganizations/moh.example.com/users/Admin@moh.example.com/msp
    export CORE_PEER_ADDRESS=localhost:10051
}

createChannel() {
    infoln "Removing previous channel artifacts"
    rm -rf ./channel-artifacts/*

    infoln "Creating channel"
    setGlobalsForPeer0Citizen

    peer channel create -o localhost:7050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ./artifacts/channel/${CHANNEL_NAME}.tx \
    --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

joinChannel() {
    infoln "Joining Citizen peer0"
    setGlobalsForPeer0Citizen
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    verifyResult $? "Joining Citizen peer0 failed"

    infoln "Joining PCI peer0"
    setGlobalsForPeer0PCI
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    verifyResult $? "Joining PCI peer0 failed"

    infoln "Joining ICMR peer0"
    setGlobalsForPeer0ICMR
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    verifyResult $? "Joining ICMR peer0 failed"

    infoln "Joining MOH peer0"
    setGlobalsForPeer0MOH
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    verifyResult $? "Joining MOH peer0 failed"

}

updateAnchorPeers() {
    infoln "Updating Citizen peer0"
    setGlobalsForPeer0Citizen
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    verifyResult $? "Updating Citizen peer0 failed"

    infoln "Updating Citizen peer0"
    setGlobalsForPeer0PCI
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    verifyResult $? "Updating PCI peer0 failed"

    infoln "Updating ICMR peer0"
    setGlobalsForPeer0ICMR
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    verifyResult $? "Updating ICMR peer0 failed"

    infoln "Updating MOH peer0"
    setGlobalsForPeer0MOH
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    verifyResult $? "Updating MOH peer0 failed"
}
infoln "🏃‍♀️🏃‍♂️ Creating Channel"
createChannel
verifyResult $? "Channel creation Failed"

echo "🏃‍♀️🏃‍♂️ Joining Channel"
joinChannel
verifyResult $? "Joining Channel Failed"

echo "🏃‍♀️🏃‍♂️ Updating Anchor peers"
updateAnchorPeers
verifyResult $? "Updating Anchor peers Failed"

successln "Channel Creation Success"
