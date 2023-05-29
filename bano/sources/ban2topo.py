from bano import db
from bano import models
from ..sql import sql_process,sql_get_data
from ..helpers import normalize,get_code_dept_from_insee
# from . import topo


def get_noms_ban(code_insee):
    return sql_get_data('noms_ban_non_rapproches_par_commune',dict(code_insee=code_insee))

def purge_noms_ban_dans_topo(code_insee):
    sql_process('purge_noms_ban_dans_topo',dict(code_insee=code_insee))

def add_noms_ban_dans_topo(code_insee,noms_ban):
    sql_process('add_noms_ban_dans_topo',dict(code_insee=code_insee,noms_ban=noms_ban))

def pseudo_fantoir(index,code_insee):
    return f"{code_insee}b{str(index).ljust(3,'b')}"

def process(code_insee,**kwargs):
    purge_noms_ban_dans_topo(code_insee)
    noms_ban = get_noms_ban(code_insee)
    if len(noms_ban) > 0:
        noms_ban_norm = set()
        topo = models.Topo(code_insee)
        dept = get_code_dept_from_insee(code_insee)
        for i,n in enumerate(noms_ban):
            nom_norm = normalize(n[0])
            if not nom_norm in topo.topo:
                noms_ban_norm.add(f"'{dept}','{code_insee}','{pseudo_fantoir(i,code_insee)}',' ','{nom_norm}','B','B','0000000'")
                print(f"'{dept}','{code_insee}','{pseudo_fantoir(i,code_insee)}',' ','{nom_norm}','B','B','0000000'")
        if len(noms_ban_norm)>0:
            add_noms_ban_dans_topo(code_insee, f"({'),('.join(noms_ban_norm)})")
