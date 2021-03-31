#!/usr/bin/env bash

source scripts/utils.sh
source scripts/envVar.sh

set -e

ROOT=$PWD

networkUp() {
    infoln "Bringing down previous network"
    networkDown

    infoln "Creating CA Containers" # bring up ca containers
    cd artifacts/channel/create-ca
    docker-compose up -d
    verifyResult $? "CA Container creation failed"
    sleep 5s

    # create certifacts
    infoln "Creating CA Certificates"
    . ./create-ca-cert.sh
    verifyResult $? "CA Certificates Creation failed"
    cd $ROOT

    # creates required artifacts
    infoln 'Creating Artifacts'
    cd artifacts/channel/
    ./create-artifacts.sh
    verifyResult $? "Artifacts creation failed"
    cd $ROOT

    # runs docker containers
    infoln '🏃‍♀️🚢 Starting Containers'
    cd artifacts
    docker-compose up -d
    verifyResult $? "Failed to start containers"
    cd $ROOT

    # create and join channel
    infoln '🔧 Creating channel'
    sleep 6s
    . ./scripts/createChannel.sh
    verifyResult $? "Channel creation failed"

    # deploy chaincode
    infoln '🚀 Deploying chaincode '

    # values
    CHANNEL_NAME=mainchannel
    CC_NAME=newsnet
    CC_SRC_PATH=../chaincode/news_cc/
    CC_SRC_LANGUAGE=javascript
    CC_VERSION=v1.0

    . ./scripts/deployCC.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE
    verifyResult $? "Chaincode deployment failed"

    infoln "Containers List"

    docker ps -f network=news-network --format "table {{.ID}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"

    infoln '############## 🚀Success👩‍🚀 #################'
    infoln "💾couchdb instances"
    infoln "Citizen    http://localhost:5984/_utils/"
    infoln "PCI        http://localhost:6984/_utils/"
    infoln "ICMR       http://localhost:7984/_utils/"
    infoln "MOH        http://localhost:8984/_utils/"

    exit 0
}

networkDown() {
    . ./scripts/cleanUp.sh
}

if [ $# -eq 0 ]; then
    echo "network.sh [up | down]"
    echo -e "\n"
    echo -e " up:\t Brings up the network and installs chaincode"
    echo -e " down:\t Brings down the network and cleans up the files"
    echo -e "\n"
    exit 0
fi

if [ $1 = "up" ]; then
    infoln "Bringing Network Up"
    networkUp
elif [ $1 = "down" ]; then
    infoln "Bringing Network down"
    networkDown
fi
