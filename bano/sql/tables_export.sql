DROP TABLE IF EXISTS cp_fantoir CASCADE;
CREATE TEMP TABLE
cp_fantoir
AS
(SELECT fantoir,
        MIN(code_postal) AS min_cp
FROM    bano_adresses
GROUP BY 1);
CREATE INDEX idx_cp_fantoir_fantoir ON cp_fantoir(fantoir);

DROP VIEW IF EXISTS num_norm CASCADE;
CREATE TEMP VIEW
num_norm
AS
(SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REGEXP_REPLACE(UPPER(numero),
                        '^0*',''),'BIS','B'),'TER','T'),'QUATER','Q'),'QUAT','Q'),' ',''),'à','-'),';',','),'"','') AS num,
        *
FROM    bano_adresses);

DROP TABLE IF EXISTS num_norm_id CASCADE;
CREATE TEMP TABLE
num_norm_id
AS
WITH a AS
(SELECT fantoir||'-'||num AS id_add,
        row_number() OVER (PARTITION BY fantoir||num ORDER BY CASE WHEN source = 'OSM' THEN 1 ELSE 2 END) AS rang,
        fantoir,
        numero,
        code_postal,
        code_insee,
        source,
        lat,
        lon,
        geometrie
FROM    num_norm)
SELECT * FROM a WHERE rang = 1;

DROP TABLE IF EXISTS nom_fantoir_with CASCADE;
CREATE TABLE nom_fantoir_with
AS
WITH
nom_fantoir_rank
AS
(
    SELECT
        fantoir,
        REPLACE(REPLACE(REGEXP_REPLACE(nom,'\t',' '),'"',chr(39)),'’',chr(39)) AS nom,
        (
            CASE WHEN source = 'OSM' THEN 1 ELSE 2 END * 100 +
            CASE nature WHEN 'lieu-dit' THEN 1 WHEN 'place' THEN 1 WHEN 'voie' THEN 2 ELSE 3 END * 10 +
            CASE WHEN nom_tag = 'name' THEN 1 ELSE 2 END
        ) AS rank
    FROM
        nom_fantoir
),
nom_fantoir_uniq_rank
AS (
    SELECT
        fantoir,
        (array_agg(nom ORDER BY
            -- Pour des noms similaires, préférer la version avec diacritiques
            regexp_count(nom, '[ÀÂÄÉÈÊËÎÏÔÖÙÛÜŸÇÆŒàâäéèêëîïôöùûüÿçæœñ]') DESC,
            -- Pour des noms similaires, préférer la version avec minuscule
            regexp_count(nom, '[a-zàâäéèêëîïôöùûüÿçæœñ]') DESC
        ))[1] AS nom,
        min(rank) AS rank
    FROM
        nom_fantoir_rank
    GROUP BY
        fantoir,
        replace(lower(unaccent(nom)), '-', ' ')
),
nom_fantoir
AS
(
    SELECT
        fantoir,
        array_agg(nom ORDER BY rank, nom) AS noms
    FROM
        nom_fantoir_uniq_rank
    GROUP BY
        fantoir
)
SELECT * FROM nom_fantoir;

DROP TABLE IF EXISTS numeros_export CASCADE;
CREATE TABLE numeros_export AS
(SELECT dep,
        n.code_insee,
        n.fantoir,
        id_add,
        numero,
        nf.noms AS nom_voie,
        n.code_postal,
        cn.libelle,
        source,
        lat,
        lon,
        n.geometrie
FROM    num_norm_id n
JOIN    nom_fantoir_with nf
USING   (fantoir)
JOIN    (SELECT dep, com, libelle FROM cog_commune WHERE typecom in ('ARM','COM')) cn
ON      (cn.com = code_insee)
);

DROP TABLE num_norm_id;
DROP TABLE nom_fantoir_with;

WITH n
AS
(SELECT DISTINCT ON (id_add)
        id_add,
        COALESCE(n.code_postal,pp.code_postal,min_cp) code_postal
FROM    numeros_export n
LEFT OUTER JOIN    polygones_postaux pp
ON      ST_Contains(pp.geometrie, n.geometrie)
LEFT OUTER JOIN cp_fantoir
ON      pp.code_postal IS NULL AND cp_fantoir.fantoir = n.fantoir
WHERE
    n.code_postal IS NULL
ORDER BY id_add, pp.id
)
UPDATE numeros_export
SET code_postal = n.code_postal
FROM n
WHERE
    numeros_export.code_postal IS NULL AND
    numeros_export.id_add = n.id_add
;

DROP TABLE cp_fantoir;

DROP TABLE IF EXISTS numeros_export_importance CASCADE;
CREATE TABLE numeros_export_importance
AS
SELECT fantoir,
       ST_Length(ST_Transform(ST_Longestline(ST_Convexhull(ST_Collect(geometrie)),ST_Convexhull(ST_Collect(geometrie))),3857)) AS longueur_max,
       count(*) AS nombre_adresses
FROM   numeros_export
GROUP BY fantoir;
CREATE INDEX numeros_export_importance_idx_fantoir ON numeros_export_importance(fantoir);


