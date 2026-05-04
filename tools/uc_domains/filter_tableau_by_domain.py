#!/usr/bin/env python3
"""
Phase 3 — Tableau Discovery wrapper.

Drive the existing tools/tableau/extract_table_metadata.py over an entire
acquired-company domain in one batch, then read the resulting global Tableau
index CSVs and emit a domain-scoped tableau_index.json that P5 can read.

Usage:
  python tools/uc_domains/filter_tableau_by_domain.py \
      --domain spaceship \
      --inventory knowledge/uc_domains/spaceship/_discovery/uc_inventory.json \
      --out knowledge/uc_domains/spaceship/_discovery/tableau_index.json

Optional flags:
  --skip-extractor       Don't re-run the Tableau extractor; just re-read the CSVs.
                         Use for re-aggregation after a previous extraction run.
  --tables-only-views    Only ask Tableau for views (skip raw bronze tables) — usually
                         what you want for an initial pass since raw bronze tables
                         rarely show up in Tableau directly.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from collections import defaultdict


REPO = Path(__file__).resolve().parent.parent.parent
TABLEAU_INDEX = REPO / "knowledge" / "tableau" / "_index"


def load_inventory(path: Path) -> tuple[list[str], dict[str, str]]:
    """Return (sorted unique table names, table_name -> full_name).

    full_name is `catalog.schema.table` from UC inventory; we use it later to
    disambiguate when multiple tables share a name.
    """
    inv = json.loads(path.read_text(encoding="utf-8"))
    out: dict[str, str] = {}
    for sd in inv["schemas"].values():
        for o in sd["objects"]:
            out.setdefault(o["name"], o["full_name"])
    return sorted(out), out


def run_extractor(table_names: list[str], cwd: Path) -> int:
    if not table_names:
        return 0
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as f:
        for n in table_names:
            f.write(n + "\n")
        listfile = f.name
    cmd = [
        sys.executable, "-u",
        str(cwd / "tools" / "tableau" / "extract_table_metadata.py"),
        "--tables-file", listfile,
    ]
    print(f"[tableau] running extractor over {len(table_names)} table names", file=sys.stderr)
    try:
        rc = subprocess.run(cmd, cwd=cwd).returncode
    finally:
        try:
            os.unlink(listfile)
        except OSError:
            pass
    return rc


def read_csv(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def schema_qualifier_matches_domain(table_full_name: str, our_full_name: str) -> bool:
    """`table_full_name` is the existing Tableau-side qualifier (e.g.
    `BI_DB_dbo.X` for Synapse, or `etoro_kpi.v_spaceship_fees` for UC).

    Strategy: accept if EITHER (a) the schema in the Tableau row is the same
    as the schema we have in UC inventory, OR (b) the Tableau qualifier has
    no schema-prefix (some workbooks just store the bare table name)."""
    if not table_full_name:
        return False
    # take last two segments
    parts = table_full_name.split(".")
    if len(parts) < 2:
        return True  # bare name — accept
    tbl_schema = parts[-2]
    our_parts = our_full_name.split(".")
    our_schema = our_parts[-2] if len(our_parts) >= 2 else ""
    return tbl_schema.lower() == our_schema.lower()


def aggregate(domain_names: dict[str, str]) -> dict:
    """Read existing _index CSVs and aggregate hits per UC full_name.

    domain_names: bare_name -> catalog.schema.table.
    """
    workbooks_rows = read_csv(TABLEAU_INDEX / "workbooks.csv")
    custom_sql_rows = read_csv(TABLEAU_INDEX / "custom_sql.csv")
    calc_fields_rows = read_csv(TABLEAU_INDEX / "calc_fields.csv")

    out: dict[str, dict] = {full: {"workbooks": [], "custom_sql": [], "calc_fields": []}
                           for full in set(domain_names.values())}

    seen_workbook_pairs: set[tuple[str, str]] = set()
    for r in workbooks_rows:
        bare = (r.get("table") or "").strip()
        full = domain_names.get(bare)
        if not full:
            continue
        if not schema_qualifier_matches_domain(r.get("table_full_name", ""), full):
            continue
        wid = r.get("workbook_id", "")
        key = (full, wid)
        if key in seen_workbook_pairs:
            continue
        seen_workbook_pairs.add(key)
        out[full]["workbooks"].append({
            "id": wid,
            "name": r.get("workbook_name", ""),
            "project": r.get("project", ""),
            "owner": r.get("owner", ""),
            "updated_at": r.get("updated_at", ""),
        })

    for r in custom_sql_rows:
        bare = (r.get("table") or "").strip()
        full = domain_names.get(bare)
        if not full:
            continue
        if not schema_qualifier_matches_domain(r.get("table_full_name", ""), full):
            continue
        out[full]["custom_sql"].append({
            "query_id": r.get("query_id", ""),
            "name": r.get("query_name", ""),
            "chars": int(r.get("query_chars") or 0),
        })

    for r in calc_fields_rows:
        bare = (r.get("table") or "").strip()
        full = domain_names.get(bare)
        if not full:
            continue
        if not schema_qualifier_matches_domain(r.get("table_full_name", ""), full):
            continue
        out[full]["calc_fields"].append({
            "field_name": r.get("field_name", ""),
            "workbook": r.get("workbook", ""),
            "datasource": r.get("datasource", ""),
            "formula_chars": int(r.get("formula_chars") or 0),
        })

    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Domain-scoped Tableau discovery wrapper")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--inventory", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--skip-extractor", action="store_true",
                    help="Skip re-running the Tableau extractor")
    ap.add_argument("--tables-only-views", action="store_true",
                    help="Only feed VIEW-type objects to the extractor")
    args = ap.parse_args()

    inv_path = Path(args.inventory)
    bare_names, full_map = load_inventory(inv_path)

    if args.tables_only_views:
        inv = json.loads(inv_path.read_text(encoding="utf-8"))
        view_names = set()
        for sd in inv["schemas"].values():
            for o in sd["objects"]:
                if "VIEW" in (o["table_type"] or "").upper():
                    view_names.add(o["name"])
        bare_names = sorted(view_names)
        print(f"[tableau] views-only mode: {len(bare_names)} names", file=sys.stderr)

    if not args.skip_extractor:
        rc = run_extractor(bare_names, REPO)
        if rc != 0:
            print(f"[tableau] extractor exited rc={rc}; aggregating what's already in CSVs",
                  file=sys.stderr)

    objects = aggregate(full_map)

    # Filter again to keep only the ones we asked about (views-only mode trimmed bare_names).
    if args.tables_only_views:
        objects = {full: v for full, v in objects.items()
                   if full.split(".")[-1] in bare_names}

    stats = {
        "objects_total": len(objects),
        "objects_with_workbook_hits": sum(1 for v in objects.values() if v["workbooks"]),
        "workbook_hits_total": sum(len(v["workbooks"]) for v in objects.values()),
        "custom_sql_hits_total": sum(len(v["custom_sql"]) for v in objects.values()),
        "calc_field_hits_total": sum(len(v["calc_fields"]) for v in objects.values()),
    }

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "domain": args.domain,
        "generated_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "inventory_source": str(inv_path),
        "objects": objects,
        "stats": stats,
    }
    out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[tableau] wrote {out_path} (objects={stats['objects_total']}, "
          f"workbook_hits={stats['workbook_hits_total']}, "
          f"custom_sql={stats['custom_sql_hits_total']}, "
          f"calc_fields={stats['calc_field_hits_total']})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
