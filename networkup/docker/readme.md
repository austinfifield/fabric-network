# Quick Start:
There are 2 environments to setup for development: ChaincodeDev and Front-end-dev

 - **ChaincodeDev** - environment for chaincode developers to quickly deploy and test chaincode without restarting network, peers are started in devmode
 
 - **Front-end-dev** - environment for front-end developers to quickly deploy fabric network locally and have all peers join channel and CC installed and instantiated. This deployment allows fabric-sdk apps to quickly make calls to the fabric network.

# Prereq:

  Docker
  
  Docker-compose
  
  golang 1.10
  
## Find your type of deployment below for a guide on how to deploy your network. For both types of deployment, please ensure checklist is completed.

### Checklist:

1. Setup environment variables, preferably in ~./bash_profile

    `export CHANNEL=foo `
    *currently the default channel name is foo(networkup/docker/crypto/v1.1/\*.tx)*
    
    `export GOPATH=$HOME/go/src`
    *ensure go is installed and GOPATH is set*
    
    `export FABRIC_CC_SRC=$GOPATH/src/<path into your cc main.go file>`
    *FABRIC_CC_SRC should point to your chaincode source files, it does not have to be in your GOPATH*
    
    `export CRYPTO_CONFIG=<absolute path to ./crypto/v1.1/crypto-config>`
    *CRYPTO_CONFIG is required for bc-explorer, make sure the path ends with ..../crypto-config*
    
    `export HLFBIN1_1=<absolute path to ./binaries/v1.1/bin>`
    *HLFBIN1_1 is required for bc-explorer*

2. If CHANNEL is different than default (foo), make sure the $CHANNEL.tx file is generated and visible in networkup/docker/crypto/${FAB_CONFIG_GEN_VERS}/

3. Ensure correct fabric version is used in networkup/docker/.env

## **ChaincodeDev** 

To deploy environment for chaincode devmode

1. Enable devmode with PEER_DEV_MODE=true for terminal 1

    ```bash
    PEER_DEV_MODE=true ./fabric.sh up
    ```
2. Open another terminal(2) and run the CC locally. Make sure your local $GOPATH/src/github.com/hyperledger/fabric branch is on the correct version if you have fabric installed locally.

    The terminal will run the chaincode(instead of a container being spun up by a peer). You can view the logs from this terminal. To stop the cc, use ctrl+C

    ```bash
    ./fabric.sh startCC ccname v1
    ```
    *ccname and v1 is optional, if not used, defaultcc and v1 will be used*
    
3. On Terminal 1, install and instantiate the cc on the peer. The peer requires this step to know about the chaincode handler.

    ```bash
    ./fabric.sh runCC ccname v1 '{"Args":["init","a","100","b","200"]}'
    ```
    *ccname and v1 must match signature from startCC, 3rd argument is for init function and is also optional*
    
4. When developing and running an updated cc, on terminal 2, ctrl+c to stop the chaincode and run the updated chaincode. Step 3 is no longer required.

    ```bash
    ^CGracefully stopping... (press Ctrl+C again to force)
    Stopping chaincode ... done
    ./fabric.sh stopCC #important to take down the container before restarting
    ./fabric.sh startCC ccname v1
    ```
5. To invoke/query cc, use ./fabric.sh invoke and query command. Examples are provided at the end of this readme and format provided below.
    ```bash
    ./fabric.sh invoke $CC_NAME $CC_VER $ARGS
    ./fabric.sh query $CC_NAME $CC_VER $ARGS
    ```
6. To take down network and clean up containers(clean removes the chaincode dev container)

    ```bash
    ./fabric.sh down && ./fabric.sh clean
    ```

## **Front-end-dev**

To deploy environment for front-end, this deployment will have "the" peer join the channel and install and instantiate the chaincode.

1. Startup the fabric network in 1 command. This will use default chaincode name, id, and init arguments. If you need to specify these values, start from step 2.

    ```bash
    ./fabric.sh upAll
    ```
2. Start up the fabric network without installing and instantiate network

    ```bash
    ./fabric.sh up
    ```
3. Install and instantiate the CC with specific name, version and init arguments
    
    ```bash
    ./fabric.sh runCC ccname v1 '{"Args":["init","a","100","b","200"]}'
    ```
    *Args may not be needed depending on the chaincode init function requirements*
    
