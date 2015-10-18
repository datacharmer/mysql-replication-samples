#!/bin/bash

if [ -f DEPLOYED ]
then
    NUM_NODES=$(cat DEPLOYED)
else
    echo "#File 'DEPLOYED' not found. Assuming 3 nodes"
    NUM_NODES=3
fi

# set -x
for NODE in $(seq 1 $NUM_NODES)
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
        if [ -d /opt/docker/mysql/node_$NODE ]
        then
            sudo rm -rf /opt/docker/mysql/node_$NODE
        fi
    fi
done
if [ -L m ]
then
    rm -f m
fi
rm -f DEPLOYED
