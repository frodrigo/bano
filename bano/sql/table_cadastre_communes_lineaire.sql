DROP TABLE IF EXISTS cadastre_communes_lineaire CASCADE;

CREATE TABLE cadastre_communes_lineaire
AS
SELECT code_insee,
       nom,
       ST_Transform(ST_SetSRID(ST_ExteriorRing((ST_DumpRings((ST_Dump(geometrie)).geom)).geom),4326),3857) AS geometrie_ligne_3857
FROM   cadastre_communes;

CREATE INDEX gidx_cadastre_communes_lineaire ON cadastre_communes_lineaire USING GIST(geometrie_ligne_3857);
