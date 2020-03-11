#!/usr/bin/env bash

# Brokered pods have a storage PV attached. They are labelled with role=broker
function get_broker_pods {
    echo "`oc get pods --selector='role=broker' -n ${PRODUCT_NAMESPACE} -o jsonpath='{.items[*].metadata.name}'`"
}

function dump_pod_data {
    local pod=$1
    local dest=$2
    local data_dir=/var/run/artemis

    # Create a backup directory for every pod with the same name
    # as the pod
    cp_pod_data "${PRODUCT_NAMESPACE}/${pod}:${data_dir}" "${dest}/${pod}"
}
function component_dump_data {
    if [[ -z "${PRODUCT_NAMESPACE:-}" ]]; then
        PRODUCT_NAMESPACE="${PRODUCT_NAMESPACE_PREFIX}enmasse"
    fi
    local archive_path="$1/archives"
    local dump_dest="/tmp/enmasse-data"
    local pods=$(get_broker_pods 2>&1)

    if [[ "$pods" == *"Error from server"* ]]; then
        echo ${pods}
        exit 1
    fi

    if [ "${#pods}" -eq "0" ]; then
        timestamp_echo "No broker pods found to backup"
        exit 0
    fi

    mkdir -p ${dump_dest}

    for pod in ${pods}; do
        timestamp_echo "Processing enmasse broker pod ${pod}"
        dump_pod_data ${pod} ${dump_dest}
    done

    ls ${dump_dest}/*
    if [ "$?" -eq "0" ]; then
        local ts=$(date '+%H_%M_%S')
        tar -zcvf "$archive_path/enmasse-pv-data-${ts}.tar.gz" -C $dump_dest .
        rm -rf $dump_dest
    else
        timestamp_echo "No enmasse broker data to backup"
    fi
}
