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
    if [ -f /tmp/my_$NODE.cnf ]
    then
        sudo rm /tmp/my_$NODE.cnf
    fi
    if [ -f /tmp/home_my_$NODE.cnf ]
    then
        sudo rm /tmp/home_my_$NODE.cnf
    fi
    sed "s/_SERVERID_/${NODE}00/" < my-template.cnf > /tmp/my_$NODE.cnf
    cp home_my.cnf /tmp/home_my_$NODE.cnf
    echo "[mysql]" >> /tmp/home_my_$NODE.cnf
    # echo "prompt=node$NODE >> " >> /tmp/home_my_$NODE.cnf
    echo "prompt='node$NODE [\\h] {\\u} (\\d) > '" >> /tmp/home_my_$NODE.cnf
    if [ ! -d /opt/docker/mysql ]
    then
        sudo mkdir -p /opt/docker/mysql
        sudo chown -R mysql /opt/docker/mysql
        sudo chgrp -R mysql /opt/docker/mysql
    fi
    if [ -d /opt/docker/mysql/node_$NODE ]
    then
        sudo rm -rf /opt/docker/mysql/node_$NODE
    fi
    # exit
    # cat /tmp/my_$NODE.cnf
    echo ""
    docker run --name mysql-node$NODE  \
        -v /tmp/my_$NODE.cnf:/etc/my.cnf \
        -v /tmp/home_my_$NODE.cnf:/root/home_my.cnf \
        -v /opt/docker/mysql/node_$NODE:/var/lib/mysql \
        -e MYSQL_ROOT_PASSWORD=secret \
        -d mysql:5.7.8-rc
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

DELAY=$(($NUM_NODES*2))
if [[ $DELAY -lt 20 ]]
then
    DELAY=10
fi
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

./set-replication.sh $NUM_NODES
