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

if [ ! -d $SANDBOX_BINARY/$VERSION ]
then
    echo "$SANDBOX_BINARY/$VERSION not found"
    exit 1
fi

# ---------------
DASHED_VERSION=$(echo $VERSION| tr '.' '_')

if [ -n "$DRYRUN" -o -n "$DRY_RUN" ]
then
    SKIP_INSTALLATION=1
    DRYRUN=1
fi

sandbox_name=$HOME/sandboxes/multi_msb_$DASHED_VERSION
initialdir=$PWD
if [ -n "$DRYRUN" ]
then
    echo "# make_multiple_sandbox --how_many_nodes=4 $VERSION"
    echo "cd $sandbox_name"
fi

if [ -z "$SKIP_INSTALLATION" ]
then
    make_multiple_sandbox --how_many_nodes=4 $VERSION
    cd $sandbox_name
    ./use_all 'reset master'
fi


function set_GTID
{
    OPTIONS="master-info-repository=table "
    OPTIONS="$OPTIONS relay-log-info-repository=table"
    OPTIONS="$OPTIONS gtid_mode=ON"
    #OPTIONS="$OPTIONS log-slave-updates"
    OPTIONS="$OPTIONS enforce-gtid-consistency"
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
        ./restart_all
    fi
}

CHANGE_MASTER_TEMPLATE=""
CHANGE_MASTER_TEMPLATE_MYSQL="CHANGE MASTER TO MASTER_HOST='127.0.0.1', MASTER_PORT=_PORT_, MASTER_USER='rsandbox', MASTER_PASSWORD='rsandbox', MASTER_AUTO_POSITION=1 for channel '_CHANNEL_'"
CHANGE_MASTER_TEMPLATE_MARIADB="CHANGE MASTER '_CHANNEL_' TO MASTER_HOST='127.0.0.1', MASTER_PORT=_PORT_, MASTER_USER='rsandbox', MASTER_PASSWORD='rsandbox', MASTER_USE_GTID=current_pos "
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
    ./use_all 'set global gtid_domain_id=@@server_id*10'
fi

echo "# Setting topology $TOPOLOGY"

if [ "$TOPOLOGY" == "ALL-MASTERS" ]
then
    # ALL-MASTERS
    for NODE in node1 node2 node3 node4
    do
        echo "# node $NODE"
        for MASTER in node1 node2 node3 node4
        do
            if [ $NODE != $MASTER ]
            then
                #set -x
                if [ -n "$DRYRUN" ]
                then
                    PORT='$MASTER_PORT'
                else
                    PORT=$($MASTER/use -BN -e 'select @@port')
                fi
                CHANGE_MASTER=$CHANGE_MASTER_TEMPLATE
                CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_PORT_/$PORT/")
                CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_CHANNEL_/$MASTER/")
                START_SLAVE="$START_SLAVE_TEMPLATE '$MASTER'"
                #echo "#$CHANGE_MASTER#"
                #echo "$START_SLAVE"
                if [ -n "$DRYRUN" ]
                then
                    # echo "# $NODE"
                    echo "$CHANGE_MASTER"
                    echo "$START_SLAVE"
                else
                    $NODE/use -ve "$CHANGE_MASTER"
                    $NODE/use -ve "$START_SLAVE"
                fi
                #set +x
            fi
        done
    done
    if [ -z "$DRYRUN" ]
    then
        cp -v $initialdir/test_all_masters_replication.sh $sandbox_name
    fi
else
    # FAN-IN
    for NODE in node1 node2 node3
    do
        if [ -n "$DRYRUN" ]
        then
            PORT='$MASTER_PORT'
        else
            PORT=$($NODE/use -BN -e 'select @@port')
        fi
        CHANGE_MASTER=$CHANGE_MASTER_TEMPLATE
        CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_PORT_/$PORT/")
        CHANGE_MASTER=$(echo $CHANGE_MASTER |sed -e "s/_CHANNEL_/$NODE/")
        START_SLAVE="$START_SLAVE_TEMPLATE '$NODE'"
        #echo "$CHANGE_MASTER"
        #echo "$START_SLAVE"
        if [ -n "$DRYRUN" ]
        then
            echo "# node4"
            echo "$CHANGE_MASTER"
        else
            node4/use -ve "$CHANGE_MASTER"
            node4/use -ve "$START_SLAVE"
        fi
    done
    if [ -z "$DRYRUN" ]
    then
        cp -v $initialdir/test_multi_source_replication.sh $sandbox_name
    fi
fi
### node4/use -ve "START SLAVE"
