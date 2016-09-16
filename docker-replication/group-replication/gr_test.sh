
function exec_node
{
    node_num=$1
    query="$2"
    docker exec -ti node$node_num mysql -paTestPwd -ve "$query"
}

function pause
{
    how_long=$1
    for J in $(seq 1 $how_long)
    do
        printf "."
        sleep 1
    done
    echo ''
}

for N in 1 2 3; do exec_node $N "select * from performance_schema.replication_group_members\G" ; done
echo "# press enter"
read dummy
exec_node 1 'create schema if not exists test'

pause 5
for N in 1 2 3; do exec_node $N 'select @@server_id; show schemas;' ; done
for N in 1 2 3; do exec_node $N 'select @@server_id; show schemas;' ; done
pause 5
for N in 1 2 3; do exec_node $N "create table test.t$N(id int not null primary key)" ; done
pause 5
for N in 1 2 3; do exec_node $N "insert into test.t$N values ($N)" ; done
pause 5
for N in 1 2 3; do exec_node $N 'select @@server_id; show tables from test;' ; done

