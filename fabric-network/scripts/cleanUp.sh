# relative import to network.sh
source scripts/utils.sh

ROOT=$PWD

# Obtain CONTAINER_IDS and remove them
# This function is called when you bring a network down
clearContainers() {
    infoln "Removing remaining containers"
    docker rm -f $(docker ps -aq --filter network=news-network) 2>/dev/null || true
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# This function is called when you bring the network down
removeUnwantedImages() {
    infoln "Removing generated chaincode docker images"
    docker image rm -f $(docker images -aq --filter reference='dev-peer*') 2>/dev/null || true
}

pruneVolumes() {
    infoln "Removing all docker volumes"
    docker volume prune -f
}

removeFiles() {
    infoln "Removing network files"
    rmFile log.txt newsnet.tar.gz
    rmFile ./artifacts/channel/*.tx
    rmFile ./artifacts/channel/genesis.block
    rmDir ./artifacts/channel/crypto-config
}

clearContainers
removeUnwantedImages
removeFiles
pruneVolumes
