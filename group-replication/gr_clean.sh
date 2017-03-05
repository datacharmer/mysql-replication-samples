#!/bin/bash
if [ ! -f gr_started ]
then
    echo file gr_started not found
    exit 1
fi

for NODE in 1 2 3;
do
    docker stop node$NODE
    docker rm -v -f node$NODE
done
#remove_containers.sh
rm -rf ddnode?

for F in gr_started gr_completed
do
    if [ -f $F ]
    then
        rm -f $F
    fi
done
