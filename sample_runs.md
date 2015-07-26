## No arguments: shows syntax
    $ ./multi_source.sh
    VERSION, FLAVOR, and TOPOLOGY  required
    Where VERSION is an indentifier like 5.7.7 or ma10.0.20
          FLAVOR is either mysql or mariadb
          TOPOLOGY is either FAN-IN or ALL-MASTERS


## DRY-RUN installation with MySQL 5.7 (fan-in)
  
    $ DRY_RUN=1 ./multi_source.sh 5.7.8 mysql FAN-IN
    # make_multiple_sandbox --how_many_nodes=4 5.7.8
    cd $HOMEsandboxes/multi_msb_5_7_8
    # Setting topology FAN-IN
    # node4
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    # node4
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    # node4
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node3'

## Real installation with MySQL 5.7 (fan-in)

    $ ./multi_source.sh 5.7.8 mysql FAN-IN
    installing node 1
    installing node 2
    installing node 3
    installing node 4
    group directory installed in $HOME/sandboxes/multi_msb_5_7_8
    # option 'master-info-repository=table' added to node1 configuration file
    # option 'relay-log-info-repository=table' added to node1 configuration file
    # option 'gtid_mode=ON' added to node1 configuration file
    # option 'log-slave-updates' added to node1 configuration file
    # option 'enforce-gtid-consistency' added to node1 configuration file
    # option 'master-info-repository=table' added to node2 configuration file
    # option 'relay-log-info-repository=table' added to node2 configuration file
    # option 'gtid_mode=ON' added to node2 configuration file
    # option 'log-slave-updates' added to node2 configuration file
    # option 'enforce-gtid-consistency' added to node2 configuration file
    # option 'master-info-repository=table' added to node3 configuration file
    # option 'relay-log-info-repository=table' added to node3 configuration file
    # option 'gtid_mode=ON' added to node3 configuration file
    # option 'log-slave-updates' added to node3 configuration file
    # option 'enforce-gtid-consistency' added to node3 configuration file
    # option 'master-info-repository=table' added to node4 configuration file
    # option 'relay-log-info-repository=table' added to node4 configuration file
    # option 'gtid_mode=ON' added to node4 configuration file
    # option 'log-slave-updates' added to node4 configuration file
    # option 'enforce-gtid-consistency' added to node4 configuration file
    # server: 1:
    # server: 2:
    # server: 3:
    # server: 4:
    # executing "stop" on $HOMEsandboxes/multi_msb_5_7_8
    executing "stop" on node 1
    executing "stop" on node 2
    executing "stop" on node 3
    executing "stop" on node 4
    # executing "start" on $HOMEsandboxes/multi_msb_5_7_8
    executing "start" on node 1
    . sandbox server started
    executing "start" on node 2
    . sandbox server started
    executing "start" on node 3
    . sandbox server started
    executing "start" on node 4
    . sandbox server started
    # Setting topology FAN-IN
    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8379, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    --------------
    
    --------------
    START SLAVE for channel  'node1'
    --------------
    
    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8380, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    --------------
    
    --------------
    START SLAVE for channel  'node2'
    --------------
    
    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8381, master_user='rsandbox', master_password='rsandbox' for channel 'node3'
    --------------
    
    --------------
    START SLAVE for channel  'node3'
    --------------

## Testing Fan-In installation

    $PWD/test_multi_source_replication.sh -> $HOME/sandboxes/multi_msb_5_7_8/test_multi_source_replication.sh

    $ ~/sandboxes/multi_msb_5_7_8/test_multi_source_replication.sh
    # Tables in server 101
    test_node1
    # Tables in server 102
    test_node2
    # Tables in server 103
    test_node3
    # Tables in fan-in slave
    test_node1
    test_node2
    test_node3
    +-----------+--------+--------------+
    | server_id | @@port | node         |
    +-----------+--------+--------------+
    |       104 |   8382 | fan-in slave |
    +-----------+--------+--------------+
    +----+----------+--------+-------+---------------------+
    | id | serverid | dbport | node  | ts                  |
    +----+----------+--------+-------+---------------------+
    |  1 |      101 |   8379 | node1 | 2015-07-26 20:33:15 |
    +----+----------+--------+-------+---------------------+
    +----+----------+--------+-------+---------------------+
    | id | serverid | dbport | node  | ts                  |
    +----+----------+--------+-------+---------------------+
    |  1 |      102 |   8380 | node2 | 2015-07-26 20:33:15 |
    +----+----------+--------+-------+---------------------+
    +----+----------+--------+-------+---------------------+
    | id | serverid | dbport | node  | ts                  |
    +----+----------+--------+-------+---------------------+
    |  1 |      103 |   8381 | node3 | 2015-07-26 20:33:16 |
    +----+----------+--------+-------+---------------------+


