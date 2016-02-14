#!/bin/bash
NAME=$1
if [ -n "$NAME" ] 
then
    shift
else
    NAME=mybox
fi
set -x
docker run --name $NAME -e MYSQL_ROOT_PASSWORD=secret -d mysql/mysql-server $@

