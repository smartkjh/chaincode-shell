#!/bin/bash

# shell directory path
shdir="$( cd "$(dirname "$0")" ; pwd -P)"
btpdir="/home/btp/gitlab.smartm2m.co.kr/btp-testbed/exaledger/fabric-edu/e-node-2"

# iclude utils scripts
source $btpdir/scripts/utils.sh
export COMPOSE_IGNORE_ORPHANS=True

function blockchain_usage {
    echo "========================================================================="
    echo " chaincode.sh"
    echo "-------------------------------------------------------------------------"
    echo " Commands"
    echo " - chaincode  : chaincode"
    echo "-------------------------------------------------------------------------"
    echo " Flags"
    echo " -cc  | --chanicode   : chaincode name            (default : basic)"
    echo " -v   | --version     : chaincode's version       (default : 1.0)"
    echo " -s   | --sequence    : chaincode's sequence      (default : 1)"
    echo " -p   | --path        : chaincode's path          (default : path)"
    echo "-------------------------------------------------------------------------"
    echo " Examples"
    echo " ./e-node-2.sh \${command} \${flags}"
    echo " ./e-node-2.sh chaincode -cc basic -v 1.0 -s 1"
    echo "========================================================================="
}

function blockchain_chaincode {
    rm -rf $btpdir/$ORGANIZATION/chaincode$shdir/$CHAINCODE
    cp -rf $shdir/$CHAINCODE $btpdir/$ORGANIZATION/chaincode$shdir/$CHAINCODE
    echo $btpdir
    blockchain_chaincode_deploy
}

function blockchain_chaincode_deploy {
    blockchain_chaincode_package
    blockchain_chaincode_install

    blockchain_chaincode_approveformyorg
    sleep 1s
    blockchain_chaincode_checkcommitreadiness
    blockchain_chaincode_commit
    blockchain_chaincode_querycommitted
}

function blockchain_chaincode_package {
    command "docker exec -it \
    cli.$PEER \
    peer lifecycle chaincode package $CHAINCODE_DIR/$CHAINCODE-$VERSION.tar.gz --path $CHAINCODE_DIR/$CHAINCODE --lang golang --label $CHAINCODE-$VERSION"
}

function blockchain_chaincode_install {
    command "docker exec -it \
    cli.$PEER \
    peer lifecycle chaincode install $CHAINCODE_DIR/$CHAINCODE-$VERSION.tar.gz"
}

function blockchain_chaincode_queryinstalled {
    command "docker exec -it \
    cli.$PEER \
    peer lifecycle chaincode queryinstalled"
}

function blockchain_chaincode_getpackageid {
    blockchain_chaincode_queryinstalled

    PACKAGE_ID=$(sed -n "/$CHAINCODE-$VERSION/{s/^Package ID: //; s/, Label:.*$//; p;}" $btpdir/log.txt)
}

function blockchain_chaincode_approveformyorg {
    blockchain_chaincode_getpackageid

    command "docker exec -it \
    cli.$PEER \
    peer lifecycle chaincode approveformyorg \
    --channelID $CHANNEL \
    --name $CHAINCODE \
    --version $VERSION \
    --package-id $PACKAGE_ID \
    --sequence $SEQUENCE \
    $GLOBAL_FLAGS"
}

function blockchain_chaincode_checkcommitreadiness {
    command "docker exec -it \
    cli.$PEER \
    peer lifecycle chaincode checkcommitreadiness  \
    --channelID $CHANNEL \
    --name $CHAINCODE \
    --version $VERSION \
    --sequence $SEQUENCE \
    $GLOBAL_FLAGS"
}

function blockchain_chaincode_commit {
    command "docker exec -it \
    cli.$PEER \
    peer lifecycle chaincode commit  \
    --channelID $CHANNEL \
    --name $CHAINCODE \
    --version $VERSION \
    --sequence $SEQUENCE \
    $GLOBAL_FLAGS"
}

function blockchain_chaincode_querycommitted {
    command "docker exec -it \
    cli.$PEER \
    peer lifecycle chaincode querycommitted  \
    --channelID $CHANNEL \
    $GLOBAL_FLAGS"
}

function blockchain_chaincode_invoke {
    command "docker exec -it \
    cli.$PEER \
    peer chaincode invoke  \
    --channelID $CHANNEL \
    --name $CHAINCODE \
    -c $ARGS \
    $GLOBAL_FLAGS"
}

function blockchain_chaincode_query {
    command "docker exec -it \
    cli.$PEER \
    peer chaincode query  \
    --channelID $CHANNEL \
    --name $CHAINCODE \
    -c $ARGS"
}

function blockchain_env {
    DOMAIN="${DOMAIN:-blockchainbusan.kr}"
    ORDERER="${ORDERER:-orderer0}"
    ORGANIZATION="${ORGANIZATION:-edu-org1}"
    CHANNEL="${CHANNEL:-testbed}"
    CHAINCODE="${CHAINCODE:-basic}"
    VERSION="${VERSION:-1.0}"
    SEQUENCE="${SEQUENCE:-1}"
    MODE="${MODE:-dev}"
    ORDERER_ADDR=$ORDERER.$DOMAIN:7050
    GLOBAL_FLAGS="-o $ORDERER_ADDR --tls --cafile /etc/hyperledger/fabric/orderer-tls/tlsca.$DOMAIN-cert.pem"
    PEER=peer0.$ORGANIZATION.$DOMAIN
    CHAINCODE_DIR=/etc/hyperledger/fabric/chaincode$shdir
}

function main {
    case $1 in
          chaincode | chaincode_package | chaincode_install | chaincode_queryinstalled \
        | chaincode_approveformyorg | chaincode_checkcommitreadiness | chaincode_commit | chaincode_querycommitted | chaincode_invoke | chaincode_query)
            cmd=blockchain_$1
            shift
            while [ "$1" != "" ]; do
				case $1 in
					-cc | --chaincode)  shift
                                        CHAINCODE=$1
                                        ;;
					-v | --version)     shift
                                        VERSION=$1
                                        ;;
					-s | --sequence)    shift
                                        SEQUENCE=$1
                                        ;;
                    -a | --args)        shift
                                        ARGS=$1
                                        ;;
                    -p | --path)        shift
                                        PATH=$1
                                        ;;
					*)
                                        blockchain_usage
                                        exit 1
				esac
				shift
			done
            blockchain_env
			$cmd
            ;;
        *)
            blockchain_usage
            exit
            ;;
    esac
}

main $@
