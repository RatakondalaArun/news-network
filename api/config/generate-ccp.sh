#!/usr/bin/env bash

one_line_pem() {
    echo "$(awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1)"
}

json_ccp() {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ./ccp-template.json
}

generate() {
    ORG=$1
    P0PORT=$2
    CAPORT=$3
    PEERPEM=${PWD}/../../fabric-network/artifacts/channel/crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/tlscacerts/tls-localhost-${CAPORT}-ca-${ORG}-example-com.pem
    CAPEM=${PWD}/../../fabric-network/artifacts/channel/crypto-config/peerOrganizations/${ORG}.example.com/msp/tlscacerts/ca.crt
    echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" >connection-${ORG}.json
}

generate citizen 7051 7054
generate pci 8051 8054
generate icmr 9051 9054
generate moh 10051 10054
