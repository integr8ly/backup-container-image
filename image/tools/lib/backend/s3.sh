#required env vars: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_S3_BUCKET_NAME
function upload_archive {
    file_list=$1
    datestamp=$2
    bucket_folder=$3

    for fname in "$file_list"; do
        s3cmd put --progress $fname "s3://$AWS_S3_BUCKET_NAME/$bucket_folder/$datestamp/$(basename $fname)"
        rc=$?
        if [ $rc -ne 0 ]; then
            echo "==> Upload $name: FAILED"
            exit 1
        fi
    done
}