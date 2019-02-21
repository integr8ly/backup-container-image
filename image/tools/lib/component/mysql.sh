function component_get_url {
    echo 'mysql://localhost'
}

function component_dump_data {
    auth_url=$1
    echo "Use $auth_url to archive mysql data"
}
