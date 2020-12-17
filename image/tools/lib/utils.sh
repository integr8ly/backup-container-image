#!/usr/bin/env bash

function cp_pod_data {
    pod_data_src=$1
    cp_dest=$2

    num_attempted_copy=0
    max_tries=3

    oc cp $pod_data_src $cp_dest
    ret=$?

    while [[ $ret != 0 && $num_attempted_copy -lt $max_tries ]]
    do
       timestamp_echo "'oc cp' failed with exit code ${ret}, will retry in 5 seconds, attempt ${num_attempted_copy} of ${max_tries}"
       sleep 5
       oc cp $pod_data_src $cp_dest
       ret=$?
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
      max_tries=3

      # Disable errors because some of the containers might not have the directory to back up
      set +eo pipefail

      oc cp "$pod_data_src" "$container_dest" -c "$container"
      ret=$?
      # Check if any files were rewritten to during oc cp, and copy it again if it was.
      while [[ $ret != 0 && $num_attempted_copy -lt $max_tries ]]
      do
         timestamp_echo "'oc cp' failed with exit code ${ret}, will retry in 5 seconds, attempt ${num_attempted_copy} of ${max_tries}"
         sleep 5
         oc cp "$pod_data_src" "$container_dest" -c "$container"
         ret=$?
         ((num_attempted_copy++))
      done

      # Re-enable errors
      set -eo pipefail
    done
}

function timestamp_echo {
    echo `(date -u '+%Y-%m-%d %H:%M:%S')` '==>' $1
}
