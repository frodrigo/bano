DROP TABLE IF EXISTS tuiles_slippy_map CASCADE;

CREATE TEMP TABLE pol_admin_level_8_3857
AS
SELECT ST_Transform(way,3857) AS way
FROM   planet_osm_polygon
WHERE  boundary='administrative' AND
       admin_level='8';

CREATE TABLE tuiles_slippy_map
AS
WITH
grid
AS
(SELECT (ST_SquareGrid(2445.98486328125, way)).geom
FROM pol_admin_level_8_3857),
grid_geo
AS
(SELECT DISTINCT geom, ST_Transform(ST_Centroid(geom),4326) AS geom_centroid_geo
FROM grid)
SELECT geom,
       geom_centroid_geo,
       lon2tile(ST_X(geom_centroid_geo),14) AS col,
       lat2tile(ST_Y(geom_centroid_geo),14) AS ligne,
       true AS chevauchant_a8
FROM   grid_geo;

CREATE INDEX gidx_tuiles_slippy_map ON tuiles_slippy_map USING GIST(geom);

ALTER TABLE tuiles_slippy_map ADD COLUMN id SERIAL;

UPDATE tuiles_slippy_map
SET    chevauchant_a8 = false
WHERE  id in (SELECT DISTINCT id 
              FROM   tuiles_slippy_map
              JOIN   pol_admin_level_8_3857
              ON     geom && way
              WHERE  ST_Contains(way,geom));
