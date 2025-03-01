#!/bin/bash

set -e

source config

PBF_URL=${1:-http://download.openstreetmap.fr/extracts/merge/france_metro_dom_com_nc.osm.pbf}
PBF_FILE=$(basename "$PBF_URL")

lockfile=${DATA_DIR}/imposm.lock

if test -f ${lockfile}
then
  echo `date`" : Process deja en cours"
  exit 1
fi

touch ${lockfile}

mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR
wget --directory-prefix=$DOWNLOAD_DIR -NS $PBF_URL
# Récupère le state.txt
STATE_URL=${PBF_URL/.osm.pbf/.state.txt}
wget --directory-prefix=$DOWNLOAD_DIR -NS $STATE_URL
mv `basename "${STATE_URL}"` state.txt

# Configure osmosis pour les updates
rm -f configuration.txt
osmosis --read-replication-interval-init  workingDirectory=.
REPL=${PBF_URL/extracts/replication/}
REPL=${REPL/.osm.pbf/\/minute/}
sed -i -e "s|baseUrl.*|baseUrl=${REPL}|" configuration.txt
# 5 jours
sed -i -e "s|maxInterval.*|maxInterval=36000|" configuration.txt

cd -

imposm import \
  -config imposm.config \
  -read $DOWNLOAD_DIR/$PBF_FILE \
  -overwritecache \
  -cachedir $IMPOSM_CACHE_DIR \
  -diff \
  -write \
  -connection postgis://$PGCON_BANO?prefix=NONE \
  -dbschema-import public

$pgsql_BANO -f sql/finalisation.sql

cp $DOWNLOAD_DIR/last.state.txt $DOWNLOAD_DIR/state.txt
rm ${lockfile}
