#!/usr/bin/env bash

function get_postgres_username {
  echo "`oc get secret ${COMPONENT_SECRET_NAME} -n default -o jsonpath={.data.POSTGRES_USERNAME} | base64 --decode`"
}

function get_postgres_password {
  echo "`oc get secret ${COMPONENT_SECRET_NAME} -n default -o jsonpath={.data.POSTGRES_PASSWORD} | base64 --decode`"
}

function get_postgres_host {
  echo "`oc get secret ${COMPONENT_SECRET_NAME} -n default -o jsonpath={.data.POSTGRES_HOST} | base64 --decode`"
}

function get_postgres_database {
  echo "`oc get secret ${COMPONENT_SECRET_NAME} -n default -o jsonpath={.data.POSTGRES_DATABASE} | base64 --decode`"
}

function get_postgres_superuser {
  echo "`oc get secret ${COMPONENT_SECRET_NAME} -n default -o jsonpath={.data.POSTGRES_SUPERUSER} | base64 --decode`"
}

function component_dump_data {
  local dest=$1
  local POSTGRES_USERNAME=$(get_postgres_username)
  local POSTGRES_PASSWORD=$(get_postgres_password)
  local POSTGRES_HOST=$(get_postgres_host)
  local POSTGRES_DATABASE=$(get_postgres_database)
  local POSTGRES_SUPERUSER=$(get_postgres_superuser)

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