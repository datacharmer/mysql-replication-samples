# mysql-replication-samples
A collection of tools for deploying and testing replication topologies with MySQL and MariaDB

The files in this collection are here to help beginners who want to start using advanced features like multi-source replication and test how they work.
They are based on [MySQL Sandbox](http://mysqlsandbox.net), with the goal that they will be eventually integrated in that project.


* multi_source_mysql.sh is an example of multi source deployment, with one fan-in slave and 3 masters. It requires MySQL 5.7.7 or later
* multi_source_mariadb.sh Is the same as the above example, but using MariaDB 10.x syntax
* all_masters_mysql.sh is a variation of multi_source_mysql.sh, where, instead of having a fan-in slave, all nodes are at once master and slave of every other node.
* test_multi_source_replication.sh tests the fan-in scenario
