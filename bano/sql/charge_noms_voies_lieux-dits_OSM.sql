SELECT	pl.name,
		pl."ref:FR:FANTOIR" f,
		'' fl,
		'' fr,
		h.libelle_suffixe,
		p."ref:INSEE",
		CASE
		    WHEN pl.place='' THEN 'voie'::text
		    ELSE 'lieudit'
		END AS nature
FROM	planet_osm_polygon 	p
JOIN	planet_osm_point 	pl
ON		pl.way && p.way					AND
		ST_Intersects(pl.way, p.way)
LEFT OUTER JOIN suffixe h
ON		ST_Intersects(pl.way, h.geometrie)
WHERE	p."ref:INSEE" = '__code_insee__'	                 AND
		(pl."ref:FR:FANTOIR" !='' OR pl.place != '') AND
		pl.name != ''
UNION
SELECT	l.name,
		l.tags->'ref:FR:FANTOIR' f,
		l.tags->'ref:FR:FANTOIR:left' fl,
		l.tags->'ref:FR:FANTOIR:right' fr,
		h.libelle_suffixe,
		p."ref:INSEE",
		'voie'
FROM	planet_osm_polygon 	p
JOIN	planet_osm_line 	l
ON		ST_Intersects(l.way, p.way)
LEFT OUTER JOIN suffixe h
ON		ST_Intersects(l.way, h.geometrie)
WHERE	p."ref:INSEE" = '__code_insee__'	AND
		l.highway 	!= ''			AND
		l.name 		!= ''
UNION
SELECT	pl.name,
		pl."ref:FR:FANTOIR" f,
		pl."ref:FR:FANTOIR:left" fl,
		pl."ref:FR:FANTOIR:right" fr,
		h.libelle_suffixe,
		p."ref:INSEE",
		'voie'
FROM	planet_osm_polygon 	p
JOIN	planet_osm_polygon 	pl
ON		pl.way && p.way					AND
		ST_Intersects(pl.way, p.way)
LEFT OUTER JOIN suffixe h
ON		ST_Intersects(pl.way, h.geometrie)
WHERE	p."ref:INSEE" = '__code_insee__'		AND
		            (pl.highway||pl."ref:FR:FANTOIR" != ''	OR
					pl.landuse = 'residential'				OR
					pl.amenity = 'parking')	AND
		pl.name 	!= '';

