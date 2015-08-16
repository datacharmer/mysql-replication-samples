#!/bin/bash

for D in $(seq 1 10)
do
    for N in $(seq 1 10)
    do
        ./insert_many.sh ./m test.${D}_t$N 200 > ./tmp/out_db${D}_t$N.txt 2>&1 &
    done 
done
