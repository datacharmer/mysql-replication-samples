#!/bin/bash
MASTER_NODE=1
if [ -f DEPLOYED ]
then
    NUM_NODES=$(cat DEPLOYED)
else
    echo "# File 'DEPLOYED' not found. Aborting"
    exit 1
fi

. ./common.sh

if [ $NUM_NODES -lt 2 ]
then
    echo "# For replication you need more than 1 node. Aborting"
    exit 1
fi

MASTER_PORT=3306
MASTER1="docker exec -it mysql-node1 mysql"
MASTER2="docker exec -it mysql-node2 mysql"
$MASTER1 -e 'select @@hostname as MASTER, @@server_id, @@server_uuid, @@version'
$MASTER2 -e 'select @@hostname as MASTER, @@server_id, @@server_uuid, @@version'

USER_EXISTS=$($MASTER1 -BN -e 'select user from mysql.user where user="rdocker"')
if [ -z "$USER_EXISTS" ] 
then
    echo "# Creating replication user in the master"
    $MASTER1 -ve 'create user rdocker identified by "rdocker"'
    $MASTER1 -ve 'grant replication slave on *.* to rdocker'
    $MASTER2 -ve 'create user rdocker identified by "rdocker"'
    $MASTER2 -ve 'grant replication slave on *.* to rdocker'
fi

$MASTER1 -e 'reset master'
$MASTER2 -e 'reset master'

#
# We either use binlog name and position or reset master + MASTER_AUTO_POSITION
#
#MASTER_STATUS=$($MASTER -e 'show master status\G')
#master_file=$(echo "$MASTER_STATUS" | grep File: | awk '{print $2}')
#master_pos=$(echo "$MASTER_STATUS" | grep Position: | awk '{print $2}')
#master_start="MASTER_LOG_FILE='$master_file', MASTER_LOG_POS=$master_pos"

for SLAVE_NODE in $(seq 3 $NUM_NODES)
do

    SLAVE_PORT=3306
    SLAVE="docker exec -it mysql-node$SLAVE_NODE mysql "

    echo "# Setting up replication"
    $SLAVE -e 'reset master'
    $SLAVE -e "select @@hostname as SLAVE_$SLAVE_NODE, @@server_id, @@server_uuid, @@version"
    SLAVE_RUNNING=$($SLAVE -BN -e 'SHOW SLAVE STATUS')
    [ -n "$SLAVE_RUNNING" ] && $SLAVE -ve 'STOP SLAVE'

    #$SLAVE -ve "change master to master_host='mysql-node1', master_port=$MASTER_PORT, master_user='rdocker', master_password='rdocker', MASTER_AUTO_POSITION=1"
    $SLAVE -ve "change master to master_host='mysql-node1', master_port=$MASTER_PORT,  MASTER_AUTO_POSITION=1 for channel 'master1'"
    $SLAVE -ve "change master to master_host='mysql-node2', master_port=$MASTER_PORT,  MASTER_AUTO_POSITION=1 for channel 'master2'"
    $SLAVE -ve 'START SLAVE user="rdocker" password="rdocker" '
    $SLAVE -e 'SHOW SLAVE STATUS\G' | grep 'Channel_Name:\|Running:'
done

if [ -n "$SKIP_TEST" ]
then
    exit
fi
echo "# Creating a table in the master"
$MASTER1 -e  'create schema if not exists test'
$MASTER1 -ve 'drop table if exists test.t1'
$MASTER1 -ve 'create table t1 (i int not null primary key, msg varchar(50), d date, t time, dt datetime);' test
$MASTER1 -ve "insert into t1 values (1, 'test1', current_date(), now() + interval 11 second, now());" test
$MASTER1 -ve "insert into t1 values (2, 'test2', current_date(), now() + interval 12 second, now());" test
$MASTER2 -e  'create schema if not exists test'
$MASTER2 -ve 'drop table if exists test.t2'
$MASTER2 -ve 'create table t2 (i int not null primary key, msg varchar(50), d date, t time, dt datetime);' test
$MASTER2 -ve "insert into t2 values (1, 'test1', current_date(), now() + interval 11 second, now());" test
pause 10

exit_code=0
echo "# Retrieving the table from the slaves"
for SLAVE_NODE in $(seq 2 $NUM_NODES)
do
    SLAVE="docker exec -it mysql-node$SLAVE_NODE mysql "
    $SLAVE -e 'select @@hostname, @@server_id, @@server_uuid'
    $SLAVE -e 'select * from test.t1'
    $SLAVE -e 'select * from test.t2'
    REPLICATED1=$($SLAVE -BN -e 'select count(*) from information_schema.tables where table_schema="test" and table_name="t2"' | tr -d '\n' | tr -d '\r')
    REPLICATED2=$($SLAVE -BN -e 'select count(*) from information_schema.tables where table_schema="test" and table_name="t2"' | tr -d '\n' | tr -d '\r')
    if [ "$REPLICATED1" == "1" ]
    then
        echo "OK - Slave $SLAVE_NODE has replicated table t1"
    else
        echo "NOT OK - Slave $SLAVE_NODE has NOT replicated table t1"
        exit_code=1
    fi 
    if [ "$REPLICATED2" == "1" ]
    then
        echo "OK - Slave $SLAVE_NODE has replicated table t2"
    else
        echo "NOT OK - Slave $SLAVE_NODE has NOT replicated table t2"
        exit_code=1
    fi 
done
echo "# Exit code: $exit_code" 
exit $exit_code
