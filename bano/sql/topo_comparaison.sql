DROP TABLE IF EXISTS topo_comparaison CASCADE;

CREATE TABLE topo_comparaison
AS
SELECT code_insee AS code, 'communes apparues'  AS test FROM topo_test
EXCEPT
SELECT code_insee AS code, 'communes apparues'  AS test FROM topo       WHERE type_voie != 'B'
UNION ALL
SELECT code_insee AS code, 'communes disparues' AS test FROM topo       WHERE type_voie != 'B'
EXCEPT
SELECT code_insee AS code, 'communes disparues' AS test FROM topo_test
UNION ALL
SELECT fantoir    AS code, 'fantoirs apparus'   AS test FROM topo_test
EXCEPT
SELECT fantoir    AS code, 'fantoirs apparus'   AS test FROM topo       WHERE type_voie != 'B'
UNION ALL
SELECT fantoir    AS code, 'fantoirs disparus'  AS test FROM topo       WHERE type_voie != 'B'
EXCEPT
SELECT fantoir    AS code, 'fantoirs disparus'  AS test FROM topo_test;