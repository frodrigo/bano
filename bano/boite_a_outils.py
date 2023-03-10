#!/usr/bin/env python
# coding: UTF-8

from .sql import sql_process
from . import batch as b


def maj_table_communes(**kwargs):
    batch_id = b.batch_start_log("maj_table_communes", "France", "France")
    try:
        sql_process("create_table_polygones_communes", dict())
        b.batch_stop_log(batch_id, True)
    except:
        b.batch_stop_log(batch_id, False)