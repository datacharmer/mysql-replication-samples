## mysql-replication-samples
A collection of tools for deploying and testing replication topologies with MySQL and MariaDB

The files in this collection are here to help beginners who want to start using advanced features like multi-source replication and test how they work.
They are based on [MySQL Sandbox](http://mysqlsandbox.net), with the goal that they will be eventually integrated in that project.

### FILES

* multi_source.sh can create bith a FAN-IN or ALL-MASTERS topology using both MySQL 5.7 or MariaDB 10
* test_multi_source_replication.sh tests the fan-in scenario
* test_all_masters_replication.sh tests the all_masters scenario

### VARIABLES

The following variables can change the installation
* SKIP_INSTALLATION (Will not install the sandbox, but assume that it is already there)
* DRYRUN or DRY_RUN (Show the replication commands, but does not execute anything)

### OBSOLETE FILES (all replaced by multi_source.sh):

* multi_source_mysql.sh is an example of multi source deployment, with one fan-in slave and 3 masters. It requires MySQL 5.7.7 or later
* multi_source_mariadb.sh Is the same as the above example, but using MariaDB 10.x syntax
* all_masters_mysql.sh is a variation of multi_source_mysql.sh, where, instead of having a fan-in slave, all nodes are at once master and slave of every other node.
* all_masters_mariadb.sh is a variation of multi_source_mmariadb.sh, where, instead of having a fan-in slave, all nodes are at once master and slave of every other node.
