#!/bin/bash
multi_sb=$1
if [ -z "$multi_sb" ]
then
    echo multiple sandbox path needed
    exit 1
fi
if [ ! -d $multi_sb ]
then
    echo directory $multi_sb not found
    exit 1
fi
if [ ! -d "$multi_sb/node3" ]
then
    echo directory $multi_sb/node3 not found
    exit 1
fi
cd $multi_sb

for N in  1 2 3 ; do 
    ./n$N -e "create schema if not exists test"
    ./n$N -e "drop table if exists test.t$N"
    ./n$N -e "create table test.t$N(id int not null primary key, sid int)"
    ./n$N -e "insert into  test.t$N values ($N, @@server_id)" 
done

#for N in 1 2 3 ; do 
#    ./n$N -e "insert into  test.t$N values ($N + 1, @@server_id)" 
#    ./n$N -e "insert into  test.t$N values ($N + 2, @@server_id)" 
#done

./use_all 'select * from test.t1 union select * from test.t2 union select * from test.t3'