## DRY-RUN installation with MariaDB 10.0.20 (fan-in)

    $ DRY_RUN=1 ./multi_source.sh ma10.0.20 mariadb FAN-IN
    # make_multiple_sandbox --how_many_nodes=4 ma10.0.20
    cd /Users/gmax/sandboxes/multi_msb_ma10_0_20
    # Setting topology FAN-IN
    # node4
    CHANGE MASTER 'node1' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    # node4
    CHANGE MASTER 'node2' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    # node4
    CHANGE MASTER 'node3' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'


## DRY-RUN installation with MySQL 5.7 (all-masters)

    $ DRY_RUN=1 ./multi_source.sh 5.7.8 mysql ALL-MASTERS
    # make_multiple_sandbox --how_many_nodes=4 5.7.8
    cd /Users/gmax/sandboxes/multi_msb_5_7_8
    # Setting topology ALL-MASTERS
    # node node1
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    START SLAVE for channel  'node2'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node3'
    START SLAVE for channel  'node3'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node4'
    START SLAVE for channel  'node4'
    # node node2
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    START SLAVE for channel  'node1'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node3'
    START SLAVE for channel  'node3'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node4'
    START SLAVE for channel  'node4'
    # node node3
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    START SLAVE for channel  'node1'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    START SLAVE for channel  'node2'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node4'
    START SLAVE for channel  'node4'
    # node node4
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    START SLAVE for channel  'node1'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    START SLAVE for channel  'node2'
    CHANGE MASTER TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox' for channel 'node3'
    START SLAVE for channel  'node3'


## DRY-RUN installation with MariaDB 10.1 (all-masters)

    $ DRY_RUN=1 ./multi_source.sh ma10.1.5 mariadb ALL-MASTERS
    # make_multiple_sandbox --how_many_nodes=4 ma10.1.5
    cd /Users/gmax/sandboxes/multi_msb_ma10_1_5
    # Setting topology ALL-MASTERS
    # node node1
    CHANGE MASTER 'node2' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node2'
    CHANGE MASTER 'node3' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node3'
    CHANGE MASTER 'node4' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node4'
    # node node2
    CHANGE MASTER 'node1' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node1'
    CHANGE MASTER 'node3' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node3'
    CHANGE MASTER 'node4' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node4'
    # node node3
    CHANGE MASTER 'node1' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node1'
    CHANGE MASTER 'node2' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node2'
    CHANGE MASTER 'node4' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node4'
    # node node4
    CHANGE MASTER 'node1' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node1'
    CHANGE MASTER 'node2' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node2'
    CHANGE MASTER 'node3' TO master_host='127.0.0.1', master_port=$MASTER_PORT, master_user='rsandbox', master_password='rsandbox'
    START SLAVE  'node3'


