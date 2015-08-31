#!/bin/bash
# Copyright 2015 Giuseppe Maxia
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

#
# Simple example of how to set semi-synchronous replication

VERSION=$1
FLAVOR=$2
THREADS=$3
initialdir=$(dirname $0)
cd $initialdir
initialdir=$PWD

if [ -z "$FLAVOR" ]
then
    echo "VERSION, FLAVOR, and THREADS required"
    echo "Where VERSION is an indentifier like 5.7.7 or ma10.0.20 "
    echo "      FLAVOR is either mysql or mariadb"
    echo "      and THREADS is the number of parallel appliers to start (default 10)"
   exit 1 
fi
[ -z "$THREADS" ] && THREADS=10
if [ "$FLAVOR" == "mysql" ]
then
    PARALLEL_VAR=slave_parallel_workers
elif [ "$FLAVOR" == "mariadb" ]
then
    PARALLEL_VAR=slave_parallel_threads
else
    echo "unknown flavor <$FLAVOR>"
    exit 1
fi


[ -z "$SANDBOX_BINARY" ] && SANDBOX_BINARY=$HOME/opt/mysql

if [ ! -d $SANDBOX_BINARY/$VERSION ]
then
    echo "$SANDBOX_BINARY/$VERSION does not exist"
    echo "Set the variable SANDBOX_BINARY to indicate where to find the expanded tarballs for MySQL::Sandbox"
    exit 1
fi

DASHED_VERSION=$(echo $VERSION| tr '.' '_')
sandbox_name=$HOME/sandboxes/rsandbox_$DASHED_VERSION
make_replication_sandbox $VERSION
cp -v checksum.sh insert*.sh multi_*.sh $sandbox_name
cd $sandbox_name
if [ "$FLAVOR" == "mysql" ]
then
    ./enable_gtid    
fi

for SLAVE in s1 s2
do
    ./$SLAVE -e "stop slave"
    ./$SLAVE -e "set global $PARALLEL_VAR=$THREADS"
    ./$SLAVE -e "start slave"
    ./$SLAVE -e "show global variables like '$PARALLEL_VAR'"
    ./$SLAVE -e "show processlist"
done

