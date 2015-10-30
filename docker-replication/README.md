## Experiments with MySQL and Docker

These examples implement MySQL replication with Docker. Unlike most of the scripts in other directories of this repository, they don't use MySQL-Sandbox, but [Docker](https://www.docker.com/).

### A simple master-slave deployment

* *simple/mysql-2node-install.sh* Deploys two MySQL nodes, without dedicated storage
* *simple/set-2node-replication.sh* (invoked by mysql-2node-install.sh) Sets replication between two nodes
* *simple/remove-2node.sh* Removes the two nodes
* *simple/my-master.cnf* options file for master node
* *simple/my-slave.cnf* options file for slave node

### A multi-node deployment 

Requires Docker 1.7+.

Installs N nodes of MySQL, with dedicated storage and customized options file for each one.

* *deploy-nodes.sh* is the main command. Invoke with ./deploy-nodes.sh [NUM_NODES]
* *common.sh* contains common routines
* *my-template.cnf* is the basis for the MySQL server templates
* *set-replication.sh* (invoked by deploy-nodes.sh) 
* *remove-nodes.sh* removes the nodes that were deployed. Invoke with ./remove-nodes.sh [NUM_NODES]
