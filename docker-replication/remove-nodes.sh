#!/bin/bash

curdir=$(dirname $0)

. $curdir/common.sh

check_operating_system

if [ -f DEPLOYED ]
then
    NUM_NODES=$(cat DEPLOYED)
else
    echo "#File 'DEPLOYED' not found. Assuming 3 nodes"
    NUM_NODES=3
fi

for NODE in $(seq 1 $NUM_NODES | sort -nr)
do
    echo "# Removing node $NODE"
    docker stop mysql-node$NODE
    docker rm mysql-node$NODE
    SN=$(($NODE-1))
    if [ -x n$NODE ]
    then
        rm -f n$NODE
    fi
    if [ -L s$SN ]
    then
        rm -f s$SN
    fi
    if [ $NODE -gt 3 ]
    then
        if [ -d $DOCKER_DATA/node_$NODE ]
        then
            sudo rm -rf $DOCKER_DATA/node_$NODE
        fi
    fi
done
if [ -L m ]
then
    rm -f m
fi
rm -f DEPLOYED
