#!/bin/bash

VERSION=$1
FLAVOR=$2
TOPOLOGY=$3

[ -z "$TOPOLOGY" ] && FLAVOR=none

case $FLAVOR in
    mysql)
        ;;
    mariadb)
        ;;
    *)
        unset TOPOLOGY
        ;;
esac

case $TOPOLOGY in
    FAN-IN)
        ;;
    ALL-MASTERS)
        ;;
    *)
        unset TOPOLOGY
        ;;
esac


if [ -z "$TOPOLOGY" ]
then
    echo "VERSION, FLAVOR, and TOPOLOGY  required"
    echo "Where VERSION is an indentifier like 5.7.7 or ma10.0.20 "
    echo "      FLAVOR is either mysql or mariadb"
    echo "      TOPOLOGY is either FAN-IN or ALL-MASTERS"
   exit 1 
fi

[ -z "$SANDBOX_BINARY" ] && SANDBOX_BINARY=$HOME/opt/mysql

if [ ! -d $SANDBOX_BINARY ]
then
    echo "$SANDBOX_BINARY does not exist"
    echo "Set the variable SANDBOX_BINARY to indicate where to find the expanded tarballs for MySQL::Sandbox"
    exit 1
fi

if [ ! -d $SANDBOX_BINARY ]
then
    echo "$SANDBOX_BINARY/$VERSION not found"
    exit 1
fi

# ---------------
DASHED_VERSION=$(echo $VERSION| tr '.' '_')

sandbox_name=$HOME/sandboxes/multi_msb_$DASHED_VERSION

if [ -z "$SKIP_INSTALLATION"]
then
    make_multiple_sandbox --how_many_nodes=4 $VERSION
fi

initialdir=$PWD
cd $sandbox_name

function set_GTID
{
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
}

CHANGE_MASTER_TEMPLATE=""
CHANGE_MASTER_TEMPLATE_MYSQL="CHANGE MASTER TO master_host='127.0.0.1', master_port=_PORT_, master_user='rsandbox', master_password='rsandbox' for channel '_CHANNEL_'"
CHANGE_MASTER_TEMPLATE_MARIADB="CHANGE MASTER '_CHANNEL_' TO master_host='127.0.0.1', master_port=_PORT_, master_user='rsandbox', master_password='rsandbox'"
START_SLAVE_TEMPLATE_MYSQL="START SLAVE for channel "
START_SLAVE_TEMPLATE_MARIADB="START SLAVE "
if [ $FLAVOR == mysql ]
then
    if [ -z "$SKIP_INSTALLATION" ]
    then
        set_GTID
    fi
    CHANGE_MASTER_TEMPLATE=$CHANGE_MASTER_TEMPLATE_MYSQL
    START_SLAVE_TEMPLATE=$START_SLAVE_TEMPLATE_MYSQL
else
    CHANGE_MASTER_TEMPLATE=$CHANGE_MASTER_TEMPLATE_MARIADB
    START_SLAVE_TEMPLATE=$START_SLAVE_TEMPLATE_MARIADB
fi

echo "# Setting topology $TOPOLOGY"

if [ "$TOPOLOGY" == "ALL-MASTERS" ]
then
    # ALL-MASTERS
    for NODE in node1 node2 node3 node4
    do
        for MASTER in node1 node2 node3 node4
        do
            if [ $NODE != $MASTER ]
            then
                #set -x
                PORT=$($MASTER/use -BN -e 'select @@port')
                CHANGE_MASTER=$CHANGE_MASTER_TEMPLATE
                CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_PORT_/$PORT/")
                CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_CHANNEL_/$MASTER/")
                #echo "#$CHANGE_MASTER#"
                $NODE/use -ve "$CHANGE_MASTER"
                START_SLAVE="$START_SLAVE_TEMPLATE '$MASTER'"
                echo "$START_SLAVE"
                $NODE/use -ve "$START_SLAVE"
                #set +x
            fi
        done
    done
    cp -v $initialdir/test_all_masters_replication.sh $sandbox_name
else
    # FAN-IN
    for NODE in node1 node2 node3
    do
        PORT=$($NODE/use -BN -e 'select @@port')
        CHANGE_MASTER=$CHANGE_MASTER_TEMPLATE
        CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_PORT_/$PORT/")
        CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_CHANNEL_/$NODE/")
        #echo "$CHANGE_MASTER"
        node4/use -ve "$CHANGE_MASTER"
        START_SLAVE="$START_SLAVE_TEMPLATE '$NODE'"
        #echo "$START_SLAVE"
        node4/use -ve "$START_SLAVE"
    done
    cp -v $initialdir/test_multi_source_replication.sh $sandbox_name
fi
### node4/use -ve "START SLAVE"
