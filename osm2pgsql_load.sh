#!/bin/bash

set -e

source config

PBF_URL=${1:-http://download.openstreetmap.fr/extracts/merge/france_metro_dom_com_nc.osm.pbf}
PBF_FILE=$(basename "$PBF_URL")

mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR
wget -NS $PBF_URL

osm2pgsql -S $BANO_DIR/osm2pgsql.style -l -d bano -U cadastre -p osm2pgsql $DOWNLOAD_DIR/$PBF_FILE

$pgsql_BANO -f $BANO_DIR/sql/finalisation_osm2pgsql.sql
