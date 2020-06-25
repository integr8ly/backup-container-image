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

# Backup every container inside a pod
function cp_container_data {
    pod_name=$1
    pod_data_src=$2
    cp_dest=$3

    # Get a list of containers inside the pod
    containers=$(oc get pods "$pod_name" -ojsonpath='{.spec.containers[*].name}' -n "${PRODUCT_NAMESPACE}")

    for container in ${containers}; do
      container_dest="$cp_dest-$container"
      timestamp_echo "backing up container $container in pod $pod_name"
      num_attempted_copy=0
      max_tries=5

      # Disable errors because some of the containers might not have the directory to back up
      set +eo pipefail

      copy_output=$(oc cp "$pod_data_src" "$container_dest" -c "$container")
      # Check if any files were rewritten to during oc cp, and copy it again if it was.
      while [[ $copy_output == *"file changed as we read it"* ]] && [ $num_attempted_copy -lt $max_tries ]
      do
         timestamp_echo "A file has been overwritten during copying, executing 'oc cp' again"
         sleep 5
         copy_output=$(oc cp "$pod_data_src" "$container_dest" -c "$container")
         ((num_attempted_copy++))
      done

      # Re-enable errors
      set -eo pipefail
    done
}

function timestamp_echo {
    echo `(date -u '+%Y-%m-%d %H:%M:%S')` '==>' $1
}