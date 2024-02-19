CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- tables Imposm dans le schema osm
ALTER ROLE cadastre IN DATABASE bano SET search_path TO public,osm;