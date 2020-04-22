TS=$(date '+%H_%M_%S')

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
        timestamp_echo "No $type in $ns to back up"
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
        timestamp_echo "backing up $type in $ns"
        if [ "$loop" == "y" ]; then
            for obj in $(oc get ${type} -n ${ns} | tr -s ' ' | cut -d ' ' -f 1 |  tail -n +2); do
                echo "$(oc get ${type}/${obj} -n ${ns} -o yaml --export)" > ${dest}/archives/${ns}-${type}.${obj}.yaml
            done
        else
            oc get ${type} -n ${ns} -o yaml --export | gzip > ${dest}/archives/${ns}-${type}.yaml.gz
        fi
    fi
    # Re-enable extended error checks
    set -eo pipefail
}

# Archive all files
function archive_files {
    dest=$1
    cd ${dest}/archives
    tar --exclude='*.tar.gz' --force-local -czf ../resources_${TS}.tar.gz .
    rm -f *.yaml.gz
    # Move the archive back to /<dest>/archives because that's where the next step expects it
    mv ../resources_${TS}.tar.gz .
}

# Entry point
function component_dump_data {
    local dest=$1
    local ns=${PRODUCT_NAMESPACE}

    timestamp_echo "Processing namespace $ns"
    backup_resource brokeredinfraconfigs ${ns} ${dest}
    backup_resource standardinfraconfigs ${ns} ${dest}
    backup_resource addressplans ${ns} ${dest}
    backup_resource addressspaceplans ${ns} ${dest}
    backup_resource authenticationservices ${ns} ${dest}
    timestamp_echo "Processing cluster resources"

    # Create a single archive including all files
    archive_files ${dest}
}
