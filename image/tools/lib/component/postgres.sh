#!/usr/bin/env bash
function component_dump_data {
  dest=$1
  echo "*:5432:*:${POSTGRES_USERNAME}:${POSTGRES_PASSWORD}" > ~/.pgpass
  chmod 0600 ~/.pgpass
  ts=$(date '+%H:%M:%S')
  export PGPASSFILE=~/.pgpass
  namespace=${POSTGRES_HOST#*.}
  namespace=${namespace%.*}

  if [ ${POSTGRES_SUPERUSER} == "true" ]; then
    pg_dumpall --clean --if-exists --oids -U ${POSTGRES_USERNAME} -h ${POSTGRES_HOST} | gzip > ${dest}/archives/${namespace}.${ts}.pg_dumpall.gz
    rc=$?
    if [ ${rc} -ne 0 ]; then
      echo "backup of postgresql: FAILED"
      exit 1
    fi
  else
    for db in $(psql -U ${POSTGRES_USERNAME} -h ${POSTGRES_HOST} ${POSTGRES_DATABASE} -A -t -c '\l' | cut -f1 -d'|' | grep -v '=' | grep -v 'template'); do
      echo "dumping ${db}"
      pg_dump --clean --if-exists --oids -U ${POSTGRES_USERNAME} -h ${POSTGRES_HOST} ${db} | gzip > ${dest}/archives/${namespace}.${db}-${ts}.pg_dump.gz
      rc=$?
      if [ ${rc} -ne 0 ]; then
          echo "==> Dump $db: FAILED"
          exit 1
      fi
    done

  fi
}