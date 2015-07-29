#!/bin/bash
#set -x

make_multiple_sandbox --how_many_nodes=5 5.7.8

cd ~/sandboxes/multi_msb_5_7_8

OPTIONS="master-info-repository=table "
OPTIONS="$OPTIONS relay-log-info-repository=table"
OPTIONS="$OPTIONS gtid_mode=ON"
OPTIONS="$OPTIONS enforce-gtid-consistency"
HUB_OPTIONS="$OPTIONS log-slave-updates "
CHANGED=""
HUB=node3
for NODE in  node1 node2 node3 node4 node5
do
    LOCAL_OPTIONS=$OPTIONS
    if [ $NODE == $HUB ]
    then
        LOCAL_OPTIONS=$HUB_OPTIONS
    fi
    for OPTION in $LOCAL_OPTIONS
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
    ./restart_all
fi

./use_all 'reset master'

HUB=node3
ENDPOINTS=(node1 node2 node4 node5)
HUB_PORT=$(./$HUB/use -BN -e 'select @@port')
echo "# HUB $HUB port: $HUB_PORT" 

for NODE in ${ENDPOINTS[*]}
do 
    NODE_PORT=$(./$NODE/use -BN -e 'select @@port')
    echo "# node $NODE port: $NODE_PORT" 
    CHANGE_MASTER_FIXED="CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox'" 
    CHANGE_MASTER_HUB_TO_NODE=", master_port=$NODE_PORT for channel '${HUB}_${NODE}'"
    CHANGE_MASTER_NODE_TO_HUB=", master_port=$HUB_PORT for channel '${NODE}_${HUB}'"
    echo "./$NODE/use -e <$CHANGE_MASTER_FIXED $CHANGE_MASTER_NODE_TO_HUB>"
    ./$NODE/use -e "$CHANGE_MASTER_FIXED $CHANGE_MASTER_NODE_TO_HUB"

    echo "./$HUB/use -e <$CHANGE_MASTER_FIXED $CHANGE_MASTER_HUB_TO_NODE>"
    ./$HUB/use -e "$CHANGE_MASTER_FIXED $CHANGE_MASTER_HUB_TO_NODE"

    echo "./$HUB/use -e <start slave for channel '${HUB}_${NODE}'>"
    ./$HUB/use -e "start slave for channel '${HUB}_${NODE}'"

    echo "./$NODE/use -e <start slave for channel '${NODE}_${HUB}'>"
    ./$NODE/use -e "start slave for channel '${NODE}_${HUB}'"
done


