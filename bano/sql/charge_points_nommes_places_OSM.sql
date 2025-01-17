WITH
pts
AS
(SELECT  pt.way,
        UNNEST(ARRAY[pt.name,pt.alt_name,pt.old_name]) as name,
        tags,
        place,
        a9.code_insee AS insee_ac,
        "ref:FR:FANTOIR" AS fantoir,
        a9.nom AS nom_ac
FROM    (SELECT way FROM planet_osm_polygon WHERE "ref:INSEE" = '__code_insee__')                    p
JOIN    (SELECT * FROM planet_osm_point WHERE place != '' AND name != '') pt
ON      pt.way && p.way                 AND
         ST_Intersects(pt.way, p.way)
LEFT OUTER JOIN (SELECT osm_id FROM planet_osm_communes_statut WHERE "ref:INSEE" = '__code_insee__' AND member_role = 'admin_centre') admin_centre
ON      pt.osm_id = admin_centre.osm_id
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(pt.way, a9.geometrie)
WHERE   admin_centre.osm_id IS NULL),
pts_hors_commune
AS
(SELECT  pt.way,
        UNNEST(ARRAY[pt.name,pt.alt_name,pt.old_name]) as name,
        tags,
        place,
        null::text AS insee_ac,
        "ref:FR:FANTOIR" AS fantoir,
        null::text AS nom_ac
FROM    (SELECT way FROM planet_osm_polygon WHERE "ref:INSEE" = '__code_insee__')                    p
JOIN    (SELECT * FROM planet_osm_point WHERE place != '' AND name != '' AND "ref:FR:FANTOIR" != '') pt
ON      pt.way && p.way                 AND
        NOT ST_Within(p.way,pt.way)),
polys
AS
(SELECT  st_centroid(pt.way) AS way,
        UNNEST(ARRAY[pt.name,pt.alt_name,pt.old_name]) as name,
        tags,
        place,
        a9.code_insee AS insee_ac,
        "ref:FR:FANTOIR" AS fantoir,
        a9.nom AS nom_ac
FROM    (SELECT way FROM planet_osm_polygon WHERE "ref:INSEE" = '__code_insee__')                    p
JOIN    (SELECT osm_id,way as way,name,alt_name,old_name,place,"ref:FR:FANTOIR",tags FROM planet_osm_polygon ) pt
ON      pt.way && p.way                 AND
         ST_Intersects(pt.way, p.way)
LEFT OUTER JOIN (SELECT osm_id FROM planet_osm_communes_statut WHERE "ref:INSEE" = '__code_insee__' AND member_role = 'admin_centre') admin_centre
ON      pt.osm_id = admin_centre.osm_id
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(pt.way, a9.geometrie)
WHERE   admin_centre.osm_id IS NULL and pt.place != '' AND pt.name != ''),
fullset
as
(SELECT ST_x(way) AS x,
        ST_y(way) AS y,
        name,
        insee_ac,
        fantoir,
        nom_ac,
        CASE
            WHEN fantoir != '' THEN 1
            ELSE 3
        END AS sortorder
FROM    pts
WHERE   name != ''
UNION
SELECT  ST_x(way),
        ST_y(way),
        name,
        insee_ac,
        fantoir,
        nom_ac,
        CASE
            WHEN fantoir != '' THEN 2
            ELSE 4
        END AS sortorder
FROM    polys
WHERE   name != ''
UNION
SELECT ST_x(way) AS x,
        ST_y(way) AS y,
        name,
        insee_ac,
        fantoir,
        nom_ac,
        5 AS sortorder
FROM    pts_hors_commune
WHERE   name != ''),
classement
as
(SELECT *,
        row_number() OVER (PARTITION BY name ORDER BY sortorder,1)
FROM    fullset)
SELECT  x,
        y,
        name,
        insee_ac,
        fantoir,
        nom_ac
FROM    classement
WHERE   row_number = 1;
