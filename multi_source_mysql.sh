#!/bin/bash
VERSION=5.7.8

# ---------------
DASHED_VERSION=$(echo $VERSION| tr '.' '_')

sandbox_name=$HOME/sandboxes/multi_msb_$DASHED_VERSION

make_multiple_sandbox --how_many_nodes=4 $VERSION

initialdir=$PWD
cd $sandbox_name
cp -v $initialdir/test_multi_source_replication.sh $sandbox_name

OPTIONS="master-info-repository=table "
OPTIONS="$OPTIONS relay-log-info-repository=table"
OPTIONS="$OPTIONS gtid_mode=ON"
OPTIONS="$OPTIONS log-slave-updates enforce-gtid-consistency"
CHANGED=""
for NODE in node1 node2 node3 node4
do
    for OPTION in $OPTIONS
    do
        option_exists=$(grep $OPTION $NODE/my.sandbox.cnf)
        if [ -z "$option_exists" ]
        then
            echo "$OPTION" >> $NODE/my.sandbox.cnf
            echo "# option '$OPTION' added to $NODE configuration file"
            CHANGED=1
        else
            echo "# option '$OPTION' already exists in $NODE configuration file"
        fi
    done
done
if [ -n "$CHANGED" ]
then
    ./use_all 'reset master'
    ./restart_all
fi

if [ -n "$ALL_MASTERS" ]
then
     $initialdir/all_masters_mysql.sh
else

    for NODE in node1 node2 node3
    do
        PORT=$($NODE/use -BN -e 'select @@port')
        CHANGE_MASTER="CHANGE MASTER TO master_host='127.0.0.1', master_port=$PORT, master_user='rsandbox', master_password='rsandbox' for channel '$NODE'"
        #echo "$CHANGE_MASTER"
        node4/use -ve "$CHANGE_MASTER"
        START_SLAVE="start slave for channel '$NODE'"
        #echo "$START_SLAVE"
        node4/use -ve "$START_SLAVE"

    done
fi
### node4/use -ve "START SLAVE"
