CREATE TABLE IF NOT EXISTS bano_adresses (
    fantoir text,
    bano_id text GENERATED ALWAYS AS (fantoir||'_'|| REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REGEXP_REPLACE(UPPER(numero),'^0*',''),'BIS','B'),'TER','T'),'QUATER','Q'),'QUAT','Q'),' ',''),'à','-'),';',','),'"','')) STORED,
    lon float,
    lat float,
    numero  text,
    nom_voie text,
    nom_place text,
    code_postal text,
    code_insee text,
    code_dept text,
    code_insee_ancienne_commune text,
    nom_ancienne_commune text,
    source text,
    certification_commune integer,
    id_ban text,
    geometrie geometry (Point, 4326) GENERATED ALWAYS AS (ST_Point(lon,lat)) STORED,
    geometrie_3857 geometry (Point, 3857) GENERATED ALWAYS AS (ST_Transform(ST_SetSRID(ST_Point(lon,lat),4326),3857)) STORED);

CREATE INDEX IF NOT EXISTS gidx_bano_adresses ON bano_adresses USING GIST(geometrie);
CREATE INDEX IF NOT EXISTS gidx_bano_adresses_3857 ON bano_adresses USING GIST(geometrie_3857);
CREATE INDEX IF NOT EXISTS idx_bano_adresses_code_insee ON bano_adresses (code_insee);
CREATE INDEX IF NOT EXISTS idx_bano_adresses_code_dept ON bano_adresses (code_dept);
CREATE INDEX IF NOT EXISTS idx_bano_adresses_fantoir ON bano_adresses (fantoir);
CREATE INDEX IF NOT EXISTS idx_bano_adresses_bano_id ON bano_adresses (bano_id);
CREATE INDEX IF NOT EXISTS idx_bano_adresses_pifo_code_insee_source ON bano_adresses (code_insee,source);

CREATE TABLE IF NOT EXISTS bano_points_nommes (
    fantoir text,
    nom text,
    code_insee text,
    code_dept text,
    nature text,
    code_insee_ancienne_commune text,
    nom_ancienne_commune text,
    source text,
    lon float,
    lat float,
    geometrie geometry (Point, 4326) GENERATED ALWAYS AS (ST_Point(lon,lat)) STORED,
    geometrie_3857 geometry (Point, 3857) GENERATED ALWAYS AS (ST_Transform(ST_SetSRID(ST_Point(lon,lat),4326),3857)) STORED);

CREATE INDEX IF NOT EXISTS gidx_bano_points_nommes ON bano_points_nommes USING GIST(geometrie);
CREATE INDEX IF NOT EXISTS gidx_bano_points_nommes_3857 ON bano_points_nommes USING GIST(geometrie_3857);
CREATE INDEX IF NOT EXISTS idx_bano_points_nommes_code_insee ON bano_points_nommes (code_insee);
CREATE INDEX IF NOT EXISTS idx_bano_points_nommes_code_dept ON bano_points_nommes (code_dept);
CREATE INDEX IF NOT EXISTS idx_bano_points_nommes_fantoir ON bano_points_nommes (fantoir);
CREATE INDEX IF NOT EXISTS idx_bano_points_nommes_fantoir_source ON bano_points_nommes (fantoir,source);
CREATE INDEX IF NOT EXISTS idx_bano_points_nommes_code_insee_source ON bano_points_nommes (code_insee,source);
CREATE INDEX IF NOT EXISTS idx_bano_points_nommes_code_insee_nature ON bano_points_nommes (code_insee,nature);
CREATE INDEX IF NOT EXISTS idx_bano_points_nommes_code_dept_nature ON bano_points_nommes (code_dept,nature);

CREATE TABLE IF NOT EXISTS nom_fantoir (
    fantoir text,
    nom text,
    code_insee text,
    code_dept text,
    nature text,
    code_insee_ancienne_commune text,
    nom_ancienne_commune text,
    source text);

CREATE INDEX IF NOT EXISTS idx_nom_fantoir_code_insee ON nom_fantoir (code_insee);
CREATE INDEX IF NOT EXISTS idx_nom_fantoir_code_dept ON nom_fantoir (code_dept);
CREATE INDEX IF NOT EXISTS idx_nom_fantoir_fantoir ON nom_fantoir (fantoir);
CREATE INDEX IF NOT EXISTS idx_nom_fantoir_code_insee_source ON nom_fantoir (code_insee,source);

CREATE TABLE IF NOT EXISTS correspondance_fantoir_ban_osm(
    code_insee text,
    fantoir_ban text,
    fantoir_osm text);

CREATE INDEX IF NOT EXISTS idx_correspondance_fantoir_ban_osm_code_insee ON correspondance_fantoir_ban_osm (code_insee);
CREATE INDEX IF NOT EXISTS idx_correspondance_fantoir_ban_osm_fantoir_ban ON correspondance_fantoir_ban_osm (fantoir_ban);

