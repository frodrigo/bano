#!/bin/bash

#set -e

lockfile=imposm.lock

echo `date`
echo debut

if test -f ${lockfile}
then
  diff_age=$((`date +%s` - `stat -c %Y $lockfile`))
  if [ $diff_age -gt 7200 ];then
    echo "Effacement du lock"
    rm ${lockfile}
  else
    echo `date`" : Process deja en cours"
    exit 1
  fi
fi


touch ${lockfile}

echo `date`" : Osmosis"
osmosis --rri workingDirectory=${DOWNLOAD_DIR} --simc --wxc ${DOWNLOAD_DIR}/changes.osc.gz
echo `date`" : Imposm"
imposm diff \
  -config imposm.config \
  -cachedir $IMPOSM_CACHE_DIR \
  -connection postgis://$PGCON_BANO?prefix=NONE \
  -dbschema-production osm \
  ${DOWNLOAD_DIR}/changes.osc.gz
echo `date`" : Osm2pgsql"
osm2pgsql -a -S osm2pgsql.style -s -l -d bano -U cadastre -p osm2pgsql $DOWNLOAD_DIR/changes.osc.gz

rm ${lockfile}

echo `date`
echo fin
