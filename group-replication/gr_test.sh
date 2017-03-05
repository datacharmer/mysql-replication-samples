#!/bin/bash

if [ ! -f gr_completed ]
then
    echo file gr_completed not found
    exit 1
fi

for N in 1 2 3
do 
    docker exec -ti node$N bash -c 'mysql -psecret -NB -e "select @@hostname"' 
    docker exec -ti node$N bash -c 'mysql -psecret -e "show schemas"' 
done

docker exec -ti node1 bash -c 'mysql -psecret < /data/input_data.sql ' 

for N in 1 2 3
do 
    docker exec -ti node$N bash -c 'mysql -psecret -t -e "select @@hostname; show tables from test"' 
done

