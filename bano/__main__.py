#!/usr/bin/env python
# coding: UTF-8

import argparse
import sys

from . import pre_process_suffixe
from . import setup_db
from . import rapprochement
from . import boite_a_outils
from . import export
from . import publish
from . import pifometre
from .sources import ban, cog, cadastre_ld, cadastre_communes, ban2topo, datagouv_commune_summary as datagouv_cs,datagouv_cp,datagouv_cp,datagouv_topo
from .constants import DEPARTEMENTS


def main():
    parser = argparse.ArgumentParser(
        prog="bano", description="Donne accès à tous les traitements"
    )
    subparsers = parser.add_subparsers(help="Commandes disponibles")

    subparser = subparsers.add_parser(
        "setup_db",
        help="Initialisation de la BD BANO",
    )
    subparser.set_defaults(func=setup_db.setup_bano)

    subparser = subparsers.add_parser(
        "charge_topo_sas",
        help="Charge une version du fichier TOPO",
    )
    subparser.add_argument(
        "--version", type=str, help="Version de TOPO pour nommage du fichier téléchargé"
    )
    subparser.add_argument(
        "--forcedownload", "-fd",
        action='store_true',
        help="Forcer le téléchargement"
    )
    subparser.add_argument(
        "--forceload", "-fl",
        action='store_true',
        help="Forcer le re-chargement en base même sans téléchargement"
    )
    subparser.set_defaults(func=datagouv_topo.process)

    subparser = subparsers.add_parser(
        "publish_topo",
        help="Bascule la version de TOPO au profit de celle dans le sas",
    )
    subparser.set_defaults(func=datagouv_topo.publish)

    subparser = subparsers.add_parser(
        "charge_cog",
        help="Charge une version des fichiers COG",
    )
    subparser.add_argument(
        "--forceload", "-f",
        action='store_true',
        help="Forcer le re-chargement en base même sans téléchargement"
    )
    subparser.set_defaults(func=cog.process_cog)

    subparser = subparsers.add_parser(
        "charge_cp",
        help="Charge une version du fichier Codes Postaux",
    )
    subparser.add_argument(
        "--forceload", "-f",
        action='store_true',
        help="Forcer le re-chargement en base même sans téléchargement"
    )
    subparser.set_defaults(func=datagouv_cp.process)

    subparser = subparsers.add_parser(
        "charge_ban",
        help="Charge une version des fichiers BAN",
    )
    subparser.add_argument(
        "--forceload", "-f",
        action='store_true',
        help="Forcer le re-chargement en base même sans téléchargement"
    )
    subparser.add_argument(
        "departements",
        type=str,
        help="Départements à traiter",
        nargs="*",
        default=DEPARTEMENTS,
    )
    subparser.set_defaults(func=ban.process_ban)

    subparser = subparsers.add_parser(
        "charge_ld_cadastre",
        help="Charge une version des lieux-dits du Cadastre JSON",
        description="Charge une version des lieux-dits du Cadastre JSON",
    )
    subparser.add_argument(
        "--forceload", "-f",
        action='store_true',
        help="Forcer le re-chargement en base même sans téléchargement"
    )
    subparser.add_argument(
        "departements",
        type=str,
        help="Départements à traiter",
        nargs="*",
        default=DEPARTEMENTS,
    )
    subparser.set_defaults(func=cadastre_ld.process)

    subparser = subparsers.add_parser(
        "charge_communes_cadastre",
        help="Charge une version des contours de commune du Cadastre JSON",
        description="Charge une version des contours de commune du Cadastre JSON",
    )
    subparser.add_argument(
        "--forceload", "-f",
        action='store_true',
        help="Forcer le re-chargement en base même sans téléchargement"
    )
    subparser.add_argument(
        "departements",
        type=str,
        help="Départements à traiter",
        nargs="*",
        default=DEPARTEMENTS,
    )
    subparser.set_defaults(func=cadastre_communes.process)

    subparser = subparsers.add_parser(
        "download_commune_summary",
        help="Met à jour les stats de BAL",
        description="Met à jour les stats de BAL",
    )
    subparser.add_argument(
        "--forceload", "-f",
        action='store_true',
        help="Forcer le re-chargement en base même sans téléchargement"
    )
    subparser.set_defaults(func=datagouv_cs.process)

    subparser = subparsers.add_parser(
        "menage_noms_ban",
        help="Nettoyage des noms BAN",
    )
    subparser.set_defaults(func=ban.menage_noms_ban)

    subparser = subparsers.add_parser(
        "update_bis_table",
        help="Identifie les indices de répétition b,t,q assimilables à bis, ter, quater",
    )
    subparser.set_defaults(func=ban.update_bis_table)

    subparser = subparsers.add_parser(
        "update_table_communes",
        help="Met à jour les polygones administratifs OSM",
    )
    subparser.set_defaults(func=boite_a_outils.maj_table_communes)

    subparser = subparsers.add_parser(
        "update_stats_departementales",
        help="Met à jour les stats departementales BAN/BANO/TOPO",
    )
    subparser.set_defaults(func=boite_a_outils.update_stats_departementales)

    subparser = subparsers.add_parser(
        "pre_process_suffixe",
        help="Détermine les zones où les noms dans le Cadastre sont suffixés",
    )
    subparser.add_argument(
        "departements",
        type=str,
        help="Départements à traiter",
        nargs="*",
        default=DEPARTEMENTS,
    )
    subparser.set_defaults(func=pre_process_suffixe.process)

    subparser = subparsers.add_parser(
        "rapprochement",
        help="Effectue l'appariement entre sources OSM ou BAN et TOPO",
    )
    group = subparser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--code_insee", type=str, help="Code INSEE de la commune à traiter"
    )
    group.add_argument(
        "--dept",
        type=str,
        help="Département à traiter (toutes les communes du dept sont traitées une par une)",
    )
    subparser.add_argument(
        "--verbose", "-v",
        action='store_true',
        help="Mode verbose - debug"
    )
    subparser.add_argument(
        "--source_pifometre", "-p",
        action='store_true',
        help="Marque les rapprochements commandés par Pifometre"
    )
    subparser.set_defaults(func=rapprochement.process)

    subparser = subparsers.add_parser(
        "ban2topo",
        help="Ajoute dans TOPO des libellés BAN",
        description="Ajoute dans TOPO des libellés BAN"
    )
    subparser.add_argument(
        "--code_insee", type=str, help="Code INSEE de la commune à traiter"
    )
    subparser.set_defaults(func=ban2topo.process)

    subparser = subparsers.add_parser(
        "update_infos_communes",
        help="Màj de la table infos_communes pour les exports JSON",
    )
    subparser.set_defaults(func=boite_a_outils.update_infos_communes)

    subparser = subparsers.add_parser(
        "prepare_export",
        help="Calculs en prévision des exports",
        description="Calculs en prévision des exports",
    )
    subparser.set_defaults(func=export.prepare_export)

    subparser = subparsers.add_parser(
        "export",
        help="Export par département dans différents formats",
        description="Export par département dans différents formats",
    )
    subparser.add_argument(
        "departements",
        type=str,
        help="Départements à traiter",
        nargs="*",
        default=DEPARTEMENTS,
    )
    subparser.set_defaults(func=export.process)

    subparser = subparsers.add_parser(
        "publish",
        help="Publication des exports dans le dossier web de https://bano.openstreetmap.fr/data - fichiers par département",
        description="Publication des exports dans le dossier web de https://bano.openstreetmap.fr/data - fichiers par département",
    )
    subparser.add_argument(
        "departements",
        type=str,
        help="Départements à traiter",
        nargs="*",
        default=DEPARTEMENTS,
    )
    subparser.set_defaults(func=publish.process)

    subparser = subparsers.add_parser(
        "publish_aggregate",
        help="Publication des exports dans un dossier web - fichiers France entière",
        description="Publication des exports dans un dossier web - fichiers France entière",
    )
    subparser.set_defaults(func=publish.process_full)

    subparser = subparsers.add_parser(
        "croisement_voies_limites",
        help="Identifie les voies nommées croisant les limites communales",
    )
    subparser.add_argument(
        "departement",
        type=str,
        help="Département à traiter",
    )
    subparser.set_defaults(func=pifometre.process_croisement_voies_limites)

    args = parser.parse_args()

    # try:
    args.func(**vars(args))
    # except ValueError as err:
    #     sys.exit(str(err))
    # except TypeError as err:
    #     import ipdb

    #     ipdb.set_trace()


if __name__ == "__main__":
    main()
