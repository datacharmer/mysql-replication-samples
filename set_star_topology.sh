#!/bin/bash
#set -x

#
# Proof of concept for a star topology.
# There is a central node (the HUB) and 4 endpoints.
# Every node is a master. 
# Changes from the endpoints are replicated to the hub,
# and from there to the other endpoints.

. ./common.sh

make_multiple_sandbox --how_many_nodes=5 5.7.8

cd ~/sandboxes/multi_msb_5_7_8

for NODE in  node1 node2 node3 node4 node5
do
    ./$NODE/use -e "create table test.not_replicated_$NODE(id int)"
done

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

HUB=node3
ENDPOINTS=(node1 node2 node4 node5)
#HUB_PORT=$(./$HUB/use -BN -e 'select @@port')
HUB_PORT=$( get_port ./$HUB/use)

echo "# HUB $HUB port: $HUB_PORT" 

for NODE in ${ENDPOINTS[*]}
do 
    NODE_PORT=$(get_port ./$NODE/use)
    echo "# node $NODE port: $NODE_PORT" 
    CHANGE_MASTER_FIXED="CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox'" 
    #node_file_and_pos=$(get_change_master_file_and_pos $NODE/use)
    #hub_file_and_pos=$(get_change_master_file_and_pos $HUB/use)
    #CHANGE_MASTER_HUB_TO_NODE=", master_port=$NODE_PORT, $hub_file_and_pos for channel '${HUB}_${NODE}'"
    #CHANGE_MASTER_NODE_TO_HUB=", master_port=$HUB_PORT, $node_file_and_pos for channel '${NODE}_${HUB}'"
    CHANGE_MASTER_NODE_TO_HUB=", master_port=$HUB_PORT, MASTER_AUTO_POSITION=1 for channel '${NODE}_${HUB}'"
    CHANGE_MASTER_HUB_TO_NODE=", master_port=$NODE_PORT, MASTER_AUTO_POSITION=1 for channel '${HUB}_${NODE}'"
    echo "./$NODE/use -e <$CHANGE_MASTER_FIXED $CHANGE_MASTER_NODE_TO_HUB>"
    ./$NODE/use -e "$CHANGE_MASTER_FIXED $CHANGE_MASTER_NODE_TO_HUB"

    echo "./$HUB/use -e <$CHANGE_MASTER_FIXED $CHANGE_MASTER_HUB_TO_NODE>"
    ./$HUB/use -e "$CHANGE_MASTER_FIXED $CHANGE_MASTER_HUB_TO_NODE"

    echo "./$HUB/use -e <start slave for channel '${HUB}_${NODE}'>"
    ./$HUB/use -e "start slave for channel '${HUB}_${NODE}'"

    echo "./$NODE/use -e <start slave for channel '${NODE}_${HUB}'>"
    ./$NODE/use -e "start slave for channel '${NODE}_${HUB}'"
done

for NODE in  node1 node2 node3 node4 node5
do
    ./$NODE/use -e "create table test.table_from_$NODE(id int)"
done
./use_all 'show tables from test'

