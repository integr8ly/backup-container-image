#!/usr/bin/env bash

function cp_pod_data {
    pod_data_src=$1
    cp_dest=$2

    num_attempted_copy=0
    max_tries=5
    copy_output=$(oc cp $pod_data_src $cp_dest)
    # Check if any files were rewritten to during oc cp, and copy it again if it was.
    while [[ $copy_output == *"file changed as we read it"* ]] && [ $num_attempted_copy -lt $max_tries ]
    do
       timestamp_echo "A file has been overwritten during copying, executing 'oc cp' again"
       sleep 5
       copy_output=$(oc cp $pod_data_src $cp_dest)
       ((num_attempted_copy++))
    done
}

function timestamp_echo {
    echo `(date -u '+%Y-%m-%d %H:%M:%S')` '==>' $1
}