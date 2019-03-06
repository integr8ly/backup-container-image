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

if [[ "$debug" ]]; then
    set -x
fi

if [[ -z "$component" ]]; then
    (>&2 echo 'Please specify a component using "-c"')
    exit 1
fi

source "$DIR/lib/utils.sh"
source "$DIR/lib/backend/$archive_backend.sh"
if [[ "$encryption_engine" ]]; then
    source "$DIR/lib/encryption/$encryption_engine.sh"
fi
source "$DIR/lib/component/$component.sh"

DATESTAMP=$(date '+%Y/%m/%d')
DEST=/tmp/intly
ARCHIVES_DEST=$DEST/archives
mkdir -p $DEST $ARCHIVES_DEST
export HOME=$DEST

component_dump_data $DEST
echo '==> Component data dump completed'

if [[ "$encryption_engine" ]]; then
    check_encryption_enabled
    if [[ $? -eq 0 ]]; then
        encrypt_prepare ${DEST}
        encrypted_files="$(encrypt_archive $ARCHIVES_DEST)"
        echo '==> Data encryption completed'
    else
        echo "==> encryption secret not found. Skipping"
        encrypted_files="$ARCHIVES_DEST/*"
    fi
else
    encrypted_files="$ARCHIVES_DEST/*"
fi
upload_archive "${encrypted_files}" $DATESTAMP backups/$component
echo '==> Archive upload completed'

echo "[$DATESTAMP] Backup completed"

if [[ "$debug" ]]; then
    echo '==> Debug flag detected - will sleep for all eternity'
    sleep infinity
fi
