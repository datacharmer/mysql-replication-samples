#!/bin/bash
MYSQL_VERSION=$1
[ -z "$MYSQL_VERSION" ] && MYSQL_VERSION=5.7.17

make_multiple_sandbox --gtid --group_directory=GR $MYSQL_VERSION

if [ "$?" != "0" ] ; then exit 1 ; fi
multi_sb=$HOME/sandboxes/GR

baseport=$($multi_sb/n1 -BN -e 'select @@port')
baseport=$(($baseport+99))

port1=$(($baseport+1))
port2=$(($baseport+2))
port3=$(($baseport+3))
for N in 1 2 3
do
    myport=$(($baseport+N))
    options=(
        binlog_checksum=NONE
        log_slave_updates=ON
        plugin-load=group_replication.so
        group_replication=FORCE_PLUS_PERMANENT
        group_replication_start_on_boot=OFF
        group_replication_bootstrap_group=OFF
        transaction_write_set_extraction=XXHASH64
        loose-group_replication_group_name="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        loose-group_replication_local_address="127.0.0.1:$myport"
        loose-group_replication_group_seeds="127.0.0.1:$port1,127.0.0.1:$port2,127.0.0.1:$port3"
        loose-group-replication-single-primary-mode=off
    )
    # group_replication_gtid_assignment_block_size=1000
    $multi_sb/node$N/add_option ${options[*]}

    user_cmd='reset master;'
    user_cmd="$user_cmd CHANGE MASTER TO MASTER_USER='rsandbox', MASTER_PASSWORD='rsandbox' FOR CHANNEL 'group_replication_recovery';"

    $multi_sb/node$N/use -v -u root -e "$user_cmd"
done


START_CMD="SET GLOBAL group_replication_bootstrap_group=ON;"
START_CMD="$START_CMD START GROUP_REPLICATION;"
START_CMD="$START_CMD SET GLOBAL group_replication_bootstrap_group=OFF;"
$multi_sb/n1 -v -e "$START_CMD"
sleep 1
$multi_sb/n2 -v -e 'START GROUP_REPLICATION;'
sleep 1
$multi_sb/n3 -v -e 'START GROUP_REPLICATION;'
sleep 1
$multi_sb/use_all 'select * from performance_schema.replication_group_members'

