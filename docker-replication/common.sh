#!/bin/bash

function check_docker_version ()
{
    [ -z "$MIN_DOCKER_VERSION" ] && MIN_DOCKER_VERSION=1.7.0
    DOCKER_VERSION=$(docker --version | perl -lne 'print $1 if /(\d+\.\d+\.\d+)/')

    # To check if the current version matches the requirement, we sort numerically both
    # the required version and the current one. Then we get the top one.
    # If top version that results from sorting is the current docker version, then
    # the check passes. If not, we need to upgrade docker
    MAX_VERSION=$((echo $MIN_DOCKER_VERSION ; echo $DOCKER_VERSION ) | sort -nr| head -1 )

    echo -n "# Docker version "
    if [ "$MAX_VERSION" == "$DOCKER_VERSION" ]
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


