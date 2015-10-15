#!/bin/bash
MASTER_NODE=1
NUM_NODES=$1
[ -z "$NUM_NODES" ] && NUM_NODES=3

MASTER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}'  mysql-node$MASTER_NODE)
echo "master: $MASTER_IP"
MASTER_PORT=3306
MASTER="mysql -u root -psecret -h $MASTER_IP -P $MASTER_PORT"
$MASTER -e 'select @@hostname as MASTER, @@server_id, @@server_uuid'

USER_EXISTS=$($MASTER -BN -e 'select user from mysql.user where user="rdocker"')
if [ -z "$USER_EXISTS" ] 
then
    echo "# Creating replication user in the master"
    $MASTER -ve 'create user rdocker identified by "rdocker"'
    $MASTER -ve 'grant replication slave on *.* to rdocker'
    $MASTER -ve 'grant select on performance_schema.global_variables to rdocker'
    $MASTER -ve 'grant select on performance_schema.session_variables to rdocker'
fi
$MASTER -e 'reset master'


for SLAVE_NODE in $(seq 2 $NUM_NODES)
do
    SLAVE_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}'  mysql-node$SLAVE_NODE)
    echo "slave: $SLAVE_IP"

    SLAVE_PORT=3306
    SLAVE="mysql -u root -psecret -h $SLAVE_IP -P $SLAVE_PORT"

    echo "# Setting up replication"
    $SLAVE -e "select @@hostname as SLAVE_$SLAVE_NODE, @@server_id, @@server_uuid"
    SLAVE_RUNNING=$($SLAVE -BN -e 'SHOW SLAVE STATUS')
    [ -n "$SLAVE_RUNNING" ] && $SLAVE -ve 'STOP SLAVE'

    $SLAVE -ve "change master to master_host='$MASTER_IP', master_port=$MASTER_PORT, master_user='rdocker', master_password='rdocker';"
    $SLAVE -ve 'START SLAVE'
    $SLAVE -e 'SHOW SLAVE STATUS\G' | grep 'Running:'
done

echo "# Creating a table in the master"
$MASTER -e 'create schema if not exists test'
$MASTER -ve 'drop table if exists test.t1'
$MASTER -ve ' create table t1 (i int not null primary key, msg varchar(50), d date, t time, dt datetime);' test
$MASTER -ve " insert into t1 values (1, 'test1', current_date(), now() + interval 11 second, now());" test
sleep $NUM_NODES

echo "# Retrieving the table from the slaves"
for SLAVE_NODE in $(seq 2 $NUM_NODES)
do
    SLAVE_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}'  mysql-node$SLAVE_NODE)
    SLAVE_PORT=3306
    SLAVE="mysql -u root -psecret -h $SLAVE_IP -P $SLAVE_PORT"
    $SLAVE -e 'select @@hostname, @@server_id, @@server_uuid'
    $SLAVE -e 'select * from test.t1'
done

