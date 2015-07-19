#!/bin/bash
cd $(dirname $0)

for NODE in node1 node2 node3
do
    $NODE/use test -e "drop table if exists test_$NODE"
    $NODE/use test -e "create table test_$NODE( id int not null primary key, serverid int, dbport int, node varchar(100), ts timestamp)"
    $NODE/use test -e "insert into test_$NODE values (1, @@server_id, @@port, '$NODE', null)"
    echo -n "# Tables in server "
    $NODE/use -BN -e 'select @@server_id; show tables from test'
    # $NODE/use test -e "select @@server_id, id, serverid,dbport,node,ts from test_$NODE "
done

sleep 3
echo "# Tables in fan-in slave"
./node4/use -BN -e 'show tables from test'

./node4/use  -e "select @@server_id as server_id, @@port, 'fan-in slave' as node"
for NODE in node1 node2 node3
do
    ./node4/use test -e "select * from test_$NODE"
done

