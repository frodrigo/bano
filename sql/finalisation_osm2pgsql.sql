ALTER TABLE osm2pgsql_line ADD COLUMN uniqid serial;
CREATE INDEX idx_osm2pgsql_line_uniqid ON osm2pgsql_line(uniqid);


CREATE INDEX gidx_osm2pgsql_line_highway_name ON osm2pgsql_line USING gist (way) WHERE name IS NOT NULL AND highway IS NOT NULL;
CREATE INDEX idx_osm2pgsql_polygon_ref_insee ON osm2pgsql_polygon("ref:INSEE");
