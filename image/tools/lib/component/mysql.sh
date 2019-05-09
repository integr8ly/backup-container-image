function check_mysql_backup_enabled {
    local result=$(oc get secret -n ${COMPONENT_SECRET_NAMESPACE} ${COMPONENT_SECRET_NAME} -o template --template='{{.metadata.name}}')
    if [[ "$result" == "${COMPONENT_SECRET_NAME}" ]]; then
        return 0
    else
        return 1
    fi
}

function get_mysql_host {
    echo "`oc get secret ${COMPONENT_SECRET_NAME} -n ${COMPONENT_SECRET_NAMESPACE} -o jsonpath={.data.MYSQL_HOST} | base64 --decode`"
}

function get_mysql_user {
    echo "`oc get secret ${COMPONENT_SECRET_NAME} -n ${COMPONENT_SECRET_NAMESPACE} -o jsonpath={.data.MYSQL_USER} | base64 --decode`"
}

function get_mysql_password {
    echo "`oc get secret ${COMPONENT_SECRET_NAME} -n ${COMPONENT_SECRET_NAMESPACE} -o jsonpath={.data.MYSQL_PASSWORD} | base64 --decode`"
}

function component_dump_data {
    local dest=$1

    check_mysql_backup_enabled
    if [[ $? -eq 1 ]]; then
        echo "==> mysql secret not found in default namespace. Skipping"
        exit 0
    fi

    local MYSQL_HOST=$(get_mysql_host)
    local MYSQL_USER=$(get_mysql_user)
    local MYSQL_PASSWORD=$(get_mysql_password)

    databases=$(mysql -h${MYSQL_HOST} -u${MYSQL_USER}  -p${MYSQL_PASSWORD} -e 'SHOW DATABASES' | tail -n+2 | grep -v information_schema)

    for database in ${databases}; do
        local ts=$(date '+%H_%M_%S')
        mysqldump --single-transaction -h${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -R ${database} | gzip > ${dest}/archives/${database}-${ts}.dump.gz
        local rc=$?
        if [ "${rc}" -ne "0" ]; then
            echo "==> Dump $database: FAILED"
            exit 1
        fi
    done
}
