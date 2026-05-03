"""Cross-check UC catalog against wikis + deploy-indexes:
  1. List every `main.*.gold_sql_dp_prod_we_*` table in UC
  2. For each: does it have a comment? does a wiki exist? is it in the deploy-index?
  3. Bucket into:
     - Deployed correctly (has comment, has wiki, in index marked Deployed)
     - In UC but no comment (the #5 answer — downstream UC mapped, no description)
     - In UC but no wiki (gap to fill from generic mapping)
     - Has wiki but UC table missing (stub-only or never deployed)
"""
from __future__ import annotations

import json
import os
import re
from collections import defaultdict
from pathlib import Path

from databricks import sql

REPO = Path(".")
WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"
GENERIC = WIKI_ROOT / "_generic_pipeline_mapping.json"


def collect_wiki_index() -> dict[str, dict[str, set[str]]]:
    """Return {schema_dir: {'tables_md_lc': set (lowercased), 'has_alter_lc': set,
    'has_uc_target_lc': set, 'tables_md_orig': set}}."""
    out: dict[str, dict[str, set[str]]] = {}
    for schema_dir in WIKI_ROOT.iterdir():
        if not schema_dir.is_dir():
            continue
        if schema_dir.name.startswith("_"):
            continue

        info = {
            "tables_md_lc": set(),
            "has_alter_lc": set(),
            "has_uc_target_lc": set(),
            "tables_md_orig": set(),
        }
        tables_dir = schema_dir / "Tables"
        if tables_dir.is_dir():
            for p in tables_dir.glob("*.md"):
                if ".review-needed" in p.name or ".lineage" in p.name:
                    continue
                info["tables_md_lc"].add(p.stem.lower())
                info["tables_md_orig"].add(p.stem)
        functions_dir = schema_dir / "Functions"
        if functions_dir.is_dir():
            for p in functions_dir.glob("*.md"):
                if ".review-needed" in p.name or ".lineage" in p.name:
                    continue
                info["tables_md_lc"].add(p.stem.lower())
                info["tables_md_orig"].add(p.stem)
        for a in schema_dir.rglob("*.alter.sql"):
            stem = a.name.removesuffix(".alter.sql")
            if ".downstream" in stem:
                continue
            info["has_alter_lc"].add(stem.lower())
            head = a.read_text(encoding="utf-8", errors="replace")[:500]
            if "_Not_Migrated" not in head and "no UC target" not in head.lower():
                info["has_uc_target_lc"].add(stem.lower())
        out[schema_dir.name] = info
    return out


def get_uc_gold_tables(cur) -> dict[str, dict]:
    """Return {fqn: {'comment': str|None, 'schema': str, 'table': str}} for every
    main.*.gold_sql_dp_prod_we_* table in UC."""
    cur.execute(
        """
        SELECT table_catalog, table_schema, table_name, comment
        FROM system.information_schema.tables
        WHERE table_catalog = 'main'
          AND table_name LIKE 'gold_sql_dp_prod_we_%'
        ORDER BY table_schema, table_name
        """
    )
    out = {}
    for cat, sch, tbl, cmt in cur.fetchall():
        fqn = f"{cat}.{sch}.{tbl}"
        out[fqn] = {
            "schema": sch,
            "table": tbl,
            "comment": (cmt or "").strip() or None,
        }
    return out


# Decode `gold_sql_dp_prod_we_<dwhdb>_<dwhsch>_<table>` -> (dwhdb, dwhsch, table)
GOLD_RE = re.compile(r"^gold_sql_dp_prod_we_(.+)$")


def decode_gold_name(table_name: str, wiki_index: dict) -> tuple[str | None, str | None]:
    m = GOLD_RE.match(table_name)
    if not m:
        return None, None
    rest = m.group(1)
    # Try to match against a known schema dir (lowercased) - <schema>_<rest>
    for schema_dir in wiki_index:
        prefix = schema_dir.lower() + "_"
        if rest.startswith(prefix):
            stem = rest[len(prefix):]
            return schema_dir, stem
    return None, rest