## Real installation with MySQL 5.7 (all-masters)

    $ ./multi_source.sh 5.7.8 mysql ALL-MASTERS
    installing node 1
    installing node 2
    installing node 3
    installing node 4
    group directory installed in $HOME/sandboxes/multi_msb_5_7_8
    # option 'master-info-repository=table' added to node1 configuration file
    # option 'relay-log-info-repository=table' added to node1 configuration file
    # option 'gtid_mode=ON' added to node1 configuration file
    # option 'enforce-gtid-consistency' added to node1 configuration file
    # option 'master-info-repository=table' added to node2 configuration file
    # option 'relay-log-info-repository=table' added to node2 configuration file
    # option 'gtid_mode=ON' added to node2 configuration file
    # option 'enforce-gtid-consistency' added to node2 configuration file
    # option 'master-info-repository=table' added to node3 configuration file
    # option 'relay-log-info-repository=table' added to node3 configuration file
    # option 'gtid_mode=ON' added to node3 configuration file
    # option 'enforce-gtid-consistency' added to node3 configuration file
    # option 'master-info-repository=table' added to node4 configuration file
    # option 'relay-log-info-repository=table' added to node4 configuration file
    # option 'gtid_mode=ON' added to node4 configuration file
    # option 'enforce-gtid-consistency' added to node4 configuration file
    # server: 1:
    # server: 2:
    # server: 3:
    # server: 4:
    # executing "stop" on /home/gmax/sandboxes/multi_msb_5_7_8
    executing "stop" on node 1
    executing "stop" on node 2
    executing "stop" on node 3
    executing "stop" on node 4
    # executing "start" on /home/gmax/sandboxes/multi_msb_5_7_8
    executing "start" on node 1
    . sandbox server started
    executing "start" on node 2
    . sandbox server started
    executing "start" on node 3
    . sandbox server started
    executing "start" on node 4
    . sandbox server started
    # Setting topology ALL-MASTERS
    # node node1
    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8380, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    --------------

    --------------
    START SLAVE for channel  'node2'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8381, master_user='rsandbox', master_password='rsandbox' for channel 'node3'
    --------------

    --------------
    START SLAVE for channel  'node3'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8382, master_user='rsandbox', master_password='rsandbox' for channel 'node4'
    --------------

    --------------
    START SLAVE for channel  'node4'
    --------------

    # node node2
    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8379, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    --------------

    --------------
    START SLAVE for channel  'node1'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8381, master_user='rsandbox', master_password='rsandbox' for channel 'node3'
    --------------

    --------------
    START SLAVE for channel  'node3'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8382, master_user='rsandbox', master_password='rsandbox' for channel 'node4'
    --------------

    --------------
    START SLAVE for channel  'node4'
    --------------

    # node node3
    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8379, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    --------------

    --------------
    START SLAVE for channel  'node1'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8380, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    --------------

    --------------
    START SLAVE for channel  'node2'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8382, master_user='rsandbox', master_password='rsandbox' for channel 'node4'
    --------------

    --------------
    START SLAVE for channel  'node4'
    --------------

    # node node4
    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8379, master_user='rsandbox', master_password='rsandbox' for channel 'node1'
    --------------

    --------------
    START SLAVE for channel  'node1'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8380, master_user='rsandbox', master_password='rsandbox' for channel 'node2'
    --------------

    --------------
    START SLAVE for channel  'node2'
    --------------

    --------------
    CHANGE MASTER TO master_host='127.0.0.1', master_port=8381, master_user='rsandbox', master_password='rsandbox' for channel 'node3'
    --------------

    --------------
    START SLAVE for channel  'node3'
    --------------

    ‘/home/gmax/workdir/git/mysql-replication-samples/test_all_masters_replication.sh’ -> ‘/home/gmax/sandboxes/multi_msb_5_7_8/test_all_masters_replication.sh’

## Testing all-masters installation

    $ ~/workdir/git/mysql-replication-samples$ ~/sandboxes/multi_msb_5_7_8/test_all_masters_replication.sh
    # NODE node1 created table test_node1
    # NODE node2 created table test_node2
    # NODE node3 created table test_node3
    # NODE node4 created table test_node4
    # Data in all nodes
    101
    1   101 8379    node1   2015-07-26 20:31:09
    1   102 8380    node2   2015-07-26 20:31:10
    1   103 8381    node3   2015-07-26 20:31:10
    1   104 8382    node4   2015-07-26 20:31:10
    102
    1   101 8379    node1   2015-07-26 20:31:09
    1   102 8380    node2   2015-07-26 20:31:10
    1   103 8381    node3   2015-07-26 20:31:10
    1   104 8382    node4   2015-07-26 20:31:10
    103
    1   101 8379    node1   2015-07-26 20:31:09
    1   102 8380    node2   2015-07-26 20:31:10
    1   103 8381    node3   2015-07-26 20:31:10
    1   104 8382    node4   2015-07-26 20:31:10
    104
    1   101 8379    node1   2015-07-26 20:31:09
    1   102 8380    node2   2015-07-26 20:31:10
    1   103 8381    node3   2015-07-26 20:31:10
    1   104 8382    node4   2015-07-26 20:31:10

