#!/usr/bin/env bash
source ./scripts/utils.sh

set -e
createConfigYamlFile() {
    local ORG=$1
    local PORT=$2

    echo "
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    ORGanizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    ORGanizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    ORGanizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}-example-com.pem
    ORGanizationalUnitIdentifier: orderer" >${PWD}/../crypto-config/peerOrganizations/${ORG}.example.com/msp/config.yaml
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

createcertificatesForCitizen() {
    echo "Enroll the CA admin"
    mkdir -p ../crypto-config/peerOrganizations/citizen.example.com/
    export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/citizen.example.com/

    fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 \
        --caname ca.citizen.example.com \
        --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-citizen-example-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-citizen-example-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-citizen-example-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-citizen-example-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/citizen.example.com/msp/config.yaml

    echo "Register peer0"
    fabric-ca-client register \
        --caname ca.citizen.example.com \
        --id.name peer0 --id.secret peer0pw \
        --id.type peer --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    echo "Register user"
    fabric-ca-client register \
        --caname ca.citizen.example.com \
        --id.name user1 \
        --id.secret user1pw \
        --id.type client \
        --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    echo "Register the org admin"
    fabric-ca-client register \
        --caname ca.citizen.example.com \
        --id.name citizenadmin \
        --id.secret citizenadminpw \
        --id.type admin \
        --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/citizen.example.com/peers

    # -----------------------------------------------------------------------------------
    #  Peer 0
    mkdir -p ../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com

    echo "## Generate the peer0 msp"
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 \
        --caname ca.citizen.example.com \
        -M ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/msp \
        --csr.hosts peer0.citizen.example.com \
        --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/msp/config.yaml

    echo "## Generate the peer0-tls certificates"

    fabric-ca-client enroll \
        -u https://peer0:peer0pw@localhost:7054 \
        --caname ca.citizen.example.com \
        -M ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls \
        --enrollment.profile tls \
        --csr.hosts peer0.citizen.example.com \
        --csr.hosts localhost \
        --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/msp/tlscacerts/ca.crt

    mkdir ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/tlsca
    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/tlsca/tlsca.citizen.example.com-cert.pem

    mkdir ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/ca
    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/peers/peer0.citizen.example.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/ca/ca.citizen.example.com-cert.pem

    # --------------------------------------------------------------------------------------------------

    mkdir -p ../crypto-config/peerOrganizations/citizen.example.com/users
    mkdir -p ../crypto-config/peerOrganizations/citizen.example.com/users/User1@citizen.example.com

    echo
    echo "## Generate the user msp"
    echo
    fabric-ca-client enroll \
        -u https://user1:user1pw@localhost:7054 \
        --caname ca.citizen.example.com \
        -M ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/users/User1@citizen.example.com/msp \
        --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/citizen.example.com/users/Admin@citizen.example.com

    echo
    echo "## Generate the org admin msp"
    echo
    fabric-ca-client enroll \
        -u https://citizenadmin:citizenadminpw@localhost:7054 \
        --caname ca.citizen.example.com \
        -M ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/users/Admin@citizen.example.com/msp \
        --tls.certfiles ${PWD}/fabric-ca/citizen/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/citizen.example.com/users/Admin@citizen.example.com/msp/config.yaml

}

