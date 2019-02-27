#required env vars: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_S3_BUCKET_NAME
#optional env vars: AWS_S3_BUCKET_SUFFIX
function upload_archive {
    file_list=$1
    datestamp=$2

    if [[ "$AWS_S3_BUCKET_SUFFIX" ]]; then
        bucket_folder="$3/$AWS_S3_BUCKET_SUFFIX"
    else 
        bucket_folder=$3
    fi

    for fname in "$file_list"; do
        s3cmd put --progress $fname "s3://$AWS_S3_BUCKET_NAME/$bucket_folder/$datestamp/$(basename $fname)"
        rc=$?
        if [ $rc -ne 0 ]; then
            echo "==> Upload $name: FAILED"
            exit 1
        fi
    done
}