4. To take down network and clean up containers(clean removes the chaincode dev container)

    ```bash
    ./fabric.sh down && ./fabric.sh clean
    ```

### Sample order to execute for dev mode

`Terminal 1`

    ./fabric.sh up
    
`Terminal 2`

    ./fabric.sh startCC ccname v1

`Terminal 1`

    ./fabric.sh runCC ccname v1
    
### Sample order to execute for non-dev mode 

`Terminal 1`

    ./fabric.sh up

`Terminal 1`

    ./fabric.sh runCC ccname v1

#To Modify and add peers and orgs to network:
Currently, tha yaml is setup for 2 orgs (Org1MSP and Org2MSP), and 2 peers and a fabric-ca each with 1 solo orderer.

Modify docker-compose.yaml and docker-compose-couch.yaml by commenting the services you want running or not.


For example:

Inside of docker-compose.yaml

    ##################################################################
    ##################################################################
      peer0.org1.example.com:
        container_name: peer0.org1.example.com
        extends:
          file:  base/docker-compose-base.yaml
          service: peer0.org1.example.com
        networks:
          - fabricbros
        depends_on:
              - orderer.example.com
    ##################################################################
    ##################################################################
    
and inside docker-compose-couch.yaml

      couchdb0:
        container_name: couchdb0
        image: hyperledger/fabric-couchdb
        # Populate the COUCHDB_USER and COUCHDB_PASSWORD to set an admin user and password
        # for CouchDB.  This will prevent CouchDB from operating in an "Admin Party" mode.
        environment:
          - COUCHDB_USER=
          - COUCHDB_PASSWORD=
        # Comment/Uncomment the port mapping if you want to hide/expose the CouchDB service,
        # for example map it to utilize Fauxton User Interface in dev environments.
        ports:
          - "5984:5984"
        networks:
          - fabricbros
    
      peer0.org1.example.com:
        environment:
          - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
          - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0:5984
          # The CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME and CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD
          # provide the credentials for ledger to connect to CouchDB.  The username and password must
          # match the username and password set for the associated CouchDB.
          - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=
          - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=
        depends_on:
          - couchdb0
          
To turn off peer0.org1.example.com, comment out these 2 block of code



## SAMPLE Invoke

```
$ ./fabric.sh invoke mycc4 v1  '{"Args":["initMarble","marble1","red","100","username"]}'

Init cc with args: {"Args":["initMarble","marble2","red","username","100"]}
2018-06-16 14:51:40.684 UTC [chaincodeCmd] InitCmdFactory -> INFO 001 Get chain(foo) orderer endpoint: orderer.example.com:7050
2018-06-16 14:51:40.686 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default escc
2018-06-16 14:51:40.686 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default vscc
2018-06-16 14:51:40.710 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 004 Chaincode invoke successful. result: status:200
2018-06-16 14:51:40.710 UTC [main] main -> INFO 005 Exiting.....

$ ./fabric.sh invoke ccname2 v1  '{"Args":["queryMarblesByOwner","username"]}'
Init cc with args: {"Args":["queryMarblesByOwner","username"]}
2018-06-16 14:53:35.052 UTC [chaincodeCmd] InitCmdFactory -> INFO 001 Get chain(foo) orderer endpoint: orderer.example.com:7050
2018-06-16 14:53:35.054 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default escc
2018-06-16 14:53:35.054 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default vscc
2018-06-16 14:53:35.203 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 004 Chaincode invoke successful. result: status:200 payload:"[{\"Key\":\"marble3\", \"Record\":{\"color\":\"red\",\"docType\":\"marble\",\"name\":\"marble3\",\"owner\":\"username\",\"size\":100}}]"
2018-06-16 14:53:35.204 UTC [main] main -> INFO 005 Exiting.....

huys-MBP-2:docker huytran$ ./fabric.sh invoke defaultcc v1 '{"Args":["invoke","a","b","100"]}'
Init cc with args: {"Args":["invoke","a","b","100"]}
2018-10-22 02:23:22.831 UTC [chaincodeCmd] InitCmdFactory -> INFO 001 Get chain(foo) orderer endpoint: orderer.example.com:7050
2018-10-22 02:23:22.834 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 002 Using default escc
2018-10-22 02:23:22.834 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default vscc
2018-10-22 02:23:22.905 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 004 Chaincode invoke successful. result: status:200 
2018-10-22 02:23:22.906 UTC [main] main -> INFO 005 Exiting.....


```