def main() -> int:
    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME",
        "adb-5142916747090026.6.azuredatabricks.net",
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = os.environ.get("DATABRICKS_TOKEN")

    print("Connecting to Databricks...", flush=True)
    if token:
        conn = sql.connect(
            server_hostname=host, http_path=http_path, access_token=token
        )
    else:
        conn = sql.connect(
            server_hostname=host, http_path=http_path, auth_type="databricks-oauth"
        )
    cur = conn.cursor()

    print("Loading wiki index...", flush=True)
    wiki = collect_wiki_index()
    for sd, info in sorted(wiki.items()):
        if info["tables_md_lc"]:
            print(
                f"  {sd:25s}  md={len(info['tables_md_lc']):4d}  "
                f"alter={len(info['has_alter_lc']):4d}  "
                f"uc_target={len(info['has_uc_target_lc']):4d}"
            )

    print("\nQuerying UC for gold_sql_dp_prod_we_* tables...", flush=True)
    uc = get_uc_gold_tables(cur)
    print(f"  Found {len(uc)} gold tables in UC", flush=True)

    cur.close()
    conn.close()

    # Cross-reference
    print("\n=== Per-DWH-schema breakdown (UC gold layer) ===")
    by_schema = defaultdict(list)
    for fqn, info in uc.items():
        dwh_dir, stem = decode_gold_name(info["table"], wiki)
        by_schema[dwh_dir or "(unmapped)"].append((fqn, info, stem))

    print(
        f"  {'dwh_schema':25s}  {'uc_count':>9s}  {'has_cmt':>8s}  "
        f"{'no_cmt':>7s}  {'wiki_match':>10s}  {'no_wiki':>8s}"
    )
    for sd in sorted(by_schema):
        rows = by_schema[sd]
        has_cmt = sum(1 for _, info, _ in rows if info["comment"])
        no_cmt = sum(1 for _, info, _ in rows if not info["comment"])
        if sd == "(unmapped)":
            wiki_hit = no_wiki = 0
        else:
            md_set = wiki.get(sd, {}).get("tables_md_lc", set())
            wiki_hit = sum(1 for _, _, stem in rows if stem and stem.lower() in md_set)
            no_wiki = sum(
                1 for _, _, stem in rows if not stem or stem.lower() not in md_set
            )
        print(
            f"  {sd:25s}  {len(rows):>9d}  {has_cmt:>8d}  "
            f"{no_cmt:>7d}  {wiki_hit:>10d}  {no_wiki:>8d}"
        )

    print("\n=== Question 5 answer: UC mapped, downstream WITHOUT description ===")
    no_cmt_total = 0
    samples: list[tuple[str, str, str | None]] = []
    by_schema_no_cmt = defaultdict(int)
    for fqn, info in uc.items():
        if not info["comment"]:
            no_cmt_total += 1
            dwh_dir, stem = decode_gold_name(info["table"], wiki)
            by_schema_no_cmt[dwh_dir or "(unmapped)"] += 1
            if len(samples) < 10:
                samples.append((fqn, dwh_dir or "?", stem))
    print(f"  Total UC gold tables WITHOUT a comment: {no_cmt_total} of {len(uc)}")
    print(f"  By DWH schema:")
    for sd, n in sorted(by_schema_no_cmt.items(), key=lambda x: -x[1]):
        print(f"    {sd:25s}  {n}")
    print(f"  First 10 samples:")
    for fqn, sd, stem in samples:
        print(f"    {fqn}  -> wiki dir={sd}  stem={stem}")

    print("\n=== BI_DB_dbo deep-dive (case-insensitive matching) ===")
    sd = "BI_DB_dbo"
    md_set = wiki.get(sd, {}).get("tables_md_lc", set())
    has_uc = wiki.get(sd, {}).get("has_uc_target_lc", set())
    rows = by_schema.get(sd, [])
    in_uc_stems_lc = {stem.lower() for _, _, stem in rows if stem}
    in_uc_with_comment_lc = {
        stem.lower() for _, info, stem in rows if stem and info["comment"]
    }
    in_uc_without_comment_lc = in_uc_stems_lc - in_uc_with_comment_lc

    wiki_only_no_uc = md_set - in_uc_stems_lc
    uc_only_no_wiki = in_uc_stems_lc - md_set

    print(f"  Wiki .md files:                                  {len(md_set)}")
    print(f"  UC gold tables for BI_DB_dbo:                    {len(in_uc_stems_lc)}")
    print(f"  UC gold WITH comment:                            {len(in_uc_with_comment_lc)}")
    print(f"  UC gold WITHOUT comment (alter never deployed):  {len(in_uc_without_comment_lc)}")
    print(f"  Wikis WITH matching UC table:                    {len(md_set & in_uc_stems_lc)}")
    print(f"  Wikis WITHOUT matching UC table (Synapse-only):  {len(wiki_only_no_uc)}")
    print(f"  UC gold tables WITHOUT a wiki:                   {len(uc_only_no_wiki)}")
    print(f"  Wikis with deployable .alter.sql (UC target):    {len(has_uc)}")
    print()
    print(f"  -- ACTIONABLE: 'UC gold WITHOUT comment AND wiki exists' --")
    can_deploy_now = in_uc_without_comment_lc & md_set
    print(f"  Count: {len(can_deploy_now)}")
    for s in sorted(can_deploy_now)[:25]:
        print(f"    {s}")
    print()
    print(f"  -- 'UC gold WITHOUT wiki' (need wiki gen first) --")
    print(f"  Count: {len(uc_only_no_wiki)}")
    for s in sorted(uc_only_no_wiki)[:15]:
        print(f"    {s}")

    # Re-tabulate the question-5 answer with case-insensitive matching
    print("\n=== Question 5 (refined): 'UC mapped, no description' AND 'wiki exists' ===")
    print("    (these are the immediately-deployable misses across all DWH schemas)")
    print(
        f"  {'dwh_schema':25s}  {'uc_no_cmt':>10s}  {'wiki_exists':>11s}  "
        f"{'wiki_missing':>13s}"
    )
    grand = 0
    for schema_dir, rows_ in sorted(by_schema.items()):
        if schema_dir == "(unmapped)":
            continue
        md_set_ = wiki.get(schema_dir, {}).get("tables_md_lc", set())
        no_cmt = [(stem, fqn) for fqn, info, stem in rows_ if not info["comment"] and stem]
        with_wiki = [s for s, _ in no_cmt if s.lower() in md_set_]
        no_wiki = [s for s, _ in no_cmt if s.lower() not in md_set_]
        if no_cmt:
            grand += len(with_wiki)
            print(
                f"  {schema_dir:25s}  {len(no_cmt):>10d}  {len(with_wiki):>11d}  "
                f"{len(no_wiki):>13d}"
            )
    print(f"\n  TOTAL with wiki ready (deployable now): {grand}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
