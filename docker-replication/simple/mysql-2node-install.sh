docker run --name mysql-master  -v $PWD/my-master.cnf:/etc/my.cnf -e MYSQL_ROOT_PASSWORD=secret -d mysql
if [ "$?" != "0" ] ; then exit 1; fi
docker run --name mysql-slave  -v $PWD/my-slave.cnf:/etc/my.cnf -e MYSQL_ROOT_PASSWORD=secret -d mysql
if [ "$?" != "0" ] ; then exit 1; fi
echo "# Waiting for nodes to be ready - Sleeping 30 seconds"
sleep 30
./set-2node-replication.sh

