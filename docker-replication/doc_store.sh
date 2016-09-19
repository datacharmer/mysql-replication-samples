#!/bin/bash

exists_net=$(docker network ls | grep -w docnet )
if [ -n "$exists_net" ]
then
    docker network rm docnet
fi
docker network create docnet
docker network ls

(set -x
docker run --name mybox --net docnet \
    -e MYSQL_ROOT_PASSWORD=secret -d \
    -v $HOME/data:/data \
    mysql/mysql-server  --plugin-load=mysqlx:mysqlx.so
)
echo "waiting 20 seconds"
sleep 20
(set -x
docker exec -ti mybox mysql -psecret  -e 'source /data/world_x-db/world_x.sql'
docker run --name myshell --rm --net docnet -ti mysql/shell -h mybox -u root -psecret world_x
)