DROP VIEW IF EXISTS export_voies_adresses_json CASCADE;
CREATE VIEW export_voies_adresses_json
AS
SELECT c.dep,
       fantoir AS id,
       ne.code_insee AS citycode,
       'street' AS type,
       nom_voie AS name,
       code_postal AS postcode,
       ROUND(pn.lat::numeric,6)::float AS lat,
       ROUND(pn.lon::numeric,6)::float AS lon,
       CASE
            WHEN pa.libelle IS NOT NULL THEN ARRAY[pa.libelle, cog.nom_com]
            ELSE ARRAY[cog.nom_com]
       END AS city,
       nom_dep AS departement,
       nom_reg AS region,
       ROUND(LOG(c.adm_weight+LOG(c.population+1)/3)::numeric*LOG(1+LOG(nombre_adresses+1)+LOG(longueur_max+1)+LOG(CASE WHEN nom_voie[1] like 'Boulevard%' THEN 4 WHEN nom_voie[1] LIKE 'Place%' THEN 4 WHEN nom_voie[1] LIKE 'Espl%' THEN 4 WHEN nom_voie[1] LIKE 'Av%' THEN 3 WHEN nom_voie[1] LIKE 'Rue %' THEN 2 ELSE 1 END))::numeric,4)::float AS importance,
       string_agg(numero||'$$$'||ROUND(ne.lat::numeric,6)::text||'$$$'||ROUND(ne.lon::numeric,6)::text,'@@@' ORDER BY numero) AS housenumbers
FROM   numeros_export ne
JOIN   cog_pyramide_admin AS cog
USING  (code_insee)
JOIN   (SELECT DISTINCT ON (fantoir)
               fantoir,
               lon,
               lat
       FROM    bano_points_nommes
       WHERE   fantoir IS NOT NULL
       ORDER BY fantoir, CASE source WHEN 'OSM' THEN 1 WHEN 'BAN' THEN 3 ELSE 2 END, CASE nature WHEN 'centroide' THEN 2 ELSE 1 END
       ) AS pn
USING  (fantoir)
JOIN   infos_communes c
USING  (code_insee)
JOIN   numeros_export_importance
USING  (fantoir)
LEFT JOIN cog_commune AS a ON
    cog.typecom = 'ARM' AND
    cog.code_insee = a.com AND
    a.dep = c.dep
LEFT JOIN cog_commune AS pa ON
    pa.com = a.comparent AND
    pa.dep = c.dep
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
;

DROP TABLE IF EXISTS set_fantoir CASCADE;
CREATE TABLE IF NOT EXISTS set_fantoir AS
(SELECT fantoir FROM bano_points_nommes
EXCEPT
SELECT fantoir FROM numeros_export)
;
CREATE INDEX idx_set_fantoir_fantoir ON set_fantoir(fantoir);

DROP VIEW IF EXISTS export_voies_ld_sans_adresses_json CASCADE;
CREATE VIEW export_voies_ld_sans_adresses_json
AS
WITH
resultats_multi_cp
AS
(SELECT pn.fantoir AS id,
       pn.code_insee AS citycode,
       nature,
       CASE
           WHEN nature = 'place' THEN 'place'
           WHEN nature = 'lieu-dit' THEN 'place'
           ELSE 'street'
       END AS type,
       REPLACE(REPLACE(REGEXP_REPLACE(nom,'\t',' '),'"',chr(39)),'’',chr(39)) AS name,
       code_postal AS postcode,
       ROUND(pn.lat::numeric,6)::float AS lat,
       ROUND(pn.lon::numeric,6)::float AS lon,
       CASE
            WHEN pa.libelle IS NOT NULL THEN ARRAY[pa.libelle, cog.nom_com]
            ELSE ARRAY[cog.nom_com]
       END AS city,
       nom_dep AS departement,
       nom_reg AS region,
       CASE
           WHEN nature IN ('place','lieu-dit') THEN 0.05
           ELSE ROUND(LOG(c.adm_weight+LOG(c.population+1)/3)::numeric*LOG(1+LOG(CASE WHEN nom like 'Boulevard%' THEN 4 WHEN nom LIKE 'Place%' THEN 4 WHEN nom LIKE 'Espl%' THEN 4 WHEN nom LIKE 'Av%' THEN 3 WHEN nom LIKE 'Rue %' THEN 2 ELSE 1 END))::numeric,4)::float
       END AS importance,
       source,
       ROW_NUMBER() OVER (PARTITION BY fantoir ORDER BY CASE source WHEN 'OSM' THEN 1 ELSE 2 END, CASE nature WHEN 'centroide' THEN 2 ELSE 1 END,pp.id) AS rang_par_fantoir,
       c.dep
FROM   set_fantoir
JOIN   bano_points_nommes AS pn
USING  (fantoir)
JOIN   cog_pyramide_admin AS cog
USING  (code_insee)
JOIN   infos_communes c
USING  (code_insee)
JOIN    polygones_postaux pp
ON      ST_Contains(pp.geometrie, pn.geometrie)
LEFT JOIN cog_commune AS a ON
    cog.typecom = 'ARM' AND
    cog.code_insee = a.com
LEFT JOIN cog_commune AS pa ON
    pa.com = a.comparent
)
SELECT *
FROM resultats_multi_cp
WHERE rang_par_fantoir = 1;
