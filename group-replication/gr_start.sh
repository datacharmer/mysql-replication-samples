#!/bin/bash

if [ ! -f gr_started ]
then
    echo file gr_started not found
    exit 1
fi
elapsed=0

while [[ $elapsed -lt 60 ]]
do
    current=$(date +%s)
    started=$(cat gr_started)
    elapsed=$(expr $current - $started)
    echo -n "$elapsed "
    sleep 2
done
echo ''


for N in 1 2 3
do 
    docker exec -ti node$N bash -c 'mysql -psecret < /data/user.sql' 
done
echo sleeping 10 seconds
sleep 10
for N in 1 2 3
do 
    docker exec -ti node$N bash -c 'mysql -psecret < /data/user2.sql' 
    sleep 4
done
date +%s > gr_completed

