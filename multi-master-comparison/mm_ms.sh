#!/bin/bash
MYSQL_VERSION=$1
[ -z "$MYSQL_VERSION" ] && MYSQL_VERSION=5.7.16

make_multiple_sandbox --gtid --group_directory=MS $MYSQL_VERSION

if [ "$?" != "0" ] ; then exit 1 ; fi
multi_sb=$HOME/sandboxes/MS

$multi_sb/use_all 'reset master'

for N in 1 2 3
do
    user_cmd=''
    for node in 1 2 3
    do
        if [ "$node" != "$N" ]
        then
            master_port=$($multi_sb/n$node -BN -e 'select @@port')
            user_cmd="$user_cmd CHANGE MASTER TO MASTER_USER='rsandbox', "
            user_cmd="$user_cmd MASTER_PASSWORD='rsandbox', master_host='127.0.0.1', "
            user_cmd="$user_cmd master_port=$master_port FOR CHANNEL 'node$node';"
            user_cmd="$user_cmd START SLAVE FOR CHANNEL 'node$node';"
        fi
    done
    $multi_sb/node$N/use -v -u root -e "$user_cmd"
done