createCertificatesForPCI() {
    echo
    echo "Enroll the CA admin"
    echo
    mkdir -p /../crypto-config/peerOrganizations/pci.example.com/

    export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/pci.example.com/

    fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca.pci.example.com --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pci-example-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pci-example-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pci-example-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pci-example-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/pci.example.com/msp/config.yaml

    echo
    echo "Register peer0"
    echo

    fabric-ca-client register --caname ca.pci.example.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    echo
    echo "Register user"
    echo

    fabric-ca-client register --caname ca.pci.example.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    echo
    echo "Register the org admin"
    echo

    fabric-ca-client register --caname ca.pci.example.com --id.name pciadmin --id.secret pciadminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/pci.example.com/peers
    mkdir -p ../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com

    # --------------------------------------------------------------
    # Peer 0
    echo
    echo "## Generate the peer0 msp"
    echo

    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.pci.example.com -M ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/msp --csr.hosts peer0.pci.example.com --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/msp/config.yaml

    echo
    echo "## Generate the peer0-tls certificates"
    echo

    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.pci.example.com -M ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls --enrollment.profile tls --csr.hosts peer0.pci.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/peerOrganizations/pci.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/pci.example.com/msp/tlscacerts/ca.crt

    mkdir ${PWD}/../crypto-config/peerOrganizations/pci.example.com/tlsca
    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/pci.example.com/tlsca/tlsca.pci.example.com-cert.pem

    mkdir ${PWD}/../crypto-config/peerOrganizations/pci.example.com/ca
    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/peers/peer0.pci.example.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/pci.example.com/ca/ca.pci.example.com-cert.pem

    # --------------------------------------------------------------------------------

    mkdir -p ../crypto-config/peerOrganizations/pci.example.com/users
    mkdir -p ../crypto-config/peerOrganizations/pci.example.com/users/User1@pci.example.com

    echo
    echo "## Generate the user msp"
    echo

    fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca.pci.example.com -M ${PWD}/../crypto-config/peerOrganizations/pci.example.com/users/User1@pci.example.com/msp --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/pci.example.com/users/Admin@pci.example.com

    echo
    echo "## Generate the org admin msp"
    echo

    fabric-ca-client enroll -u https://pciadmin:pciadminpw@localhost:8054 --caname ca.pci.example.com -M ${PWD}/../crypto-config/peerOrganizations/pci.example.com/users/Admin@pci.example.com/msp --tls.certfiles ${PWD}/fabric-ca/pci/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/pci.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/pci.example.com/users/Admin@pci.example.com/msp/config.yaml

}

createCertificatesForICMR() {
    echo
    echo "Enroll the CA admin"
    echo
    mkdir -p /../crypto-config/peerOrganizations/icmr.example.com/

    export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/icmr.example.com/

    fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 --caname ca.icmr.example.com --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-icmr-example-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-icmr-example-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-icmr-example-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-icmr-example-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/icmr.example.com/msp/config.yaml

    echo
    echo "Register peer0"
    echo

    fabric-ca-client register --caname ca.icmr.example.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    echo
    echo "Register user"
    echo

    fabric-ca-client register --caname ca.icmr.example.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    echo
    echo "Register the org admin"
    echo

    fabric-ca-client register --caname ca.icmr.example.com --id.name icmradmin --id.secret icmradminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/icmr.example.com/peers
    mkdir -p ../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com

    # --------------------------------------------------------------
    # Peer 0
    echo
    echo "## Generate the peer0 msp"
    echo

    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca.icmr.example.com -M ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/msp --csr.hosts peer0.icmr.example.com --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/msp/config.yaml

    echo
    echo "## Generate the peer0-tls certificates"
    echo

    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca.icmr.example.com -M ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls --enrollment.profile tls --csr.hosts peer0.icmr.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/msp/tlscacerts/ca.crt

    mkdir ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/tlsca
    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/tlsca/tlsca.icmr.example.com-cert.pem

    mkdir ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/ca
    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/peers/peer0.icmr.example.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/ca/ca.icmr.example.com-cert.pem

    # --------------------------------------------------------------------------------

    mkdir -p ../crypto-config/peerOrganizations/icmr.example.com/users
    mkdir -p ../crypto-config/peerOrganizations/icmr.example.com/users/User1@icmr.example.com

    echo
    echo "## Generate the user msp"
    echo

    fabric-ca-client enroll -u https://user1:user1pw@localhost:10054 --caname ca.icmr.example.com -M ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/users/User1@icmr.example.com/msp --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/icmr.example.com/users/Admin@icmr.example.com

    echo
    echo "## Generate the org admin msp"
    echo

    fabric-ca-client enroll -u https://icmradmin:icmradminpw@localhost:10054 --caname ca.icmr.example.com -M ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/users/Admin@icmr.example.com/msp --tls.certfiles ${PWD}/fabric-ca/icmr/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/icmr.example.com/users/Admin@icmr.example.com/msp/config.yaml

}

