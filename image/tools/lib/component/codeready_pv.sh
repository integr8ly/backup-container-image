#!/usr/bin/env bash

function dump_pod_data {
    workspace_pod_name=$1
    dump_dest=$2
    workspace_id=$(echo ${workspace_pod_name} | awk -F"." '{ print $1}')
    cp_pod_data "${PRODUCT_NAMESPACE_PREFIX}codeready/${workspace_pod_name}:/projects" "${dump_dest}/${workspace_id}"
}

function component_dump_data {
    local pods="$(oc get pods -n ${PRODUCT_NAMESPACE_PREFIX}codeready | grep workspace)"
    if [ "${#pods}" -eq "0" ]; then
        echo "=>> No workspaces found to backup"
        exit 0
    fi

    local workspace_pods="$(echo $pods | awk '{print $1}')"
    local archive_path="$1/archives"
    local dump_dest="/tmp/codeready-data"
    mkdir -p $dump_dest
    for i in $workspace_pods; do dump_pod_data $i $dump_dest; done
    local ts=$(date '+%H_%M_%S')
    tar -zcvf "$archive_path/codeready-pv-data-${ts}.tar.gz" -C $dump_dest .
    rm -rf $dump_dest
}