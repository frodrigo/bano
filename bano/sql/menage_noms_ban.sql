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