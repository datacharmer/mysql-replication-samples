#!/bin/bash

if [ ! -d ./tmp ]
then
    mkdir tmp
fi

./m -e 'drop table if exists rollcall' test
./m -e 'create table rollcall( schema_name varchar(50), table_name varchar(50), started datetime, ended datetime, primary key (schema_name, table_name)) ' test
for D in $(seq 1 10)
do
    ./m -e "create schema if not exists db$D"
    for N in $(seq 1 10)
    do
        ./insert_many.sh ./m db$D t$N 500 > ./tmp/out_db${D}_t$N.txt 2>&1 &
    done 
done
