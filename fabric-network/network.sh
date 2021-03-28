#!/usr/bin/env bash

source scripts/utils.sh
source scripts/envVar.sh

ROOT=$PWD

networkUp() {
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

    infoln '############## 🚀Success👩‍🚀 #################'
    infoln "💾couchdb instances"
    infoln -e 'Citizen\t http://localhost:5984/_utils/'
    infoln -e 'PCI\t http://localhost:6984/_utils/'
    infoln -e 'ICMR\t http://localhost:7984/_utils/'
    infoln -e 'MOH\t http://localhost:8984/_utils/'
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
