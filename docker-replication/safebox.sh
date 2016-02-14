#!/bin/bash
NAME=$1
if [ -n "$NAME" ] 
then
    shift
else
    NAME=mybox
fi

OS=$(uname -s)
if [ "$OS" == "Linux" ]
then
    CHECKSUM=sh256sum
elif [ "$OS" == "Darwin" ]
then
    CHECKSUM=shasum5.18
else
    echo "Unrecognized operating system '$OS'"
    exit 1
fi

# Generate a random password
RANDOM_PASSWORD=$(echo $RANDOM | $CHECKSUM | cut -c 1-10 )

# Save the random password to a file
SECRETPASSWORD=$PWD/secretpassword.txt
HOME_MY_SAFE=$PWD/home_my_safe.cnf
echo $RANDOM_PASSWORD > $SECRETPASSWORD

# Create the .my.cnf file
echo '[client]' > $HOME_MY_SAFE
echo 'user=root' >> $HOME_MY_SAFE
echo "password=$RANDOM_PASSWORD" >> $HOME_MY_SAFE

[ -z "$IMAGE" ] && IMAGE=mysql/mysql-server
set -x
docker run --name $NAME \
    -v $SECRETPASSWORD:/root/secretpassword.txt \
    -v $HOME_MY_SAFE:/root/home_my.cnf \
    -e MYSQL_ROOT_PASSWORD=/root/secretpassword.txt -d $IMAGE $@

