#!/bin/bash
MASTER_NODE=1
if [ -f DEPLOYED ]
then
    NUM_NODES=$(cat DEPLOYED)
else
    echo "# File 'DEPLOYED' not found. Aborting"
    exit 1
fi

if [ $NUM_NODES -lt 2 ]
then
    echo "# For replication you need more than 1 node. Aborting"
    exit 1
fi

MASTER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}'  mysql-node$MASTER_NODE)
echo "master IP: $MASTER_IP"
MASTER_PORT=3306
# MASTER="mysql -u root -psecret -h $MASTER_IP -P $MASTER_PORT"
MASTER="docker exec -it mysql-node1 mysql"
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

#
# We either use binlog name and position or reset master + MASTER_AUTO_POSITION
#
#MASTER_STATUS=$($MASTER -e 'show master status\G')
#master_file=$(echo "$MASTER_STATUS" | grep File: | awk '{print $2}')
#master_pos=$(echo "$MASTER_STATUS" | grep Position: | awk '{print $2}')
#master_start="MASTER_LOG_FILE='$master_file', MASTER_LOG_POS=$master_pos"

for SLAVE_NODE in $(seq 2 $NUM_NODES)
do
    SLAVE_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}'  mysql-node$SLAVE_NODE)
    echo "slave: $SLAVE_IP"

    SLAVE_PORT=3306
    # SLAVE="mysql -u root -psecret -h $SLAVE_IP -P $SLAVE_PORT"
    SLAVE="docker exec -it mysql-node$SLAVE_NODE mysql "

    echo "# Setting up replication"
    $SLAVE -e 'reset master'
    $SLAVE -e "select @@hostname as SLAVE_$SLAVE_NODE, @@server_id, @@server_uuid"
    SLAVE_RUNNING=$($SLAVE -BN -e 'SHOW SLAVE STATUS')
    [ -n "$SLAVE_RUNNING" ] && $SLAVE -ve 'STOP SLAVE'

    $SLAVE -ve "change master to master_host='$MASTER_IP', master_port=$MASTER_PORT, master_user='rdocker', master_password='rdocker', MASTER_AUTO_POSITION=1"
    # $SLAVE -ve "change master to master_host='$MASTER_IP', master_port=$MASTER_PORT, master_user='rdocker', master_password='rdocker', $master_start"
    $SLAVE -ve 'START SLAVE'
    $SLAVE -e 'SHOW SLAVE STATUS\G' | grep 'Running:'
done

echo "# Creating a table in the master"
$MASTER -e 'create schema if not exists test'
$MASTER -ve 'drop table if exists test.t1'
$MASTER -ve ' create table t1 (i int not null primary key, msg varchar(50), d date, t time, dt datetime);' test
$MASTER -ve " insert into t1 values (1, 'test1', current_date(), now() + interval 11 second, now());" test
sleep $NUM_NODES

exit_code=0
echo "# Retrieving the table from the slaves"
for SLAVE_NODE in $(seq 2 $NUM_NODES)
do
    SLAVE="docker exec -it mysql-node$SLAVE_NODE mysql "
    $SLAVE -e 'select @@hostname, @@server_id, @@server_uuid'
    $SLAVE -e 'select * from test.t1'
    REPLICATED=$($SLAVE -BN -e 'select count(*) from information_schema.tables where table_schema="test" and table_name="t1"' | tr -d '\n' | tr -d '\r')
    if [ "$REPLICATED" == "1" ]
    then
        echo "OK - Slave $SLAVE_NODE has replicated table t1"
    else
        echo "NOT OK - Slave $SLAVE_NODE has NOT replicated table t1"
        exit_code=1
    fi 
done
echo "# Exit code: $exit_code" 
exit $exit_code
