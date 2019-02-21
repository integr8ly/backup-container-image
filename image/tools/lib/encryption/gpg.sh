function encrypt_prepare {
    dest=$1/gpg
    mkdir -p $dest
    key_path=$dest/gpg_public_key
    echo -e "$GPG_PUBLIC_KEY" > $key_path

    gpg --import $key_path
    gpg --list-keys
}

function encrypt_archive {
    dest=$1

    for fname in $dest/*; do
        gpg --no-tty --batch --yes --encrypt --recipient "$GPG_RECIPIENT" --trust-model $GPG_TRUST_MODEL $fname
        rc=$?
        if [ $rc -ne 0 ]; then
            echo "==> Encrypt $fname: FAILED"
            exit 1
        fi
    done

    echo "$dest/*.gpg"
}