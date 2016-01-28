#!/bin/bash
NAME=$1
[ -z "$NAME" ] && NAME=mybox

docker run --name $NAME -e MYSQL_ROOT_PASSWORD=secret -d mysql/mysql-server $@

