#!/bin/bash
echo "OBSOLETE: use multi_source.sh instead"
exit
#
VERSION=ma10.0.20

# ---------------
DASHED_VERSION=$(echo $VERSION| tr '.' '_')

sandbox_name=$HOME/sandboxes/multi_msb_$DASHED_VERSION

make_multiple_sandbox --how_many_nodes=4 $VERSION


initialdir=$PWD
cd $sandbox_name

if [ -n "$ALL_MASTERS" ]
then
     $initialdir/all_masters_mariadb.sh
     cp -v $initialdir/test_all_masters_replication.sh $sandbox_name
else
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
    cp -v $initialdir/test_multi_source_replication.sh $sandbox_name
fi
#node4/use -ve "START SLAVE"
