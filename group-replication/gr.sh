#!/bin/bash
exists_net=$(docker network ls | grep -w group1 )
if [ -z "$exists_net" ]
then
    docker network create group1
fi
docker network ls

if [ -f ips ]
then
    rm ips
fi
for node in 1 2 3
do
    export SERVERID=$node
    export IPEND=$(($SERVERID+1))
    perl -pe 's/_SERVER_ID_/$ENV{SERVERID}/;s/_IP_END_/$ENV{IPEND}/' my-template.cnf > my${node}.cnf
    datadir=ddnode${node}
    if [ ! -d $datadir ]
    then
        mkdir $datadir
    fi
    unset SERVERID
    docker run -d --name=node$node --net=group1 --hostname=node$node \
        -v $PWD/my${node}.cnf:/etc/my.cnf \
        -v $PWD/data:/data \
        -v $PWD/$datadir:/var/lib/mysql \
        -e MYSQL_ROOT_PASSWORD=secret \
        mysql/mysql-server:5.7.17

    ip=$(docker inspect --format '{{ .NetworkSettings.Networks.group1.IPAddress}}' node${node})
    echo "${node} $ip" >> ips
done

cat ips
