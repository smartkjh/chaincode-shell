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
    echo " -p   | --cpath        : chaincode's path          (default : path)"
    echo "-------------------------------------------------------------------------"
    echo " Examples"
    echo " ./chaincode.sh \${command} \${flags}"
    echo " ./chaincode.sh chaincode -cc testcc -v 1.0 -s 1 -p /home/student0/testCC"
    echo "========================================================================="
}

function blockchain_chaincode {
    rm -rf $btpdir/$ORGANIZATION/chaincode/$USER/$CHAINCODE
    mkdir -p $btpdir/$ORGANIZATION/chaincode/$USER
    cp -rf $CPATH $btpdir/$ORGANIZATION/chaincode/$USER/$CHAINCODE
    $btpdir/e-node-2.sh chaincode -cc $CHAINCODE -v $VERSION -s $SEQUENCE -p /$USER/$CHAINCODE
}

function blockchain_env {
    ORGANIZATION="${ORGANIZATION:-edu-org1}"
    CHAINCODE="${CHAINCODE:-basic}"
    VERSION="${VERSION:-1.0}"
    SEQUENCE="${SEQUENCE:-1}"
}

function main {
    case $1 in
          chaincode )
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
                    			-p | --cpath)       shift
                                        CPATH=$1
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