createCertificatesForMOH() {
    echo
    echo "Enroll the CA admin"
    echo
    mkdir -p /../crypto-config/peerOrganizations/moh.example.com/

    export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/moh.example.com/

    fabric-ca-client enroll -u https://admin:adminpw@localhost:110054 --caname ca.moh.example.com --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-110054-ca-moh-example-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-110054-ca-moh-example-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-110054-ca-moh-example-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-110054-ca-moh-example-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/moh.example.com/msp/config.yaml

    echo
    echo "Register peer0"
    echo

    fabric-ca-client register --caname ca.moh.example.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    echo
    echo "Register user"
    echo

    fabric-ca-client register --caname ca.moh.example.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    echo
    echo "Register the org admin"
    echo

    fabric-ca-client register --caname ca.moh.example.com --id.name mohadmin --id.secret mohadminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/moh.example.com/peers
    mkdir -p ../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com

    # --------------------------------------------------------------
    # Peer 0
    echo
    echo "## Generate the peer0 msp"
    echo

    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:110054 --caname ca.moh.example.com -M ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/msp --csr.hosts peer0.moh.example.com --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/msp/config.yaml

    echo
    echo "## Generate the peer0-tls certificates"
    echo

    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:110054 --caname ca.moh.example.com -M ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls --enrollment.profile tls --csr.hosts peer0.moh.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/peerOrganizations/moh.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/moh.example.com/msp/tlscacerts/ca.crt

    mkdir ${PWD}/../crypto-config/peerOrganizations/moh.example.com/tlsca
    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/moh.example.com/tlsca/tlsca.moh.example.com-cert.pem

    mkdir ${PWD}/../crypto-config/peerOrganizations/moh.example.com/ca
    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/peers/peer0.moh.example.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/moh.example.com/ca/ca.moh.example.com-cert.pem

    # --------------------------------------------------------------------------------

    mkdir -p ../crypto-config/peerOrganizations/moh.example.com/users
    mkdir -p ../crypto-config/peerOrganizations/moh.example.com/users/User1@moh.example.com

    echo
    echo "## Generate the user msp"
    echo

    fabric-ca-client enroll -u https://user1:user1pw@localhost:110054 --caname ca.moh.example.com -M ${PWD}/../crypto-config/peerOrganizations/moh.example.com/users/User1@moh.example.com/msp --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    mkdir -p ../crypto-config/peerOrganizations/moh.example.com/users/Admin@moh.example.com

    echo
    echo "## Generate the org admin msp"
    echo

    fabric-ca-client enroll -u https://mohadmin:mohadminpw@localhost:110054 --caname ca.moh.example.com -M ${PWD}/../crypto-config/peerOrganizations/moh.example.com/users/Admin@moh.example.com/msp --tls.certfiles ${PWD}/fabric-ca/moh/tls-cert.pem

    cp ${PWD}/../crypto-config/peerOrganizations/moh.example.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/moh.example.com/users/Admin@moh.example.com/msp/config.yaml

}

createCretificatesForOrderer() {
    infoln "Enroll the CA admin"
    mkdir -p ../crypto-config/ordererOrganizations/example.com

    export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/ordererOrganizations/example.com

    fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml

    infoln "Register orderer"

    fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    infoln "Register orderer2"

    fabric-ca-client register --caname ca-orderer --id.name orderer2 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    infoln "Register orderer3"

    fabric-ca-client register --caname ca-orderer --id.name orderer3 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    infoln "Register the orderer admin"

    fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    mkdir -p ../crypto-config/ordererOrganizations/example.com/orderers
    # mkdir -p ../crypto-config/ordererOrganizations/example.com/orderers/example.com

    # ---------------------------------------------------------------------------
    #  Orderer

    mkdir -p ../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com

    infoln "## Generate the orderer msp"

    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml

    infoln "## Generate the orderer-tls certificates"

    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls --enrollment.profile tls --csr.hosts orderer.example.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

    mkdir ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    mkdir ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/tlscacerts
    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    # ---------------------------------------------------------------------------

    mkdir -p ../crypto-config/ordererOrganizations/example.com/users
    mkdir -p ../crypto-config/ordererOrganizations/example.com/users/Admin@example.com

    infoln "## Generate the admin msp"

    fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem

    cp ${PWD}/../crypto-config/ordererOrganizations/example.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml

}

# createCretificateForOrderer

rm -rf ../crypto-config/*
# rm -rf ./fabric-ca
# sudo rm -rf mohfabric-ca/*
# createcertificatesForCitizen
# createCertificatesForPCI
# createCertificatesForICMR
# createCertificatesForMOH

createcertificatesForOrg citizen 7054
createcertificatesForOrg pci 8054
createcertificatesForOrg icmr 10054
createcertificatesForOrg moh 11054
createCretificatesForOrderer
