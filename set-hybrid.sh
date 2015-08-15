#!/bin/bash
# proof of concept of a hybrid topology
make_multiple_sandbox --how_many_nodes=8 5.7.8

cd $HOME/sandboxes/multi_msb_5_7_8

OPTIONS="master-info-repository=table "
OPTIONS="$OPTIONS relay-log-info-repository=table"
OPTIONS="$OPTIONS gtid_mode=ON"
OPTIONS="$OPTIONS enforce-gtid-consistency"
for N in $(seq 1 8)
do
    MYOPTIONS=$OPTIONS
    if [ "$N" == "2" -o "$N" == "3" ]
    then
        MYOPTIONS="$OPTIONS log-slave-updates"
    fi
    echo "# NODE $N"
    ./node$N/add_option "$MYOPTIONS"
done
set -x
./node1/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8381, MASTER_AUTO_POSITION=1 for channel 'hub_node1'"
./node3/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8379, MASTER_AUTO_POSITION=1 for channel 'node1_hub'"
./node3/use -e "START SLAVE FOR CHANNEL 'node1_hub'"
./node1/use -e "START SLAVE FOR CHANNEL 'hub_node1'"
# node node2 port: 8380
./node2/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8381, MASTER_AUTO_POSITION=1 for channel 'hub_node2'"
./node3/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8380, MASTER_AUTO_POSITION=1 for channel 'node2_hub'"
./node3/use -e "START SLAVE FOR CHANNEL 'node2_hub'"
./node2/use -e "START SLAVE FOR CHANNEL 'hub_node2'"
# node node4 port: 8382
./node4/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8381, MASTER_AUTO_POSITION=1 for channel 'hub_node4'"
./node3/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8382, MASTER_AUTO_POSITION=1 for channel 'node4_hub'"
./node3/use -e "START SLAVE FOR CHANNEL 'node4_hub'"
./node4/use -e "START SLAVE FOR CHANNEL 'hub_node4'"
# node node5 port: 8383
./node5/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8382, MASTER_AUTO_POSITION=1 for channel 'node4_node5'"
./node4/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8383, MASTER_AUTO_POSITION=1 for channel 'node5_node4'"
./node4/use -e "START SLAVE FOR CHANNEL 'node5_node4'"
./node5/use -e "START SLAVE FOR CHANNEL 'node4_node5'"

# node node6 port: 8384
./node6/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8382, MASTER_AUTO_POSITION=1 for channel 'node4_node6'"
./node6/use -e "START SLAVE FOR CHANNEL 'node4_node6'"

# node node7 port: 8385
./node7/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8380, MASTER_AUTO_POSITION=1 for channel 'node2_node7'"
./node2/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8385, MASTER_AUTO_POSITION=1 for channel 'node7_node2'"
./node7/use -e "START SLAVE FOR CHANNEL 'node2_node7'"
./node2/use -e "START SLAVE FOR CHANNEL 'node7_node2'"

# node node8 port: 8386
./node8/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8380, MASTER_AUTO_POSITION=1 for channel 'node2_node8'"
./node8/use -e "START SLAVE FOR CHANNEL 'node2_node8'"
set +x
for N in 1 2 3 4 5 7 
do
    ./n$N -e "create table test.t$N(id int)"
done

for N in 1 2 3 4 5 6 7 8
do
    echo "# server $N"
    ./n$N -BNe " show tables from test"
done

