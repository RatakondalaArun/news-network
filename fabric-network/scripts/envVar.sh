#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
source utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_CITIZEN_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/ca.crt
export PEER0_PCI_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/ca.crt
export PEER0_ICMR_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/ca.crt
export PEER0_MOH_CA=${PWD}/artifacts/channel/crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/ca.crt
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

# Set environment variables for the peer org
setGlobals() {
    local USING_ORG=""
    if [ -z "$OVERRIDE_ORG" ]; then
        USING_ORG=$1
    else
        USING_ORG="${OVERRIDE_ORG}"
    fi

    infoln "Using organization ${USING_ORG}"
    if [ $USING_ORG == "Citizen" ]; then
        setGlobalsForPeer0Citizen
    elif [ $USING_ORG == "PCI" ]; then
        setGlobalsForPeer0PCI
    elif [ $USING_ORG == "ICMR" ]; then
        setGlobalsForPeer0ICMR
    elif [ $USING_ORG == "MOH" ]; then
        setGlobalsForPeer0MOH
    else
        errorln "ORG Unknown"
    fi

    if [ "$VERBOSE" == "true" ]; then
        env | grep CORE
    fi
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
    setGlobals $1

    local USING_ORG=""
    if [ -z "$OVERRIDE_ORG" ]; then
        USING_ORG=$1
    else
        USING_ORG="${OVERRIDE_ORG}"
    fi

    if [ $USING_ORG == "Citizen" ]; then
        export CORE_PEER_ADDRESS=peer0.citizen.example.com:7051
    elif [ $USING_ORG == "PCI" ]; then
        export CORE_PEER_ADDRESS=peer0.pci.example.com:8051
    elif [ $USING_ORG == "ICMR" ]; then
        export CORE_PEER_ADDRESS=peer0.icmr.example.com:9051
    elif [ $USING_ORG == "MOH" ]; then
        export CORE_PEER_ADDRESS=peer0.moh.example.com:10051
    else
        errorln "ORG Unknown"
    fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
    PEER_CONN_PARMS=()
    PEERS=""
    while [ "$#" -gt 0 ]; do
        setGlobals $1
        PEER="peer0.$1"
        ## Set peer addresses
        if [ -z "$PEERS" ]; then
            PEERS="$PEER"
        else
            PEERS="$PEERS $PEER"
        fi
        PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
        ## Set path to TLS certificate
        if [ $1 == "Citizen" ]; then
            CA=PEER0_CITIZEN_CA
        else
            CA=PEER0_$1_CA
        fi

        TLSINFO=(--tlsRootCertFiles "${!CA}")
        PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
        # shift by one to get to the next organization
        shift
    done
}

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

verifyResult() {
    if [ $1 -ne 0 ]; then
        fatalln "$2"
    fi
}
