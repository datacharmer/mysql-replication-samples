#!/bin/bash
export BASE_IP=172.200.0
export GR_NETWORK=group1
exists_net=$(docker network ls | grep -w $GR_NETWORK )
if [ -n "$exists_net" ]
then
    docker network rm $GR_NETWORK
    if [ "$?" != "0" ]
    then
        echo "Error removing network $GR_NETWORK "
        exit 1
    fi
fi
docker network create --subnet ${BASE_IP}.0/16 --gateway ${BASE_IP}.1 $GR_NETWORK
if [ "$?" != "0" ]
then
    echo "Error creating network $GR_NETWORK "
    exit 1
fi
docker network ls
if [ -f gr_started ]
then
    rm -f gr_started
fi
if [ -f ips ]
then
    rm ips
fi

for node in 1 2 3
do
    export SERVERID=$node
    export IPEND=$(($SERVERID+1))
    perl -pe 's/_SERVER_ID_/$ENV{SERVERID}/;s/_IP_END_/$ENV{IPEND}/;s/_BASE_IP_/$ENV{BASE_IP}/g' my-template.cnf > my${node}.cnf
    datadir=ddnode${node}
    if [ ! -d $datadir ]
    then
        mkdir $datadir
    fi
    unset SERVERID
    docker run -d --name=node$node --net=$GR_NETWORK --hostname=node$node \
        -v $PWD/my${node}.cnf:/etc/my.cnf \
        -v $PWD/data:/data \
        -v $PWD/$datadir:/var/lib/mysql \
        -e MYSQL_ROOT_PASSWORD=secret \
        mysql/mysql-server:5.7.17

    ip=$(docker inspect --format "{{ .NetworkSettings.Networks.$GR_NETWORK.IPAddress}}" node${node})
    echo "${node} $ip" >> ips
done

cat ips
date +%s > gr_started

