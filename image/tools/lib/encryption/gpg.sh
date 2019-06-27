function check_encryption_enabled {
    local result=$(oc get secret -n ${ENCRYPTION_SECRET_NAMESPACE} ${ENCRYPTION_SECRET_NAME} -o template --template='{{.metadata.name}}')
    if [ "$result" == "${ENCRYPTION_SECRET_NAME}" ]; then
        return 0
    else
        return 1
    fi
}

function get_public_key {
    echo -e "`oc get secret ${ENCRYPTION_SECRET_NAME} -n ${ENCRYPTION_SECRET_NAMESPACE} -o jsonpath={.data.GPG_PUBLIC_KEY} | base64 --decode`"
}

function get_trust_model {
    echo "`oc get secret ${ENCRYPTION_SECRET_NAME} -n ${ENCRYPTION_SECRET_NAMESPACE} -o jsonpath={.data.GPG_TRUST_MODEL} | base64 --decode`"
}

function get_recipient {
    echo "`oc get secret ${ENCRYPTION_SECRET_NAME} -n ${ENCRYPTION_SECRET_NAMESPACE} -o jsonpath={.data.GPG_RECIPIENT} | base64 --decode`"
}

function encrypt_prepare {
    dest=$1/gpg
    mkdir -p $dest
    key_path=$dest/gpg_public_key
    local key=$(get_public_key)
    echo -e "${key}" > ${key_path}
    gpg --import ${key_path}
    gpg --list-keys
}

function encrypt_archive {
    dest=$1

    local recipient=$(get_recipient)
    local trust=$(get_trust_model)

    for fname in ${dest}/*; do
        gpg --no-tty --batch --yes --encrypt --recipient "$recipient" --trust-model ${trust} ${fname}
        rc=$?
        if [[ ${rc} -ne 0 ]]; then
            echo "==> Encrypt $fname: FAILED"
            exit 1
        fi
    done

    echo "$dest/*.gpg"
}
