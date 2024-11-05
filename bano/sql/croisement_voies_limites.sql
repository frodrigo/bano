CREATE TEMP TABLE poladmin
AS
SELECT way AS geometrie,
       "ref:INSEE" AS code_insee,
       admin_level,
       name AS nom_com
FROM   osm2pgsql_polygon
WHERE  boundary='administrative' AND
       admin_level = '8' AND
       "ref:INSEE" LIKE '__dept__%' AND
       name IS NOT NULL;
CREATE INDEX gidx_poladmin ON poladmin USING GIST(geometrie);

CREATE TEMP TABLE highway_name
as
SELECT uniqid,
       osm_id,
       way,
       ST_StartPoint(way) way_from,
       ST_EndPoint(way) way_to,
       name AS nom
FROM   (SELECT uniqid,
               osm_id,
               way,
               name
       FROM    osm2pgsql_line
       WHERE   osm_id > 0 AND
               name IS NOT NULL AND
               highway IS NOT NULL) l
JOIN poladmin
ON   way && geometrie;

CREATE INDEX gidx_highway_name_from ON highway_name USING GIST(way_from);
CREATE INDEX gidx_highway_name_to ON highway_name USING GIST(way_to);

DELETE
FROM   croisement_voies_limites
WHERE  code_dept = '__dept__';

INSERT INTO croisement_voies_limites
WITH
sub
AS
(SELECT DISTINCT uniqid,
                 osm_id,
                 way,
                 nom,
                 pf.nom_com    AS nom_commune_debut,
                 pf.code_insee AS code_insee_debut,
                 pt.nom_com    AS nom_commune_fin,
                 pt.code_insee AS code_insee_fin
FROM  highway_name n
JOIN  poladmin AS pf
ON    n.way_from && pf.geometrie AND
      ST_Contains(pf.geometrie,way_from)
JOIN  poladmin AS pt
ON    n.way_to && pt.geometrie AND
      ST_Contains(pt.geometrie,way_to)
WHERE pf.code_insee != pt.code_insee)
SELECT DISTINCT '__dept__',
                uniqid,
                osm_id,
                way,
                sub.nom,
                nom_commune_debut,
                code_insee_debut,
                COALESCE(nff.rapproche,False),
                nom_commune_fin,
                code_insee_fin,
                COALESCE(nft.rapproche,False)
FROM sub
LEFT JOIN (SELECT code_insee AS code_insee_debut,nom,True AS rapproche FROM nom_fantoir WHERE code_insee LIKE '__dept__%' AND source = 'OSM') as nff
USING (code_insee_debut,nom)
LEFT JOIN (SELECT code_insee,nom,True AS rapproche FROM nom_fantoir WHERE code_insee LIKE '__dept__%' AND source = 'OSM') as nft
ON    code_insee_fin = nft.code_insee AND
      sub.nom = nft.nom;

CREATE TEMP TABLE pol_line
AS
SELECT code_insee,
       ST_Collect(ST_ExteriorRing(geom)) AS erings
FROM   (SELECT code_insee,
               (ST_Dump(geometrie)).geom AS geom
       FROM    poladmin) AS pol
GROUP BY 1;
CREATE INDEX gidx_pol ON pol_line USING GIST (erings);

DELETE FROM point_croisement_voies_limites
WHERE code_dept = '__dept__';

INSERT INTO point_croisement_voies_limites
WITH
pts
AS
(SELECT    code_dept,
           osm_id,
           (ST_DumpPoints(ST_Intersection(geometrie_osm,erings))).geom,
           geometrie_osm,
           nom_osm,
           code_insee_debut,
           code_insee_fin
FROM       (SELECT * FROM croisement_voies_limites WHERE code_dept = '__dept__') c
JOIN       pol_line
ON         code_insee = code_insee_debut
UNION
SELECT     code_dept,
           osm_id,
           (ST_DumpPoints(ST_Intersection(geometrie_osm,erings))).geom,
           geometrie_osm,
           nom_osm,
           code_insee_debut,
           code_insee_fin
FROM       (SELECT * FROM croisement_voies_limites WHERE code_dept = '__dept__') c
JOIN       pol_line
ON         code_insee = code_insee_fin)
SELECT     code_dept,
           osm_id,
           geom,
           nom_osm,
           code_insee_debut,
           code_insee_fin,
           DEGREES(ST_Azimuth(ST_LineInterpolatePoint(geometrie_osm,greatest(0.0,ST_LineLocatePoint(geometrie_osm,geom)::numeric - 0.01)),
                        ST_LineInterpolatePoint(geometrie_osm,least(1.0,ST_LineLocatePoint(geometrie_osm,geom)::numeric + 0.01))))::integer % 180 + 90
FROM       pts;