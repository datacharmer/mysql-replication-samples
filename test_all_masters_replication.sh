#!/bin/bash
cd $(dirname $0)

for NODE in node1 node2 node3 node4
do
    $NODE/use test -e "drop table if exists test_$NODE"
    $NODE/use test -e "create table test_$NODE( id int not null primary key, serverid int, dbport int, node varchar(100), ts timestamp)"
    $NODE/use test -e "insert into test_$NODE values (1, @@server_id, @@port, '$NODE', null)"
    # echo -n "# Tables in server "
    # $NODE/use -BN -e 'select @@server_id; show tables from test'
    echo "# NODE $NODE created table test_$NODE"
done

sleep 3
echo "# Data in all nodes"
for NODE in node1 node2 node3 node4
do
    $NODE/use -BN -e 'select @@server_id'
    for TABLE_NAME in node1 node2 node3 node4
    do
        $NODE/use test -BN -e "select * from test_$TABLE_NAME"
    done
done

