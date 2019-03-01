function component_dump_data {
    dest_file="$1/archives/dump.rdb"
    dumb_rdb_path="/var/lib/redis/data/dump.rdb"

    oc projects
    redis_pod_name=$(oc get pods -l deploymentConfig=backend-redis -o name -n 3scale | sed -e 's/^pod\///')
    copy_output=$(oc cp 3scale/${redis_pod_name}:${dumb_rdb_path} ${dest_file})
    echo ${copy_output}
    
    # check if rdb file was rewritten during oc cp, and copy it again if it was
    if [[ $copy_output == *"file changed as we read it"* ]]; then
        sleep 10s #wait until rdb rewrite finished
        echo "dumb.rdb has been overwritten during copying, executing 'oc cp' again"
        oc cp 3scale/${redis_pod_name}:${dumb_rdb_path} ${dest_file}
    fi
}