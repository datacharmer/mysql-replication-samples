#!/bin/bash

client=$1
DB=$2
table=$3
max_recs=$4
if [ -z "$client" ]
then
    echo "# Syntax mysql_client [ DB table_name [max_recs] ]"
    exit 1
fi
[ -z "$DB" ] && DB=test
[ -z "$table" ] && table=t1
[ -z "$max_recs" ] && max_recs=1000
$client -e "drop table if exists $table" $DB
$client -e "create table $table (i int not null primary key,  ts timestamp) " $DB

for N in $(seq 1 $max_recs)
do
    $client -e " insert into $table values ($N,  null) " $DB
done
