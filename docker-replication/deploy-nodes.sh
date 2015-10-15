#!/bin/bash

[ -z "$MIN_DOCKER_VERSION" ] && export MIN_DOCKER_VERSION=1.7.0

. ./common.sh

check_docker_version

NUM_NODES=$1
if [ -z "$NUM_NODES" ]
then
    NUM_NODES=3
fi

for NODE in $( seq 1 $NUM_NODES )
do
    export NODE
    echo "# $NODE"
    sed "s/_SERVERID_/${NODE}00/" < my-template.cnf > /tmp/my_$NODE.cnf
    if [ ! -d /opt/docker/mysql ]
    then
        mkdir -p /opt/docker/mysql
        chown -R mysql /opt/docker/mysql
        chgrp -R mysql /opt/docker/mysql
    fi
    if [ -d /opt/docker/mysql/node_$NODE ]
    then
        rm -rf /opt/docker/mysql/node_$NODE
    fi
    # exit
    # cat /tmp/my_$NODE.cnf
    echo ""
    docker run --name mysql-node$NODE  \
        -v /tmp/my_$NODE.cnf:/etc/my.cnf \
        -v /opt/docker/mysql/node_$NODE:/var/lib/mysql \
        -e MYSQL_ROOT_PASSWORD=secret \
        -d mysql:5.7.8-rc
    if [ "$?" != "0" ] ; then exit 1; fi
done

function is_ready
{
    NODE=$1
    IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress}}'  mysql-node$NODE)
    if [ -z "$IP" ]
    then
        echo "## NO IP"
        return
    fi
    PORT=3306
    MYSQL="mysql -u root -psecret -h $IP -P $PORT"
    READY=$($MYSQL -BN -e 'select 1')
    if [ "$READY" == "1" ]
    then
        echo OK
    fi
}

echo "# Waiting for nodes to be ready"

DELAY=$(($NUM_NODES*2))
pause $DELAY
for NODE in $( seq 1 $NUM_NODES )
do
    MAX_ATTEMPTS=30
    ATTEMPTS=0
    node_ready=''
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
        sleep 1
    done
    echo ''
done

./set-replication.sh $NUM_NODES
