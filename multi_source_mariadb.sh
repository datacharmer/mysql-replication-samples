#!/bin/bash
sandbox_name=$HOME/sandboxes/multi_msb_ma10_0_17

make_multiple_sandbox --how_many_nodes=4 ma10.0.17

cd $sandbox_name

#$sandbox_name/n4 -e "change master to master_host='127.0.0.1', master_port=10017, master_user='rsandbox', master_password='rsandbox'"

for NODE in node1 node2 node3
do
    PORT=$($NODE/use -BN -e 'select @@port')
    CHANGE_MASTER="CHANGE MASTER '$NODE' TO master_host='127.0.0.1', master_port=$PORT, master_user='rsandbox', master_password='rsandbox'"
    #echo "$CHANGE_MASTER"
    node4/use -ve "$CHANGE_MASTER"
    START_SLAVE="start slave '$NODE'"
    #echo "$START_SLAVE"
    node4/use -ve "$START_SLAVE"
done

#node4/use -ve "START SLAVE"
