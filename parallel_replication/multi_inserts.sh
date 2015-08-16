#!/bin/bash

for D in $(seq 1 10)
do
    ./m -e "create schema if not exists db$D"
    for N in $(seq 1 10)
    do
        ./insert_many.sh ./m db$D.t$N 100 > ./tmp/out_db${D}_t$N.txt 2>&1 &
    done 
done
