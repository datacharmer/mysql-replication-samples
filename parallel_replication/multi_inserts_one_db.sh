#!/bin/bash

if [ ! -d ./tmp ]
then
    mkdir tmp
fi

for D in $(seq 1 10)
do
    for N in $(seq 1 10)
    do
        ./insert_many.sh ./m test ${D}_t$N 500 > ./tmp/out_db${D}_t$N.txt 2>&1 &
    done 
done
