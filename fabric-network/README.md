# Fabric Network

This is the Hyperledger fabric network.

## Setup the Hyperledger fabric network

1) Run the script to start the network and initilize docker containers

    ```shell
    ./setup-network.sh
    ```

    This script creates channel configuration files and brings up the docker containers.

2) Create the channel and join peer

    ```shell
    ./createChannel.sh
    ```

    This script creates `mainchannel` and joins all the peers to that network.

3) Clean up the files.

    ```shell
    ./cleanUp.sh
    ```

    This script removes all the `crypto-config` `.tx` and `*.block` files from `./artifacts/channel/`.
