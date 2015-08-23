#!/bin/bash

function check_client
{
    func=$1
    client=$2
    if [  -z "$client" ]
    then
        echo "# function $func : client_path not set"
        exit 1
    fi
    if [ ! -x $client ]
    then
        echo "# function $func: client $client not found or not executable"
        exit 1
    fi
}

function get_port
{
    client_path=$1
    check_client get_port $client_path
    $client_path -BN -e 'select @@port'
}

function get_master_file_and_pos
{
    client_path=$1
    check_client get_master_file_and_pos $client_path
    MASTER_STATUS=$($client_path -e 'show master status\G')
    master_file=$(echo "$MASTER_STATUS" | grep File: | awk '{print $2}')
    master_pos=$(echo "$MASTER_STATUS" | grep Position: | awk '{print $2}')
    echo "$master_file $master_pos"
}

function get_change_master_file_and_pos
{
    client_path=$1
    check_client get_change_master_file_and_pos $client_path
    
    file_and_pos=$(get_master_file_and_pos $client_path)
    file_and_pos=$(get_master_file_and_pos $HUB/use)
    file=$(echo "$file_and_pos" | awk '{print $1}')
    pos=$(echo "$file_and_pos" | awk '{print $2}')
    echo "MASTER_LOG_FILE='$file', MASTER_LOG_POS=$pos"
}
