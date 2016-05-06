#!/bin/bash

export DOCKER_TMP=$HOME/docker/tmp
export DOCKER_DATA=$HOME/docker/mysql
export DATA_VOLUME=YES

function check_operating_system
{
    OS=$(uname -s)
    if [ "$OS" == "Linux" ]
    then
        DOCKER_TMP=/opt/docker/tmp
        DOCKER_DATA=/opt/docker/mysql
    else
        if [ -n "$SKIP_VOLUME" ]
        then
            DATA_VOLUME=no
        else
            DOCKER_TMP=$HOME/docker/tmp
            DOCKER_DATA=$HOME/docker/mysql
        fi
    fi
}

function normalized_version
{
    v=$1
    PARTS=$(echo $v | tr '.' ' ' | wc -w)
    if [[ $PARTS -lt 3 ]]
    then
        echo "# Version '$v' should have 3 components. Found only $PARTS"
        exit 1
    fi
    V1=$(echo $v | tr '.' ' ' | awk '{print $1}')
    V2=$(echo $v | tr '.' ' ' | awk '{print $2}')
    V3=$(echo $v | tr '.' ' ' | awk '{print $3}')
    printf "%02d.%02d.%02d" $V1 $V2 $V3
}

function check_docker_version ()
{
    [ -z "$MIN_DOCKER_VERSION" ] && MIN_DOCKER_VERSION=1.7.0
    DOCKER_VERSION=$(docker --version | perl -lne 'print $1 if /(\d+\.\d+\.\d+)/')
    DOCKER_NORMALIZED_VERSION=$(normalized_version $DOCKER_VERSION)
    MIN_DOCKER_NORMALIZED_VERSION=$(normalized_version $MIN_DOCKER_VERSION)

    # To check if the current version matches the requirement, we sort numerically both
    # the required version and the current one. Then we get the top one.
    # If top version that results from sorting is the current docker version, then
    # the check passes. If not, we need to upgrade docker
    MAX_VERSION=$((echo $MIN_DOCKER_NORMALIZED_VERSION ; echo $DOCKER_NORMALIZED_VERSION ) | sort -nr| head -1 )

    echo -n "# Docker version "
    if [ "$MAX_VERSION" == "$DOCKER_NORMALIZED_VERSION" ]
    then
        echo ok
    else
        echo "not ok: wanted $MIN_DOCKER_VERSION - Found $DOCKER_VERSION"
        exit 1
    fi
}

function pause
{
    delay=$1
    step=$2
    [ -z "$delay" ] && delay=30
    [ -z "$step" ] && step=5
    echo "# Sleeping $delay seconds ... "
    for N in $(seq 1 $delay)
    do
        MOD=$(($N%$step))
        if [ "$MOD" == "0" ]
        then
            echo -n $N
        else
            echo -n '.'
        fi
        MOD=$(($N%80))
        if [ "$MOD" == "0" ]
        then
            echo ''
        fi
        sleep 1
    done
    echo ''
}


