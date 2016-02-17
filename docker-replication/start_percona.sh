#!/bin/bash

# example of using experimental Percona image with Tokudb
echo 'always madwise [never]' > never.txt
docker run \
    --name mybox  \
    -e MYSQL_ROOT_PASSWORD=secret -d \
    -e INIT_TOKUDB=1 \
    -v $PWD/never.txt:/sys/kernel/mm/transparent_hugepage/defrag \
    -v $PWD/never.txt:/sys/kernel/mm/transparent_hugepage/enabled \
    percona/percona-server


