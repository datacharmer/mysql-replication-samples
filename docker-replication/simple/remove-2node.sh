#!/bin/bash
set -x
docker stop mysql-master
docker rm mysql-master
docker stop mysql-slave
docker rm mysql-slave
