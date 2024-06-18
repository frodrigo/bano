CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;

-- tables Imposm dans le schema osm
ALTER ROLE postgres SET search_path TO public,osm;
