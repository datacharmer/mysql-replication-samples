exists_net=$(docker network ls | grep -w group1 )
if [ -n "$exists_net" ]
then
    docker network rm group1
fi
docker network create group1
docker network ls

docker run -d --name=node1 --net=group1 \
    -e MYSQL_ROOT_PASSWORD=aTestPwd \
    -e MYSQL_REPLICATION_USER=rpl_user \
    -e MYSQL_REPLICATION_PASSWORD=rpl_pass \
    mysql/mysql-gr \
    --group_replication_group_seeds='node2:6606,node3:6606' --server-id=1

docker run -d --name=node2 --net=group1 \
    -e MYSQL_ROOT_PASSWORD=aTestPwd \
    -e MYSQL_REPLICATION_USER=rpl_user \
    -e MYSQL_REPLICATION_PASSWORD=rpl_pass \
    mysql/mysql-gr \
    --group_replication_group_seeds='node1:6606,node3:6606' --server-id=2

docker run -d --name=node3 --net=group1 \
    -e MYSQL_ROOT_PASSWORD=aTestPwd \
    -e MYSQL_REPLICATION_USER=rpl_user \
    -e MYSQL_REPLICATION_PASSWORD=rpl_pass \
    mysql/mysql-gr \
    --group_replication_group_seeds='node1:6606,node2:6606' --server-id=3

