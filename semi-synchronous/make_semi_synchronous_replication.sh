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
initialdir=$PWD

if [ -z "$VERSION" ]
then
    echo "VERSION required"
    echo "Where VERSION is an indentifier like 5.7.7 or ma10.0.20 "
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

sbtool -o plugin --plugin=semisynch -s $sandbox_name

