#!/bin/bash
set -x
docker run --name mybox1 --hostname hmybox1 \
    -e MYSQL_DATABASE=db1 \
    -e MYSQL_USER=myuser1 \
    -e MYSQL_PASSWORD=mypassword1 \
    -e MYSQL_ROOT_PASSWORD=secret -d mysql/mysql-server
docker run --name mybox2 --hostname hmybox2 \
	-e MYSQL_DATABASE=db2 \
	-e MYSQL_USER=myuser2 \
	-e MYSQL_PASSWORD=mypassword2 \
	-e MYSQL_ROOT_PASSWORD=secret -d mysql/mysql-server

exists_net=$(docker network ls | grep my_net)
[ -z "$exists_net" ] && docker network create my_net

docker run --name mybox1n --hostname hmybox1n \
    --net my_net \
    -e MYSQL_DATABASE=db1 \
    -e MYSQL_USER=myuser1 \
    -e MYSQL_PASSWORD=mypassword1 \
    -e MYSQL_ROOT_PASSWORD=secret -d mysql/mysql-server
docker run --name mybox2n --hostname hmybox2n \
    --net my_net \
	-e MYSQL_DATABASE=db2 \
	-e MYSQL_USER=myuser2 \
	-e MYSQL_PASSWORD=mypassword2 \
	-e MYSQL_ROOT_PASSWORD=secret -d mysql/mysql-server

docker ps 
