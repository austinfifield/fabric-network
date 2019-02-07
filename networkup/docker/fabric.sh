#!/usr/bin/env bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# simple batch script making it easier to cleanup and start a relatively fresh fabric env.
set -a
. ./.env
set +a

current_dir=$(pwd)
export PEER_DEV_MODE=${PEER_DEV_MODE:-false}
export CHANNEL=${CHANNEL:-foo}
export FABRIC_CC_SRC=$FABRIC_CC_SRC
export GOPATH=$GOPATH


if [ ! -e "docker-compose.yaml" ];then
  echo "docker-compose.yaml not found."
  exit 8
fi

ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION=${ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION:-}

function clean(){

  rm -rf /var/hyperledger/*

  if [ -e "/tmp/HFCSampletest.properties" ];then
    rm -f "/tmp/HFCSampletest.properties"
  fi

  lines=`docker ps -a | grep 'dev-peer' | wc -l`

  if [ "$lines" -gt 0 ]; then
    docker ps -a | grep 'dev-peer' | awk '{print $1}' | xargs docker rm -f
  fi

  lines=`docker images | grep 'dev-peer' | grep 'dev-peer' | wc -l`
  if [ "$lines" -gt 0 ]; then
    docker images | grep 'dev-peer' | awk '{print $1}' | xargs docker rmi -f
  fi

}

function up(){


    if [[ -z "${FABRIC_CC_SRC}" ]] ; then
        echo "Missing FABRIC_CC_SRC ENV! Set the ENV to the chaincode files path"
        exit 1
    fi

    if [ "$ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION" == "1.0.0" ]; then
        docker-compose up --force-recreate ca0 ca1 peer1.org1.example.com peer1.org2.example.com ccenv
    else
#    docker-compose up --force-recreate
        docker-compose -f docker-compose.yaml -f docker-compose-couch.yaml up --force-recreate -d 2>&1
    fi

}

function down(){
  docker-compose down;
  docker-compose -f docker-compose.yaml -f docker-compose-couch.yaml down --volumes
}

function stop (){
  docker-compose stop;
}

function start (){
  docker-compose start;
}


function installCC(){

    CC_NAME=$1
    CC_VER=$2

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi

    echo "Install cc using ${CC_NAME}:${CC_VER}"

    docker exec cli peer chaincode install -p chaincode -n ${CC_NAME} -v ${CC_VER}

}

function instantiateCC(){
    CC_NAME=$1
    CC_VER=$2
    CC_ARGS=$3

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi

    if [[ -z "${CC_ARGS}" ]] ; then
        echo "Missing argument for CC_ARGS setting default to" '{"Args":["init","a","100","b","200"]}'
        CC_ARGS='{"Args":["init","a","100","b","200"]}'
    fi


    echo "Instantiating cc with args: ${CC_ARGS}"
#{"Args":["init","a","100","b","200"]}
    docker exec cli peer chaincode instantiate -o orderer.example.com:7050 -n ${CC_NAME} -v ${CC_VER} -c ${CC_ARGS} -C ${CHANNEL}
}


function invoke(){
    CC_NAME=$1
    CC_VER=$2
    CC_ARGS=$3

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi
    if [[ -z "${CC_ARGS}" ]] ; then
        echo "Missing argument for CC_ARGS setting default to" '{"Args":["no","need","for","init"]}'
        CC_ARGS='{"Args":["no","need","for","init"]}'
    fi

    echo "Init cc with args: ${CC_ARGS}"

    docker exec cli peer chaincode invoke -n ${CC_NAME} -v ${CC_VER} -c ${CC_ARGS} -C ${CHANNEL}
    # peer chaincode invoke -n mycc -c '{"Args":["invoke","a","b","10"]}' -o 127.0.0.1:7050 -C ch1
}


function query(){
    CC_NAME=$1
    CC_VER=$2
    CC_ARGS=$3

    if [[ -z "${CC_NAME}" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "${CC_VER}" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi
    if [[ -z "${CC_ARGS}" ]] ; then
        echo "Missing argument for CC_ARGS setting default to" '{"Args":["no","need","for","init"]}'
        CC_ARGS='{"Args":["no","need","for","init"]}'
    fi

    echo "Init cc with args: ${CC_ARGS}"

    docker exec cli peer chaincode query -n ${CC_NAME} -v ${CC_VER} -c ${CC_ARGS} -C ${CHANNEL}
}

function startCC(){

    export CC_NAME=$1
    export CC_VER=$2

    if [[ -z "${FABRIC_CC_SRC}" ]] ; then
        echo "Missing FABRIC_CC_SRC ENV! Set the ENV to the chaincode files path"
    fi

    if [[ -z "$CC_NAME" ]] ; then
        echo "Missing argument for CC_NAME setting default to 'defaultcc'"
        CC_NAME=defaultcc
    fi

    if [[ -z "$CC_VER" ]] ; then
        echo "Missing argument for CC_VER setting default to v1"
        CC_VER=v1
    fi


    echo "Using CC_NAME=$CC_NAME and CC_VER=$CC_VER"
    docker-compose -f docker-compose-cc-dev.yaml up
#    cd ${FABRIC_CC_SRC} && go clean && go build -o ccgo && CORE_CHAINCODE_LOGGING_LEVEL=DEBUG CORE_CHAINCODE_LOGGING_SHIM=DEBUG CORE_LOGGING_LEVEL=DEBUG CORE_PEER_ADDRESS=127.0.0.1:7052 CORE_CHAINCODE_ID_NAME=${CC_NAME}:${CC_VER} ./ccgo
    exit 0
}



function installAndInstantiate(){


    installCC $1 $2

    instantiateCC $1 $2 $3

    exit 0
}


function stopCC(){
    docker-compose -f docker-compose-cc-dev.yaml down
}


for opt in "$@"
do

    case "$opt" in
        up)
            up
            ;;
        down)
            down
            ;;
        upAll)
            up
            sleep 10 #allow network to stabilize
            installAndInstantiate $2 $3
            ;;
        stop)
            stop
            ;;
        start)
            start
            ;;
        clean)
            clean
            ;;
        runCC)
            installAndInstantiate $2 $3 $4
            ;;
        instantiateCC)
            instantiateCC $2 $3
            ;;
        startCC)
            startCC $2 $3
            ;;
        stopCC)
            stopCC
            ;;
        installCC)
            installCC $2 $3
            ;;
        restart)
            down
            clean
            up
            ;;
        invoke)
            invoke $2 $3 $4
            exit 0
            ;;
         query)
            query $2 $3 $4
            exit 0
            ;;
        *)
            echo $"Usage: $0 {up | down | start | stop | clean | restart | createChannel | joinChannel | startCC CC_NAME CC_VER (arg1 and arg2 optional) | installCC CC_NAME CC_VER (arg1 and arg2 optional) | invoke CC_NAME CC_VER CC_ARGS | query CC_NAME CC_VER CC_ARGS}"
            exit 1

esac
done
