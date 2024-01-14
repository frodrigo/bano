SELECT id,
       citycode,
       type,
       name,
       postcode,
       lat,
       lon,
       city,
       departement,
       region,
       importance,
       housenumbers
FROM   export_voies_adresses_json
WHERE  dep = '__dept__'
ORDER BY 1;