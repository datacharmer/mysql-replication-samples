#!/bin/bash
# "OBSOLETE: use multi_source.sh instead"
# 
for NODE in node1 node2 node3 node4
do
    for MASTER in node1 node2 node3 node4
    do
        if [ $NODE != $MASTER ]
        then
            PORT=$($MASTER/use -BN -e 'select @@port')
            CHANGE_MASTER="CHANGE MASTER TO master_host='127.0.0.1', master_port=$PORT, master_user='rsandbox', master_password='rsandbox' for channel '$MASTER'"
            #echo "$CHANGE_MASTER"
            $NODE/use -ve "$CHANGE_MASTER"
            START_SLAVE="start slave for channel '$MASTER'"
            #echo "$START_SLAVE"
            $NODE/use -ve "$START_SLAVE"
        fi
    done
done

### node4/use -ve "START SLAVE"
