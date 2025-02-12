UPDATE ban
SET    nom_voie = TRIM (BOTH CHR(39) FROM (
                    TRIM (BOTH FROM (
                       REPLACE(REPLACE(nom_voie,CHR(39)||CHR(39),CHR(39)),CHR(34),'')
                    )
                  )))
WHERE nom_voie LIKE '% '                       OR
      nom_voie LIKE ' %'                       OR
      nom_voie LIKE '%'||CHR(39)||CHR(39)||'%' OR
      nom_voie LIKE '%'||CHR(34)||'%'          OR
      nom_voie LIKE CHR(39)||'%'               OR
      nom_voie LIKE '%'||CHR(39);


-- Supprime de la BAN des voies de mêmes noms sur la même commune fusionnée par erreur
-- https://github.com/osm-fr/bano/issues/439
DELETE FROM
   ban
WHERE
   code_insee='33063' AND
   nom_voie IN (
      'Rue Camille Saint-Saëns',
      'Rue Corot',
      'Rue Jean-Jacques Rousseau',
      'Rue Kléber',
      'Rue de Lacanau',
      'Rue Maréchal Joffre',
      'Rue Pierre Loti'
   )
;
