#!/usr/bin/env sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
component=''
archive_backend='s3'
encryption_engine='gpg'
debug=''

while getopts "c:b:e:d:" opt; do
    case "$opt" in 
    c)
        component="$OPTARG"
        ;;
    b)
        archive_backend="$OPTARG"
        ;;
    e)
        encryption_engine="$OPTARG"
        ;;
    d)
        debug="$OPTARG"
        ;;
    esac 
done

if [[ -z "$component" ]]; then
    (>&2 echo 'Please specify a component using "-c"')
    exit 1
fi

source "$DIR/lib/backend/$archive_backend.sh"
source "$DIR/lib/encryption/$encryption_engine.sh"
source "$DIR/lib/component/$component.sh"

timestamp="$(date '+%H:%M:%S')"
fname="/tmp/archive-$timestamp"

url=component_get_url
component_dump_data $url $fname.tar.gz
encrypt_archive $fname.tar.gz
upload_archive $fname.tar.gz.encrypted

echo "[$timestamp] Backup completed"

if [[ -n "$debug" ]]; then
    echo 'Debug flag detected - will sleep for all eternity'
    sleep infinity
fi