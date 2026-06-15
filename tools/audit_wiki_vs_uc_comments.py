"""Audit: which generic-pipeline-mapped Synapse tables have a wiki MD but
NO (or near-zero) UC comments?

Cross-references three sources:
  1. `_generic_pipeline_mapping.json` — the universe of tables landed in UC
     by the generic pipeline (1906 mappings, all source DBs).
  2. `knowledge/synapse/Wiki/<schema>/Tables|Views/<name>.md` — wiki MDs.
  3. `main.information_schema.tables` + `main.information_schema.columns`
     — live UC comment state (bulk single query).

Output: `tools/lakebridge/wiki_vs_uc_coverage.csv` with one row per
(schema, table) that has a wiki MD AND is in the generic mapping, scored
by UC comment coverage. Stdout summary highlights the worst gaps.

Buckets:
  * MISSING_IN_UC      — UC table doesn't exist (mapping says it should)
  * NO_COMMENTS_AT_ALL — UC table exists, 0/N cols have comments AND
                         table-level comment is empty
  * NO_TABLE_COMMENT   — cols are commented but table-level comment empty
  * LOW_COL_COVERAGE   — <30% of cols commented
  * OK                 — >=30% col coverage AND table comment set

Usage:
  python tools/audit_wiki_vs_uc_comments.py
  python tools/audit_wiki_vs_uc_comments.py --schemas BI_DB_dbo DWH_dbo
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"
MAP_JSON = WIKI / "_generic_pipeline_mapping.json"
OUT_CSV = REPO / "tools" / "lakebridge" / "wiki_vs_uc_coverage.csv"


def index_wikis() -> dict[tuple[str, str], tuple[Path, str]]:
    """Return {(schema_folder, table_name): (md_path, 'Tables'|'Views')}."""
    out: dict[tuple[str, str], tuple[Path, str]] = {}
    for sch_dir in sorted(WIKI.iterdir()):
        if not sch_dir.is_dir() or sch_dir.name.startswith("_") or sch_dir.name == "__pycache__":
            continue
        for sub in ("Tables", "Views"):
            d = sch_dir / sub
            if not d.exists():
                continue
            for md in d.glob("*.md"):
                if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
                    continue
                if md.name.startswith("_"):
                    continue
                out[(sch_dir.name, md.stem)] = (md, sub)
    return out


def index_mappings() -> dict[tuple[str, str], dict]:
    """Return {(schema_name, table_name): mapping_dict}. Mapping schema_name
    already matches wiki folder name (e.g. 'BI_DB_dbo')."""
    raw = json.loads(MAP_JSON.read_text(encoding="utf-8"))
    out: dict[tuple[str, str], dict] = {}
    for m in raw.get("mappings", []):
        sch = (m.get("schema_name") or "").strip()
        tbl = (m.get("table_name") or "").strip()
        if not sch or not tbl:
            continue
        key = (sch, tbl)
        # If duplicated, keep the first (sql_dp_prod_we is canonical for the
        # DWH/BI_DB families; mapping order tends to put canonical first).
        out.setdefault(key, m)
    return out


def split_uc(uc_table_raw: str) -> tuple[str, str, str]:
    """Normalize UC fully-qualified name to (catalog, schema, table) lower."""
    t = uc_table_raw.strip().lstrip("`").rstrip("`")
    parts = t.split(".")
    if len(parts) == 2:
        cat, tbl = parts
        sch = cat
        cat = "main"  # mapping omits catalog for non-pii_data targets
    elif len(parts) == 3:
        cat, sch, tbl = parts
    else:
        return ("", "", "")
    return (cat.lower(), sch.lower(), tbl.lower())


def alter_exists(schema_dir: str, name: str, sub: str) -> bool:
    return (WIKI / schema_dir / sub / f"{name}.alter.sql").is_file()


def fetch_uc_coverage(uc_targets: list[tuple[str, str, str]]) -> dict[tuple[str, str, str], dict]:
    """One bulk query for table-level + per-column comment coverage."""
    if not uc_targets:
        return {}
    sys.path.insert(0, str(REPO / "tools"))
    from databricks import sql

    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net"
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    print(f"Connecting to Databricks (cataloging {len(uc_targets)} UC targets)...", flush=True)
    if token:
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
    cur = conn.cursor()

    # Distinct schemas across targets — query per schema to bound result size.
    by_schema: dict[tuple[str, str], set[str]] = defaultdict(set)
    for cat, sch, tbl in uc_targets:
        by_schema[(cat, sch)].add(tbl)

    out: dict[tuple[str, str, str], dict] = {}
    for (cat, sch), tbls in by_schema.items():
        # Table-level comments
        cur.execute(
            f"SELECT lower(table_name) AS t, comment "
            f"FROM {cat}.information_schema.tables "
            f"WHERE table_schema = '{sch}'"
        )
        tbl_comments: dict[str, str] = {row[0]: (row[1] or "") for row in cur.fetchall()}
        # Per-column counts
        cur.execute(
            f"SELECT lower(table_name) AS t, "
            f"COUNT(*) AS total_cols, "
            f"SUM(CASE WHEN comment IS NULL OR comment = '' THEN 0 ELSE 1 END) AS commented_cols, "
            f"SUM(CASE WHEN comment IN ('T0','T1','T2','T3','T4') THEN 1 ELSE 0 END) AS tier_drift_cols "
            f"FROM {cat}.information_schema.columns "
            f"WHERE table_schema = '{sch}' "
            f"GROUP BY lower(table_name)"
        )
        col_stats: dict[str, tuple[int, int, int]] = {
            row[0]: (int(row[1] or 0), int(row[2] or 0), int(row[3] or 0))
            for row in cur.fetchall()
        }
        for tbl in tbls:
            present = tbl in col_stats
            total, commented, tier = col_stats.get(tbl, (0, 0, 0))
            out[(cat, sch, tbl)] = {
                "exists": present,
                "table_comment": tbl_comments.get(tbl, ""),
                "total_cols": total,
                "commented_cols": commented,
                "tier_drift_cols": tier,
            }
        print(f"  {cat}.{sch}: {len(tbls)} targets, {sum(1 for t in tbls if t in col_stats)} found in UC", flush=True)
    cur.close()
    conn.close()
    return out


def classify(uc: dict, mapped: bool, wiki_exists: bool) -> str:
    if not uc["exists"]:
        return "MISSING_IN_UC"
    total = uc["total_cols"]
    commented = uc["commented_cols"]
    tbl_c = (uc["table_comment"] or "").strip()
    if total == 0:
        return "NO_COLUMNS_IN_UC"  # extremely rare; defensive
    if commented == 0 and not tbl_c:
        return "NO_COMMENTS_AT_ALL"
    if commented == 0 and tbl_c:
        return "ONLY_TABLE_COMMENT"
    if commented < total and (commented / total) < 0.30:
        return "LOW_COL_COVERAGE"
    if commented >= total * 0.30 and not tbl_c:
        return "NO_TABLE_COMMENT"
    return "OK"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schemas", nargs="*", help="Limit to specific wiki schemas")
    ap.add_argument("--skip-uc", action="store_true",
                    help="Skip live UC query (for layout debugging only)")
    args = ap.parse_args()

    wikis = index_wikis()
    mappings = index_mappings()

    if args.schemas:
        keep = set(args.schemas)
        wikis = {k: v for k, v in wikis.items() if k[0] in keep}

    pairs: list[tuple[str, str, Path, str, dict]] = []
    no_mapping_count = 0
    for (sch, name), (md, sub) in sorted(wikis.items()):
        m = mappings.get((sch, name))
        if not m:
            no_mapping_count += 1
            continue
        pairs.append((sch, name, md, sub, m))
    print(f"Wiki MDs found: {len(wikis)}")
    print(f"  of which generic-pipeline mapped: {len(pairs)}")
    print(f"  of which NOT in generic mapping (custom pipeline / standalone): {no_mapping_count}")

    # Build UC target list (one per pair).
    uc_targets: list[tuple[str, str, str]] = []
    pair_uc: dict[int, tuple[str, str, str]] = {}
    for i, (_sch, _name, _md, _sub, m) in enumerate(pairs):
        cat, sch_l, tbl_l = split_uc(m.get("uc_table", ""))
        if not tbl_l:
            continue
        uc_targets.append((cat, sch_l, tbl_l))
        pair_uc[i] = (cat, sch_l, tbl_l)
    # Deduplicate while preserving order
    uc_targets = list({t: None for t in uc_targets})

    if args.skip_uc:
        print("\n--skip-uc set, leaving out live UC coverage. Counting layout only.")
        cov = {}
    else:
        cov = fetch_uc_coverage(uc_targets)

    rows = []
    bucket_counts = Counter()
    for i, (sch, name, md, sub, m) in enumerate(pairs):
        key = pair_uc.get(i)
        if not key:
            uc_state = {"exists": False, "table_comment": "", "total_cols": 0, "commented_cols": 0, "tier_drift_cols": 0}
            uc_full = ""
        else:
            uc_state = cov.get(key, {"exists": False, "table_comment": "", "total_cols": 0, "commented_cols": 0, "tier_drift_cols": 0})
            uc_full = f"{key[0]}.{key[1]}.{key[2]}"
        bucket = classify(uc_state, mapped=True, wiki_exists=True)
        bucket_counts[bucket] += 1
        rows.append({
            "schema_folder": sch,
            "object_name": name,
            "object_kind": sub.rstrip("s"),
            "wiki_md": md.relative_to(REPO).as_posix(),
            "wiki_alter_exists": "yes" if alter_exists(sch, name, sub) else "no",
            "uc_table": uc_full,
            "uc_exists": "yes" if uc_state["exists"] else "no",
            "uc_table_comment_set": "yes" if (uc_state["table_comment"] or "").strip() else "no",
            "uc_total_cols": uc_state["total_cols"],
            "uc_commented_cols": uc_state["commented_cols"],
            "uc_tier_drift_cols": uc_state["tier_drift_cols"],
            "uc_col_coverage_pct": (
                round(100 * uc_state["commented_cols"] / uc_state["total_cols"], 1)
                if uc_state["total_cols"] else 0.0
            ),
            "bucket": bucket,
        })

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    print()
    print("=" * 72)
    print(f"Audit complete. Detail CSV: {OUT_CSV.relative_to(REPO).as_posix()}")
    print()
    print("Buckets:")
    for b, n in bucket_counts.most_common():
        print(f"  {b:<22s} {n:>5d}")
    print()
    # Highlight the gap targets
    target_buckets = ("MISSING_IN_UC", "NO_COMMENTS_AT_ALL", "ONLY_TABLE_COMMENT", "LOW_COL_COVERAGE", "NO_TABLE_COMMENT")
    print(f"Gap rows by schema (buckets: {', '.join(target_buckets)}):")
    by_sch_bucket = defaultdict(Counter)
    for r in rows:
        if r["bucket"] in target_buckets:
            by_sch_bucket[r["schema_folder"]][r["bucket"]] += 1
    for sch in sorted(by_sch_bucket):
        parts = ", ".join(f"{b}={n}" for b, n in by_sch_bucket[sch].most_common())
        print(f"  {sch:<20s} {parts}")
    print()
    # First 15 of the worst-offender bucket (NO_COMMENTS_AT_ALL — wiki exists but UC table truly bare)
    worst = [r for r in rows if r["bucket"] == "NO_COMMENTS_AT_ALL"]
    if worst:
        print(f"Worst gaps (NO_COMMENTS_AT_ALL: wiki exists but UC has 0 col comments and no table comment). First 20:")
        for r in sorted(worst, key=lambda x: (-x["uc_total_cols"], x["uc_table"]))[:20]:
            print(f"  [{r['uc_total_cols']:>3d} cols] {r['uc_table']:<70s} ({r['wiki_md']})")


if __name__ == "__main__":
    main()
