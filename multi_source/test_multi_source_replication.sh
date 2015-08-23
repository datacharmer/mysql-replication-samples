#!/bin/bash
# Copyright 2015 Giuseppe Maxia
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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

