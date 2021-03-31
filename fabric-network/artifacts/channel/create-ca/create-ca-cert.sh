#!/usr/bin/env bash
# creates CA Certifactes using ca Certificate
source ./scripts/utils.sh

# failes on first error
set -e

createConfigYamlFile() {
    local ORG=$1
    local PORT=$2
    # creates config.yaml for all the orgs
    echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    OrganizationalUnitIdentifier: orderer" >${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/msp/config.yaml
}

createcertificatesForOrg() {
    local ORG=$1
    local PORT=$2

    infoln "Enroll the CA admin $ORG"
    mkdir -p ../crypto-config/peerOrganizations/${ORG}.example.com/
    export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/

    fabric-ca-client enroll -u https://admin:adminpw@localhost:${PORT} --caname ca.${ORG}.example.com --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed to enroll fabric ca $ORG $PORT"

    createConfigYamlFile $ORG $PORT
    verifyResult $? "Failed to enroll fabric ca $ORG $PORT"

    infoln "Register peer0 on $ORG"
    fabric-ca-client register --caname ca.${ORG}.example.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed to register fabric ca peer0 $ORG $PORT"

    infoln "Register user on $ORG"
    fabric-ca-client register --caname ca.${ORG}.example.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed to register fabric ca user1 $ORG $PORT"

    infoln "Register the org admin on $ORG"
    fabric-ca-client register --caname ca.${ORG}.example.com --id.name ${ORG}admin --id.secret ${ORG}adminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed to register fabric ca org admin $ORG $PORT"

    mkdir -p ../crypto-config/peerOrganizations/${ORG}.example.com/peers

    # -----------------------------------------------------------------------------------
    #  Peer 0
    mkdir -p ../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com

    infoln "Generating the peer0 msp $ORG"
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${PORT} --caname ca.${ORG}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/msp --csr.hosts peer0.${ORG}.example.com --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed to generate peer0 MSP on $ORG $PORT"

    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/msp/config.yaml

    infoln "Generate the peer0-tls certificates on $ORG"
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${PORT} --caname ca.${ORG}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls --enrollment.profile tls --csr.hosts peer0.${ORG}.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed to generate the peer0-tls certificates on $ORG"

    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/msp/tlscacerts/ca.crt

    mkdir ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/tlsca
    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/tlsca/tlsca.${ORG}.example.com-cert.pem

    mkdir ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/ca
    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/peers/peer0.${ORG}.example.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/ca/ca.${ORG}.example.com-cert.pem

    # --------------------------------------------------------------------------------------------------

    mkdir -p ../crypto-config/peerOrganizations/${ORG}.example.com/users
    mkdir -p ../crypto-config/peerOrganizations/${ORG}.example.com/users/User1@${ORG}.example.com

    infoln "Generate the user msp on $ORG"
    fabric-ca-client enroll -u https://user1:user1pw@localhost:${PORT} --caname ca.${ORG}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/users/User1@${ORG}.example.com/msp --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed Generate the peer0-tls certificates on $ORG"

    mkdir -p ../crypto-config/peerOrganizations/${ORG}.example.com/users/Admin@${ORG}.example.com

    infoln "Generate the org admin msp on $ORG"
    fabric-ca-client enroll -u https://${ORG}admin:${ORG}adminpw@localhost:${PORT} --caname ca.${ORG}.example.com -M ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/users/Admin@${ORG}.example.com/msp --tls.certfiles ${PWD}/fabric-ca/${ORG}/tls-cert.pem
    verifyResult $? "Failed Generate the peer0-tls certificates on $ORG"

    cp ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/users/Admin@${ORG}.example.com/msp/config.yaml
}

createCretificatesForOrderer() {
    infoln "Enroll the CA admin"
    mkdir -p ../crypto-config/ordererOrganizations/example.com

    export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/ordererOrganizations/example.com

    infoln "Enrolling Orderer"
    fabric-ca-client enroll -u https://admin:adminpw@localhost:6054 --caname ca-orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Enrolling orderer failed"

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-6054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-6054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-6054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-6054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml

    infoln "Register orderer"
    fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Failed to register orderer"

    infoln "Register orderer2"
    fabric-ca-client register --caname ca-orderer --id.name orderer2 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Failed to register orderer 2"

    infoln "Register orderer3"
    fabric-ca-client register --caname ca-orderer --id.name orderer3 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Failed to register orderer 3"

    infoln "Register the orderer admin"
    fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Failed to register orderer admin"

    mkdir -p ../crypto-config/ordererOrganizations/example.com/orderers

    # ---------------------------------------------------------------------------
    #  Orderer

    mkdir -p ../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com

    infoln "Generate the orderer msp"
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:6054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Generate the orderer msp"

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml

    infoln "Generate the orderer-tls certificates"
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:6054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Generate the orderer-tls certificates"

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    mkdir ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    # orderer2
    mkdir -p ../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com

    infoln "Generate the orderer msp"
    fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:6054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp --csr.hosts orderer2.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Generate the orderer msp"

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/config.yaml

    infoln "Generate the orderer-tls certificates"
    fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:6054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls --enrollment.profile tls --csr.hosts orderer2.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Generate the orderer-tls certificates"

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    # orderer3
    mkdir -p ../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com

    infoln "Generate the orderer msp"
    fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:6054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/msp --csr.hosts orderer3.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Failed to Generate the orderer msp"

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/msp/config.yaml

    infoln "Generate the orderer-tls certificates"
    fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:6054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls --enrollment.profile tls --csr.hosts orderer3.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Failed to Generate the orderer-tls certificates"

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    # ---------------------------------------------------------------------------

    mkdir -p ../crypto-config/ordererOrganizations/example.com/users
    mkdir -p ../crypto-config/ordererOrganizations/example.com/users/Admin@example.com

    infoln "Generate the admin msp"
    fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:6054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
    verifyResult $? "Failed to Generate Admin MSP"

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml

}

# createCretificateForOrderer

infoln "Removing previous crypto-config files"
rm -rf ../crypto-config/*

infoln "Generating certifactes fro Orgs"
createcertificatesForOrg citizen 7054
createcertificatesForOrg pci 8054
createcertificatesForOrg icmr 9054
createcertificatesForOrg moh 10054
infoln "Create certifacts for orderer"
createCretificatesForOrderer
verifyResult $? "Create certifacts for orderer"

successln "Generated certs successfully"
