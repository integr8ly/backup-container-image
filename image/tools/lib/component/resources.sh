TS=$(date '+%H_%M_%S')

function get_middleware_namespaces {
    echo "`oc get namespaces --selector='integreatly-middleware-service=true' -o jsonpath='{.items[*].metadata.name}'`"
}

# Checks if a given resource is present in a given namespace
function check_resource {
    local type=$1
    local ns=$2
    local result=$(oc get $type -n $ns 2>&1 | wc -l)
    # 1 line in the result means that only an error message
    # was returned but no actual results. That would be at
    # least two lines: one for the header and one for each
    # resource found
    if [ "$result"  -eq "1" ]; then
        echo "==> No $type in $ns to back up"
        return 1
    else
        return 0
    fi
}

# Backs up a namespaced resource
function backup_resource {
    local type=$1
    local ns=$2
    local dest=$3
    local loop=${4-default}

    # Disable extended error checks. The check_resource function relies on a non-zero
    # return code, which is interpreted as a failed command and causes the script to be
    # terminated with the '-e' option
    set +eo pipefail
    check_resource ${type} ${ns}
    if [ "$?" -eq "0" ]; then
        echo "==> backing up $type in $ns"
        if [ "$loop" == "y" ]; then
            echo '---' > /tmp/${type}.yaml
            for obj in $(oc get ${type} -n ${ns} | tr -s ' ' | cut -d ' ' -f 1 |  tail -n +2); do
                echo '-' >> /tmp/${type}.yaml
                echo "$(oc get ${type}/${obj} -n enmasse -o yaml --export | sed 's/^/  /')" >> /tmp/${type}.yaml
                cat /tmp/${type}.yaml | gzip > ${dest}/archives/${ns}-${type}.yaml.gz
                rm -f /tmp/${type}.yaml
            done
        else
            oc get ${type} -n ${ns} -o yaml --export | gzip > ${dest}/archives/${ns}-${type}.yaml.gz
        fi
    fi
    # Re-enable extended error checks
    set -eo pipefail
}

# Backs up a namespace
function backup_namespace {
    local ns=$1
    local dest=$2
    echo "==> backing up namespace $ns"
    oc get namespace ${ns} -o yaml --export | gzip > ${dest}/archives/${ns}-namespace.yaml.gz
}

# Backs up all service accounts in a namespace but excludes the
# system ones
function backup_service_accounts {
    local ns=$1
    local dest=$2
    echo "==> backing up service accounts in $ns"
    oc get serviceaccounts -n ${ns} --field-selector='metadata.name!=builder,metadata.name!=deployer,metadata.name!=default' -o yaml --export | gzip > ${dest}/archives/${ns}-sa.yaml.gz
}

# Backs up all rolebindings in a namespace but excludes the system ones
function backup_role_bindings {
    local ns=$1
    local dest=$2
    echo "==> backing up role bindings in $ns"
    oc get rolebindings -n ${ns} --field-selector='metadata.name!=system:deployers,metadata.name!=system:image-builders,metadata.name!=system:image-pullers' -o yaml --export | gzip > ${dest}/archives/${ns}-rb.yaml.gz
}

# Backs up a cluster level resource
function backup_cluster_resource {
    local type=$1
    local dest=$2
    echo "==> backing up cluster resource $type"
    oc get ${type} -o yaml --export | gzip > ${dest}/archives/${type}.yaml.gz
}

# Archive all files
function archive_files {
    dest=$1
    cd ${dest}/archives
    tar --exclude='*.tar.gz' --force-local -czf resources_${TS}.tar.gz .
    rm -f *.yaml.gz
}

# Entry point
function component_dump_data {
    local dest=$1
    local namespaces=$(get_middleware_namespaces)

    for ns in ${namespaces} "default"; do
        echo "==> processing namespace $ns"
        backup_resource secrets ${ns} ${dest}
        backup_resource configmaps ${ns} ${dest}
        backup_resource services ${ns} ${dest}
        backup_resource routes ${ns} ${dest}
        backup_resource deployments ${ns} ${dest}
        backup_resource roles ${ns} ${dest}
        backup_resource webapps ${ns} ${dest}
        backup_resource keycloaks ${ns} ${dest}
        backup_resource keycloakrealms ${ns} ${dest}
        backup_resource alertmanagers ${ns} ${dest}
        backup_resource applicationmonitorings ${ns} ${dest}
        backup_resource giteas ${ns} ${dest}
        backup_resource grafanadashboards ${ns} ${dest}
        backup_resource grafanas ${ns} ${dest}
        backup_resource prometheuses ${ns} ${dest}
        backup_resource servicemonitors ${ns} ${dest}
        backup_resource syndesises ${ns} ${dest}
        backup_resource addressplans ${ns} ${dest}
        backup_resource addressspaceplans ${ns} ${dest}
        backup_resource brokeredinfraconfigs ${ns} ${dest}
        backup_resource standardinfraconfigs ${ns} ${dest}
        backup_resource addresses ${ns} ${dest}
        backup_resource addressspaces ${ns} ${dest}
        backup_resource addressspaceschemas ${ns} ${dest}
        backup_resource messagingusers ${ns} ${dest} 'y'
        backup_resource limitranges ${ns} ${dest}
        backup_resource persistentvolumeclaims ${ns} ${dest}
        backup_resource statefulsets ${ns} ${dest}
        backup_resource buildconfigs ${ns} ${dest}
        backup_resource builds ${ns} ${dest}
        backup_resource imagestreamtag ${ns} ${dest}
        backup_resource prometheusrules ${ns} ${dest}
        backup_resource deploymentconfigs ${ns} ${dest}

        backup_service_accounts ${ns} ${dest}
        backup_role_bindings ${ns} ${dest}
        backup_namespace ${ns} ${dest}
    done

    echo "==> processing cluster resources"

    # These resources are not located in a particular namespace
    backup_cluster_resource oauthclients ${dest}
    backup_cluster_resource clusterservicebrokers ${dest}
    backup_cluster_resource clusterroles ${dest}
    backup_cluster_resource clusterrolebindings ${dest}
    backup_cluster_resource cronjobs ${dest}
    backup_cluster_resource customresourcedefinitions ${dest}

    # Create a single archive including all files
    archive_files ${dest}
}
