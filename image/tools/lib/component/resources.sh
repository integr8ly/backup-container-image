function get_namespace {
    # We assume that every middleware namespace has at least one pod
    # and we retrieve the current namespace by looking at the first
    # pod we encounter
    echo "`oc get pods -o jsonpath='{.items[0].metadata.namespace}'`"
}
function check_resource {
    local type=$1
    local ns=$2
    local result=$(oc get $type -n $ns 2>&1 | wc -l)
    # 1 line in the result means that only an error message
    # was returned but no actual results. That would be at
    # least two lines: one for the header and one for each
    # resource found
    if [[ "$result"  == "1" ]]; then
        echo "==> No $type in $ns to back up"
        return 1
    else
        return 0
    fi
}

function backup_resource {
    local ts=$(date '+%H:%M:%S')
    local type=$1
    local ns=$2
    local dest=$3
    check_resource ${type} ${ns}
    if [[ $? -eq 0 ]]; then
        echo "==> backing up $type in $ns"
        oc get ${type} -n ${ns} -o yaml --export | gzip > ${dest}/intly_${type}-${ns}-${ts}.dump.gz
    fi
}

function component_dump_data {
    local dest=$1
    local ns=$(get_namespace)
    echo "==> processing namespace $ns"
    backup_resource secrets ${ns} ${dest}
    backup_resource configmaps ${ns} ${dest}
    backup_resource services ${ns} ${dest}
    backup_resource routes ${ns} ${dest}
    backup_resource deployments ${ns} ${dest}
    backup_resource namespaces ${ns} ${dest}
    backup_resource roles ${ns} ${dest}
    backup_resource rolebindings ${ns} ${dest}
    backup_resource webapps ${ns} ${dest}
}
