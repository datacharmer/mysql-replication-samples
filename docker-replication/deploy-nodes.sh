#!/bin/bash

[ -z "$MIN_DOCKER_VERSION" ] && export MIN_DOCKER_VERSION=1.7.0
curdir=$(dirname $0)

. $curdir/common.sh
[ -z "$MYSQL_IMAGE" ] && MYSQL_IMAGE=mysql/mysql-server

check_docker_version
check_operating_system

NUM_NODES=$1
if [ -z "$NUM_NODES" ]
then
    NUM_NODES=3
fi

if [ $NUM_NODES -gt 20 ]
then
    echo "# Can't run more than 20 nodes"
    exit 1
fi

for NODE in $( seq 1 $NUM_NODES )
do
    export NODE
    echo "# $NODE"
    if [ -f $DOCKER_TMP/my_$NODE.cnf ]
    then
        rm $DOCKER_TMP/my_$NODE.cnf
    fi
    if [ -f $DOCKER_TMP/home_my_$NODE.cnf ]
    then
        rm $DOCKER_TMP/home_my_$NODE.cnf
    fi
    sed "s/_SERVERID_/${NODE}00/" < my-template.cnf > $DOCKER_TMP/my_$NODE.cnf
    cp home_my.cnf $DOCKER_TMP/home_my_$NODE.cnf
    echo "[mysql]" >> $DOCKER_TMP/home_my_$NODE.cnf
    # echo "prompt=node$NODE >> " >> $DOCKER_TMP/home_my_$NODE.cnf
    if [ "$NODE" == "1" ]
    then
        NAME=master
    else
        NAME="node$NODE"
    fi
    echo "prompt='$NAME [\\h] {\\u} (\\d) > '" >> $DOCKER_TMP/home_my_$NODE.cnf
    if [ "$DATA_VOLUME" == "YES" ]
    then
        if [ ! -d $DOCKER_DATA ]
        then
            mkdir -p $DOCKER_DATA
            sudo chown -R mysql $DOCKER_DATA
            sudo chgrp -R mysql $DOCKER_DATA
        fi
        if [ -d $DOCKER_DATA/node_$NODE ]
        then
            sudo rm -rf $DOCKER_DATA/node_$NODE
        fi
        DATA_OPTION="-v $DOCKER_DATA/node_$NODE:/var/lib/mysql"
    else
        DATA_OPTION=""
    fi
    echo ""
    echo "# Deploying $MYSQL_IMAGE into container mysql-node$NODE"
    docker run --name mysql-node$NODE  \
        -v $DOCKER_TMP/my_$NODE.cnf:/etc/my.cnf \
        -v $DOCKER_TMP/home_my_$NODE.cnf:/root/home_my.cnf \
        -e MYSQL_ROOT_PASSWORD=secret $DATA_OPTION \
        -d $MYSQL_IMAGE

    if [ "$?" != "0" ] ; then exit 1; fi
done

function is_ready
{
    NODE=$1
    MYSQL="docker exec -it mysql-node$NODE mysql --defaults-file=/root/home_my.cnf "
    # 'docker exec' leaves a trailing newline in the result
    READY=$($MYSQL -BN -e 'select 12345' | tr -d '\n' | tr -d '\r')
    if [ "$READY" == "12345" ]
    then
        echo OK
    fi
}

echo "# Waiting for nodes to be ready"

pause 10
for NODE in $( seq 1 $NUM_NODES )
do
    MAX_ATTEMPTS=30
    ATTEMPTS=0
    node_ready=''
    echo "# Checking container mysql-node$NODE"
    while [ "$node_ready" != "OK" ]
    do
        ATTEMPTS=$(($ATTEMPTS+1))
        if [[ $ATTEMPTS -gt $MAX_ATTEMPTS ]]
        then
            echo "## Maximum number of attempts exceeded "
            exit 1
        fi
        node_ready=$(is_ready $NODE)
        echo "# NODE $NODE - $ATTEMPTS - $node_ready"
        [ "$node_ready" != "OK" ] && sleep 1
    done
    echo ''
done

echo $NUM_NODES > DEPLOYED

for NODE in $( seq 1 $NUM_NODES )
do
    echo '#!/bin/bash' > n$NODE
    echo "docker exec -it mysql-node$NODE mysql \"\$@\"" > n$NODE
    chmod +x n$NODE
    if [ "$NODE" == "1" ]
    then
        ln -s n1 m
    else
        SN=$(($NODE-1))
        ln -s n$NODE s$SN
    fi
    #
    # Set username and password in private file
    # Notice that this operation cannot happen before MySQL initialization
    docker exec -it mysql-node$NODE cp /root/home_my.cnf /root/.my.cnf
done

if [ -n "$SKIP_REPLICATION" ]
then
    echo "# Skipping replication setup"
    exit
fi
./set-replication.sh
