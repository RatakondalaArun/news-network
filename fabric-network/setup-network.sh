#!/usr/bin/env bash

ROOT=$PWD

# creates required artifacts
echo '############## 🏗 Creating Artifacts ###############'
cd artifacts/channel/
./create-artifacts.sh
cd $ROOT

# runs docker containers
echo '############## 🏃‍♀️🏃‍♂️ Running Containers #################'
cd artifacts
docker-compose up -d
cd $ROOT

# create and join channel
# echo '############## 🏃‍♀️🏃‍♂️ Setting up channel #################'
# ./createChannel.sh

echo '############## 🚀Success👩‍🚀 #################'

echo "💾couchdb instances"

echo -e 'Citizen\t http://localhost:5984/_utils/'
echo -e 'PCI\t http://localhost:6984/_utils/'
echo -e 'ICMR\t http://localhost:7984/_utils/'
echo -e 'MOH\t http://localhost:8984/_utils/'
