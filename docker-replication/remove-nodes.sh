#!/bin/bash
NUM_NODES=$1
[ -z "$NUM_NODES" ] && NUM_NODES=3

set -x
for NODE in $(seq 1 $NUM_NODES)
do
    docker stop mysql-node$NODE
    docker rm mysql-node$NODE
done
