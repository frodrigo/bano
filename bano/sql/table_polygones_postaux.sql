BEGIN;

DROP TABLE IF EXISTS polygones_postaux CASCADE;
CREATE TABLE polygones_postaux
AS
SELECT way AS geometrie,
       CASE postal_code
           WHEN '' THEN "addr:postcode"
           ELSE postal_code
       END AS code_postal
FROM   planet_osm_postal_code
WHERE  boundary = 'postal_code' AND
      "addr:postcode"||postal_code != ''
ORDER BY ST_Area(way);
ALTER TABLE polygones_postaux ADD COLUMN id serial;

INSERT INTO polygones_postaux
SELECT way,
       CASE postal_code
           WHEN '' THEN "addr:postcode"
           ELSE postal_code
       END AS code_postal
FROM   planet_osm_postal_code
WHERE  boundary = 'administrative' AND
       "addr:postcode"||postal_code != ''
ORDER BY ST_Area(way);

CREATE INDEX gidx_polygones_postaux ON polygones_postaux USING GIST(geometrie);

COMMIT;