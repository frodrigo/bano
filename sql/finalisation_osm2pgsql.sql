ALTER TABLE osm2pgsql_line ADD COLUMN uniqid serial;
CREATE INDEX idx_osm2pgsql_line_uniqid ON osm2pgsql_line(uniqid);