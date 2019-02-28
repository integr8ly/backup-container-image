function component_dump_data {
    dest=$1
    databases=$(mysql -h$MYSQL_HOST -u$MYSQL_USER  -p$MYSQL_PASSWORD -e 'SHOW DATABASES' | tail -n+2 | grep -v information_schema)
    for database in $databases; do
        ts=$(date '+%H:%M:%S')
        mysqldump --single-transaction -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -R $database | gzip > $dest/archives/$database-$ts.dump.gz
        rc=$?
        if [ $rc -ne 0 ]; then
            echo "==> Dump $database: FAILED"
            exit 1
        fi
    done
}
