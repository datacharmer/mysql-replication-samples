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

for N in $(seq 1 9)
do
    if [ -d node$N ]
    then
        NODES[$N]=node$N
    fi
done

for NODE in ${NODES[*]}
do
    $NODE/use test -e "drop table if exists test_$NODE"
    $NODE/use test -e "create table test_$NODE( id int not null primary key, serverid int, dbport int, node varchar(100), ts timestamp)"
    $NODE/use test -e "insert into test_$NODE values (1, @@server_id, @@port, '$NODE', null)"
    echo "# NODE $NODE created table test_$NODE"
done

sleep 3
echo "# Data in all nodes"
for NODE in ${NODES[*]}
do
    $NODE/use -BN -e 'select @@server_id'
    for TABLE_NAME in ${NODES[*]}
    do
        $NODE/use test -BN -e "select * from test_$TABLE_NAME"
    done
done