CREATE TABLE IF NOT EXISTS statut_fantoir (
    fantoir character varying(9),
    id_statut integer,
    timestamp_statut double precision,
    code_insee character(5));

CREATE INDEX IF NOT EXISTS idx_statut_fantoir_fantoir ON statut_fantoir (fantoir);
CREATE INDEX IF NOT EXISTS idx_statut_fantoir_insee ON statut_fantoir (code_insee);

CREATE TABLE IF NOT EXISTS statut_numero (
    numero text ,
    fantoir character(9) ,
    source text ,
    id_statut integer,
    timestamp_statut double precision,
    code_insee character(5));

CREATE INDEX IF NOT EXISTS idx_statut_numero_fantoir ON statut_numero (fantoir, numero);

GRANT SELECT ON ALL TABLES IN SCHEMA public TO public;

CREATE TABLE IF NOT EXISTS bano_stats_communales(
    code_insee text,
    nb_adresses_osm integer,
    nb_adresses_ban integer,
    nb_nom_adr_osm integer,
    nb_nom_osm integer,
    nb_nom_ban integer,
    nb_nom_cadastre integer,
    nb_nom_topo integer,
    maj timestamp DEFAULT now(),
    ratio_noms_adr integer GENERATED ALWAYS AS ((100 * nb_nom_adr_osm) / greatest(nb_nom_ban,1)) STORED);

CREATE INDEX IF NOT EXISTS idx_bano_stats_communales_code_insee ON bano_stats_communales (code_insee);

CREATE TABLE IF NOT EXISTS bano_stats_communales_cumul(
    code_insee text,
    nb_adresses_osm integer,
    nb_adresses_ban integer,
    nb_nom_adr_osm integer,
    nb_nom_osm integer,
    nb_nom_ban integer,
    nb_nom_cadastre integer,
    nb_nom_topo integer,
    maj timestamp,
    ratio_noms_adr integer);

CREATE INDEX IF NOT EXISTS idx_bano_stats_communales_cumul_code_insee ON bano_stats_communales_cumul (code_insee);

CREATE TABLE IF NOT EXISTS infos_communes (
    dep character varying(3),
    code_insee character(5),
    name text,
    adm_weight integer,
    population integer,
    population_milliers numeric,
    type text,
    lon numeric,
    lat numeric,
    geometrie geometry(Point, 4326));

CREATE INDEX IF NOT EXISTS idx_infos_communes_insee ON infos_communes(code_insee);
CREATE INDEX IF NOT EXISTS gidx_infos_communes ON infos_communes USING GIST(geometrie);


CREATE TABLE IF NOT EXISTS croisement_voies_limites (
    code_dept character varying(3),
    id integer,
    osm_id bigint,
    geometrie_osm geometry(LineString,4326),
    nom_osm text,
    nom_commune_debut text,
    code_insee_debut character(5),
    rapproche_debut boolean,
    nom_commune_fin text,
    code_insee_fin character(5),
    rapproche_fin boolean,
    export_pbf boolean DEFAULT false,
    point_debut_3857 geometry (Point, 3857) GENERATED ALWAYS AS (ST_Transform(ST_StartPoint(geometrie_osm),3857)) STORED,
    point_fin_3857 geometry (Point, 3857) GENERATED ALWAYS AS (ST_Transform(ST_EndPoint(geometrie_osm),3857)) STORED,
    geometrie_osm_3857 geometry (LineString, 3857) GENERATED ALWAYS AS (ST_Transform(geometrie_osm,3857)) STORED);

CREATE INDEX IF NOT EXISTS idx_croisement_voies_limites_code_dept ON croisement_voies_limites(code_dept);
CREATE INDEX IF NOT EXISTS gidx_croisement_voies_limites ON croisement_voies_limites USING GIST(geometrie_osm);
CREATE INDEX IF NOT EXISTS gidx_croisement_voies_limites_3857 ON croisement_voies_limites USING GIST(geometrie_osm_3857);

CREATE TABLE IF NOT EXISTS point_croisement_voies_limites (
    code_dept character varying(3),
    osm_id bigint,
    geometrie geometry(Point,4326),
    nom_osm text,
    code_insee_debut character(5),
    code_insee_fin character(5),
    degres integer,
    geometrie_3857 geometry (Point, 3857) GENERATED ALWAYS AS (ST_Transform(geometrie,3857)) STORED);

CREATE INDEX IF NOT EXISTS idx_point_croisement_voies_limites_code_dept ON point_croisement_voies_limites(code_dept);
CREATE INDEX IF NOT EXISTS gidx_point_croisement_voies_limites_3857 ON point_croisement_voies_limites USING GIST(geometrie_3857);
