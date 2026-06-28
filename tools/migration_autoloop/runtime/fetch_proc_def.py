#!/usr/bin/env python3
"""Fetch a routine_definition and write it to a UTF-8 file (no shell redirection)."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def fetch_def(schema: str, name: str) -> str:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    sql = (
        "SELECT routine_definition FROM dwh_daily_process.information_schema.routines "
        f"WHERE specific_schema='{schema}' AND routine_name='{name}'"
    )
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    if not rows:
        return ""
    return rows[0][0] or ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema", default="migration_tables")
    ap.add_argument("--name", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    txt = fetch_def(args.schema, args.name)
    Path(args.out).write_text(txt, encoding="utf-8")
    print(f"LEN={len(txt)} -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
