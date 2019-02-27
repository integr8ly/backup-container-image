#!/usr/bin/env bash

function dump_pod_data {
    workspace_pod_name=$1
    dump_dest=$2
    workspace_id=$(echo ${workspace_pod_name} | awk -F"." '{ print $1}')
    cp_pod_data "codeready/${workspace_pod_name}:/projects" "${dump_dest}/${workspace_id}"
}

function component_dump_data {
    workspace_pods=$(oc get pods -n codeready | grep workspace | awk '{print $1}')

    if [ ${#workspace_pods} = 0 ]
    then
        echo "No workspaces found to backup"
    else
        archive_path="$1/archives"
        dump_dest="/tmp/codeready-data"
        mkdir -p $dump_dest
        for i in $workspace_pods; do dump_pod_data $i $dump_dest; done
        tar -zcvf "$archive_path/codeready-pv-data.tar.gz" -C $dump_dest .
        rm -rf $dump_dest
    fi
}