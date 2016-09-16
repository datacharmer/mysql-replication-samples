#!/bin/bash
NAME=$1
if [ -n "$NAME" ] 
then
    shift
else
    NAME=mybox
fi
set -x

VOLUME="-v $HOME/docker/mysql/single:/var/lib/mysql"
PORT="-p 5000:3306"
docker run --name $NAME -e MYSQL_ROOT_PASSWORD=secret -d $VOLUME $PORT mysql/mysql-server $@

