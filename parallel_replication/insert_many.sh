#!/bin/bash

client=$1
table=$2
max_recs=$3
if [ -z "$client" ]
then
    echo "# Syntax mysql_client [ table_name [max_recs] ]"
    exit 1
fi
[ -z "$table" ] && table=t1
[ -z "$max_recs" ] && max_recs=1000
$client -e "drop table if exists $table" 
$client -e "create table $table (i int not null primary key,  ts timestamp) " 

for N in $(seq 1 $max_recs)
do
    $client -e " insert into $table values ($N,  null) " 
done
