#!/bin/bash
# Copyright London Stock Exchange Group All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
set -e
# This script expedites the chaincode development process by automating the
# requisite channel create/join commands
pwd
# We use a pre-generated orderer.block and channel transaction artifact (myc.tx),
# both of which are created using the configtxgen tool

# first we create the channel against the specified configuration in myc.tx
# this call returns a channel configuration block - myc.block - to the CLI container
echo "creating channel"
peer channel create -c $CHANNEL -f ./crypto/v1.1/$CHANNEL.tx -o orderer.example.com:7050

# now we will join the channel and start the chain with myc.block serving as the
# channel's first block (i.e. the genesis block)

echo "joining channel"

peer channel join -b $CHANNEL.block

# Now the user can proceed to build and start chaincode in one terminal
# And leverage the CLI container to issue install instantiate invoke query commands in another

#we should have bailed if above commands failed.
#we are here, so they worked
sleep 600000
exit 0