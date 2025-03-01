#!/bin/bash

OLD=$1
NEW=$2
JSON=${3:-full.sjson.gz}

# Stats du nombre d'éléments par commune
zcat "$OLD/$JSON" | jq -rc '. | {id: .id[0:5]}' | jq -rcs 'group_by(.id) | [.[] | {id: .[0].id, length_old: length}] | sort_by(".id")' > /tmp/count-commune-old.json
zcat "$NEW/$JSON" | jq -rc '. | {id: .id[0:5]}' | jq -rcs 'group_by(.id) | [.[] | {id: .[0].id, length_new: length}] | sort_by(".id")' > /tmp/count-commune-new.json

# Diff des id communes, vérifie les communes ajoutées ou supprimées
echo
echo "== Communes en moins et en plus =="
echo
cat /tmp/count-commune-old.json | jq -r '.[] | .id' | sort | uniq > /tmp/commune-id-old.csv
cat /tmp/count-commune-new.json | jq -r '.[] | .id' | sort | uniq > /tmp/commune-id-new.csv
diff -ruN /tmp/commune-id-old.csv /tmp/commune-id-new.csv | grep "^[-+]"

# Stats sur les communes avec les plus grosses différences
echo
echo "== Communes avec les plus grosses différences =="
echo
jq -cs 'map(map({key: .id, value: .}) | from_entries) | .[0] * .[1] | map(.) | .[] | select(.length_old and .length_new and .length_old != .length_new) | (. += { length_diff: (.length_new - .length_old), length_change: ((.length_new - .length_old) / .length_old) })' /tmp/count-commune-old.json /tmp/count-commune-new.json | jq -cs 'sort_by(.length_change) | .[]' > /tmp/count-commune-diff.json

head -n 20 /tmp/count-commune-diff.json
echo

tail -n 20 /tmp/count-commune-diff.json
echo

echo "Nombre de communes avec une perte d'au moins 30% de voies/ld"
cat /tmp/count-commune-diff.json | jq -c 'select(.length_change < -0.3)' | wc -l
echo
echo "Communes de grande taille avec une perte d'au moins 5% de voies/ld"
cat /tmp/count-commune-diff.json | jq -c 'select(.length_old > 2000 and .length_change < -0.05)'



# Stats du type d'élément par département
zcat "$OLD/$JSON" | jq -rc '. | {id: .id[0:2], type: .type}' | jq -cs 'group_by([.id, .type]) | [.[] | {id: .[0].id, type: .[0].type, length_old: length}] | sort_by("[.id, .type]")' > /tmp/count-type-old.json
zcat "$NEW/$JSON" | jq -rc '. | {id: .id[0:2], type: .type}' | jq -cs 'group_by([.id, .type]) | [.[] | {id: .[0].id, type: .[0].type, length_new: length}] | sort_by("[.id, .type]")' > /tmp/count-type-new.json

# Stat sur les types par département avec les plus grosses différences
echo
echo "== Elements par types et départements, les plus grosses différences =="
echo
jq -cs 'map(map({key: (.id + .type), value: .}) | from_entries) | .[0] * .[1] | map(.) | .[] | select(.length_old and .length_new and .length_old != .length_new) | (. += { length_diff: (.length_new - .length_old), length_change: ((.length_new - .length_old) / .length_old) }) | select(.length_diff > 2)' /tmp/count-type-old.json /tmp/count-type-new.json | jq -cs 'sort_by(.length_change) | .[]' > /tmp/count-type-diff.json
head -n 20 /tmp/count-type-diff.json
tail -n 20 /tmp/count-type-diff.json
