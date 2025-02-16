#!/bin/bash

#set -e

source /data/project/bano_v3/venv_v3/bin/activate

pip install -e .

source config

lockfile=imposm.lock
LOGFILE=${SCRIPT_DIR}/cron.log

echo `date`>> ${LOGFILE}
echo debut >> ${LOGFILE}

if test -f ${lockfile}
then
  diff_age=$((`date +%s` - `stat -c %Y $lockfile`))
  if [ $diff_age -gt 7200 ];then
    echo "Effacement du lock" >> ${LOGFILE}
    rm ${lockfile}
  else
    echo `date`" : Process deja en cours" >> ${LOGFILE}
    exit 1
  fi
fi


touch ${lockfile}

echo `date`" : Osmosis" >> ${LOGFILE}
osmosis --rri workingDirectory=${DOWNLOAD_DIR} --simc --wxc ${DOWNLOAD_DIR}/changes.osc.gz
echo `date`" : Imposm" >> ${LOGFILE}
imposm diff \
  -config imposm.config \
  -cachedir $IMPOSM_CACHE_DIR \
  -connection postgis://$PGCON_BANO?prefix=NONE \
  -dbschema-production osm \
  ${DOWNLOAD_DIR}/changes.osc.gz
echo `date`" : Osm2pgsql" >> ${LOGFILE}
osm2pgsql -a -S osm2pgsql.style -s -l -d bano -U cadastre -p osm2pgsql $DOWNLOAD_DIR/changes.osc.gz

rm ${lockfile}

echo `date` >> ${LOGFILE}
echo fin >> ${LOGFILE}

tail -1000 ${LOGFILE} > foo.bar.foo && mv foo.bar.foo ${LOGFILE}
