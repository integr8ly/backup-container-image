function check_backup_enabled {
    local result=$(oc get secret -n ${BACKEND_SECRET_NAMESPACE} ${BACKEND_SECRET_NAME} -o template --template='{{.metadata.name}}')
    if [[ "$result" == "${BACKEND_SECRET_NAME}" ]]; then
        return 0
    else
        return 1
    fi
}

function get_s3_bucket_name {
    echo "`oc get secret -n ${BACKEND_SECRET_NAMESPACE} ${BACKEND_SECRET_NAME} -o jsonpath='{.data.AWS_S3_BUCKET_NAME}' | base64 --decode`"
}

function get_s3_key_id {
    echo "`oc get secret -n ${BACKEND_SECRET_NAMESPACE} ${BACKEND_SECRET_NAME} -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 --decode`"
}

function get_s3_access_key {
    echo "`oc get secret -n ${BACKEND_SECRET_NAMESPACE} ${BACKEND_SECRET_NAME} -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 --decode`"
}

function upload_archive {
    check_backup_enabled
    if [ "$?" -eq "1" ]; then
        echo "==> backend secret not found. Skipping"
        return 0
    fi

    local file_list=$1
    local datestamp=$2
    local bucket_folder=$3

    local AWS_S3_BUCKET_NAME=$(get_s3_bucket_name)
    local AWS_ACCESS_KEY_ID="$(get_s3_key_id)"
    local AWS_SECRET_ACCESS_KEY="$(get_s3_access_key)"

    for fname in ${file_list}; do
        ls ${fname}

        # ls will exit with 1 if the glob does not expand to any files
        if [ "$?" -eq "0" ]; then
            s3cmd put --access_key ${AWS_ACCESS_KEY_ID} --secret_key ${AWS_SECRET_ACCESS_KEY} --progress ${fname} "s3://$AWS_S3_BUCKET_NAME/$bucket_folder/$datestamp/$(basename ${fname})"
            rc=$?
            if [ "${rc}" -ne "0" ]; then
                echo "==> Upload $fname: FAILED"
                exit 1
            fi
            echo "==> Upload ${fname} completed"
        else
            echo "==> No backups in ${fname} to upload"
        fi
    done
}
