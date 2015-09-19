#!/bin/bash
# Copyright 2015 Giuseppe Maxia
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

#
# Proof of concept for a star topology.
# There is a central node (the HUB) and 4 endpoints.
# Every node is a master. 
# Changes from the endpoints are replicated to the hub,
# and from there to the other endpoints.

VERSION=$1
FLAVOR=$2
cd $(dirname $0)
initialdir=$PWD


case $FLAVOR in
    mysql)
        ;;
    mariadb)
        ;;
    *)
        unset VERSION
        ;;
esac

if [ -z "$VERSION" ]
then
    echo "VERSION and FLAVOR required"
    echo "Where VERSION is an indentifier like 5.7.7 or ma10.0.20 "
    echo "      and FLAVOR is either mysql or mariadb"
   exit 1 
fi

. ./common.sh

[ -z "$SANDBOX_BINARY" ] && SANDBOX_BINARY=$HOME/opt/mysql

if [ ! -d $SANDBOX_BINARY/$VERSION ]
then
    echo "$SANDBOX_BINARY/$VERSION does not exist"
    echo "Set the variable SANDBOX_BINARY to indicate where to find the expanded tarballs for MySQL::Sandbox"
    exit 1
fi

DASHED_VERSION=$(echo $VERSION| tr '.' '_')
sandbox_name=$HOME/sandboxes/multi_msb_$DASHED_VERSION

make_multiple_sandbox --how_many_nodes=5 $VERSION

cp -v ../multi_source/test_all_masters_replication.sh $sandbox_name
cd $sandbox_name
./use_all 'reset master'

#for NODE in  node1 node2 node3 node4 node5
#do
#    ./$NODE/use -e "create table test.not_replicated_$NODE(id int)"
#done

OPTIONS="master-info-repository=table "
OPTIONS="$OPTIONS relay-log-info-repository=table"
OPTIONS="$OPTIONS gtid_mode=ON"
OPTIONS="$OPTIONS enforce-gtid-consistency"
if [ "$FLAVOR" == "mariadb" ]
then
    OPTIONS=""
fi

HUB_OPTIONS="$OPTIONS log-slave-updates "
HUB=node3
NODE_COUNT=0
for NODE in  node1 node2 node3 node4 node5
do
    CHANGED=""
    NODE_COUNT=$(($NODE_COUNT+1))
    LOCAL_OPTIONS=$OPTIONS
    if [ $NODE == $HUB ]
    then
        LOCAL_OPTIONS=$HUB_OPTIONS
    fi
    if [ "$FLAVOR" == "mariadb" ]
    then
        SERVER_ID=$($NODE/use -BN -e 'select @@server_id')
        DOMAIN=$(($SERVER_ID*10))
        LOCAL_OPTIONS="$LOCAL_OPTIONS gtid_domain_id=$DOMAIN"
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
    if [ -n "$CHANGED" ]
    then
        $NODE/restart
    fi
done

HUB=node3
ENDPOINTS=(node1 node2 node4 node5)
#HUB_PORT=$(./$HUB/use -BN -e 'select @@port')
HUB_PORT=$( get_port ./$HUB/use)

echo "# HUB $HUB port: $HUB_PORT" 

for NODE in ${ENDPOINTS[*]}
do 
    NODE_PORT=$(get_port ./$NODE/use)
    echo "# node $NODE port: $NODE_PORT" 
    NODE_CHANNEL=hub_${NODE}
    HUB_CHANNEL=${NODE}_hub
    CHANGE_MASTER_FIXED="master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox'" 
    case $FLAVOR in 
        mariadb)
            auto_position="MASTER_USE_GTID=current_pos"
            CHANGE_MASTER_NODE_TO_HUB="CHANGE MASTER '$NODE_CHANNEL' TO $CHANGE_MASTER_FIXED, master_port=$HUB_PORT, $auto_position "
            CHANGE_MASTER_HUB_TO_NODE="CHANGE MASTER '$HUB_CHANNEL' TO $CHANGE_MASTER_FIXED, master_port=$NODE_PORT, $auto_position "
            START_SLAVE_NODE="START SLAVE '$NODE_CHANNEL' "
            START_SLAVE_HUB="START SLAVE '$HUB_CHANNEL' "
            ;;
        mysql)
            auto_position="MASTER_AUTO_POSITION=1"
            CHANGE_MASTER_NODE_TO_HUB="CHANGE MASTER TO $CHANGE_MASTER_FIXED, master_port=$HUB_PORT, $auto_position for channel '$NODE_CHANNEL'"
            CHANGE_MASTER_HUB_TO_NODE="CHANGE MASTER TO $CHANGE_MASTER_FIXED, master_port=$NODE_PORT, $auto_position for channel '$HUB_CHANNEL'"
            START_SLAVE_NODE="START SLAVE FOR CHANNEL '$NODE_CHANNEL'"
            START_SLAVE_HUB="START SLAVE FOR CHANNEL '$HUB_CHANNEL'"
        ;;
        *)
            echo "unexpected flavor <$FLAVOR>"
            exit 1
            ;;
    esac
    echo "./$NODE/use -e \"$CHANGE_MASTER_NODE_TO_HUB\""
    ./$NODE/use -e "$CHANGE_MASTER_NODE_TO_HUB"

    echo "./$HUB/use -e \"$CHANGE_MASTER_HUB_TO_NODE\""
    ./$HUB/use -e "$CHANGE_MASTER_HUB_TO_NODE"

    echo "./$HUB/use -e \"$START_SLAVE_HUB\""
    ./$HUB/use -e "$START_SLAVE_HUB"

    echo "./$NODE/use -e \"$START_SLAVE_NODE\""
    ./$NODE/use -e "$START_SLAVE_NODE"
done

