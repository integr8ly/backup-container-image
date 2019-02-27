#!/usr/bin/env bash

function get_data_src {
    codeready_ns="codeready"
    postgres_pod_name="$(oc get pods -n $codeready_ns | grep postgres | awk '{print $1}')"
    data_path="/var/lib/pgsql/data"

    if [ ${#postgres_pod_name} = 0 ] || [ $postgres_pod_name = "No resources found" ]
    then
        echo "NO-POD"
    else
        echo "${codeready_ns}/${postgres_pod_name}:${data_path}"
    fi
}

function component_dump_data {
    data_src=$(get_data_src)
    archive_path=$1
    dump_dest="/tmp/codeready-data"

    if [ $data_src = "NO-POD" ]
    then
        echo "codeready pod not available"
    else
        oc cp $data_src $dump_dest
        tar -zcvf "$archive_path/codeready-pv-data.tar.gz" -C $dump_dest .
        rm -rf $dump_dest
    fi
}