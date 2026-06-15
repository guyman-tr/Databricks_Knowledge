"""Audit: every wiki MD file in the repo vs live UC comment coverage.

Discovers four wiki sources and resolves each to a UC table where possible:

  1. SYNAPSE        — knowledge/synapse/Wiki/<DBSchema>/<Tables|Views>/<name>.md
                      Match: schema_name=<DBSchema>, table_name=<name> in
                      _generic_pipeline_mapping.json.
  2. PRODSCHEMAS    — knowledge/ProdSchemas/<group>/<DB>/Wiki/<schema>/
                      <Tables|Views>/<schema>.<name>.md   (Tier 1 / Bonnie)
                      Match: database_name=<DB>, schema_name=<schema>,
                      table_name=<name> in mapping. Lands in bronze/silver UC.
  3. UC_GENERATED   — knowledge/UC_generated/<schema>/<Tables|Views>/<name>.md
                      UC target = main.<schema>.<name> directly (no mapping
                      lookup — these are already-in-UC canonical objects).
  4. UC_DOMAINS     — knowledge/uc_domains/<domain>/... (skipped — these are
                      domain narratives, not per-table docs).

For each (md, uc_target) pair, queries UC information_schema for column
comment coverage and table-level comment, then classifies into buckets:

  * NOT_MAPPED          — no UC mapping resolvable from the wiki path
  * MISSING_IN_UC       — mapping points to UC table that doesn't exist
  * NO_COMMENTS_AT_ALL  — UC exists, 0 col comments AND no table comment
  * ONLY_TABLE_COMMENT  — col comments empty, table-level comment set
  * LOW_COL_COVERAGE    — <30 percent col coverage
  * NO_TABLE_COMMENT    — >=30 percent col coverage but table comment empty
  * OK                  — >=30 percent col coverage AND table comment set

Output: tools/lakebridge/wiki_vs_uc_all_sources.csv (full join table).
Stdout: summary by source + worst-gap previews.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
KNOWLEDGE = REPO / "knowledge"
WIKI_SYNAPSE = KNOWLEDGE / "synapse" / "Wiki"
WIKI_PROD = KNOWLEDGE / "ProdSchemas"
WIKI_UC = KNOWLEDGE / "UC_generated"
MAP_JSON = WIKI_SYNAPSE / "_generic_pipeline_mapping.json"
OUT_CSV = REPO / "tools" / "lakebridge" / "wiki_vs_uc_all_sources.csv"

SKIP_FILE_NAMES = {"_glossary.md", "_index.md"}
SKIP_FOLDERS = {"Stored Procedures", "User Defined Types", "Functions"}


def _is_dataset_md(md: Path) -> bool:
    """Return True for table/view wikis (skip narrative, glossary, SP docs)."""
    if md.name in SKIP_FILE_NAMES or md.name.startswith("_"):
        return False
    if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
        return False
    parts = set(md.parts)
    if parts & SKIP_FOLDERS:
        return False
    return True


# ----------------------------- discovery -----------------------------

def discover_synapse() -> list[dict]:
    """Wiki files under knowledge/synapse/Wiki/<DBSchema>/{Tables,Views}/."""
    out: list[dict] = []
    if not WIKI_SYNAPSE.exists():
        return out
    for sch_dir in sorted(WIKI_SYNAPSE.iterdir()):
        if not sch_dir.is_dir() or sch_dir.name.startswith("_") or sch_dir.name == "__pycache__":
            continue
        for sub in ("Tables", "Views"):
            d = sch_dir / sub
            if not d.exists():
                continue
            for md in d.glob("*.md"):
                if not _is_dataset_md(md):
                    continue
                out.append({
                    "source": "SYNAPSE",
                    "md": md,
                    "kind": sub.rstrip("s"),
                    "db_for_mapping": None,         # synapse mapping doesn't need db
                    "schema_for_mapping": sch_dir.name,
                    "table_for_mapping": md.stem,
                })
    return out


def discover_prodschemas() -> list[dict]:
    """Wiki files under knowledge/ProdSchemas/<group>/<DB>/Wiki/<schema>/{Tables,Views}/.
    Filename pattern is '<schema>.<name>.md' but we fall back to stem split."""
    out: list[dict] = []
    if not WIKI_PROD.exists():
        return out
    # Find all Wiki dirs under ProdSchemas
    for wiki_dir in sorted(WIKI_PROD.rglob("Wiki")):
        if not wiki_dir.is_dir():
            continue
        # DB name is the parent of "Wiki"
        db_name = wiki_dir.parent.name
        for sch_dir in sorted(wiki_dir.iterdir()):
            if not sch_dir.is_dir() or sch_dir.name.startswith("_"):
                continue
            schema_name = sch_dir.name
            for sub in ("Tables", "Views"):
                d = sch_dir / sub
                if not d.exists():
                    continue
                for md in d.glob("*.md"):
                    if not _is_dataset_md(md):
                        continue
                    stem = md.stem
                    if stem.startswith(f"{schema_name}."):
                        table_name = stem[len(schema_name) + 1:]
                    else:
                        # filename without schema prefix — use stem as-is
                        table_name = stem
                    out.append({
                        "source": "PRODSCHEMAS",
                        "md": md,
                        "kind": sub.rstrip("s"),
                        "db_for_mapping": db_name,
                        "schema_for_mapping": schema_name,
                        "table_for_mapping": table_name,
                    })
    return out


def discover_uc_generated() -> list[dict]:
    """Wiki files under knowledge/UC_generated/<schema>/{Tables,Views}/<name>.md.
    These document already-in-UC canonical objects; no mapping needed —
    UC target is main.<schema>.<name>."""
    out: list[dict] = []
    if not WIKI_UC.exists():
        return out
    for sch_dir in sorted(WIKI_UC.iterdir()):
        if not sch_dir.is_dir() or sch_dir.name.startswith("_"):
            continue
        for sub in ("Tables", "Views"):
            d = sch_dir / sub
            if not d.exists():
                continue
            for md in d.glob("*.md"):
                if not _is_dataset_md(md):
                    continue
                out.append({
                    "source": "UC_GENERATED",
                    "md": md,
                    "kind": sub.rstrip("s"),
                    "uc_catalog": "main",
                    "uc_schema": sch_dir.name.lower(),
                    "uc_table_name": md.stem.lower(),
                })
    return out


# ----------------------------- mapping -----------------------------

def load_mapping_indexes():
    """Return two dicts:
       by_syn[(schema_name, table_name)] = mapping dict   (synapse-style)
       by_prod[(db, schema, table)]      = mapping dict   (prod-schemas-style)
    Case-insensitive on prod side."""
    raw = json.loads(MAP_JSON.read_text(encoding="utf-8"))
    by_syn: dict[tuple[str, str], dict] = {}
    by_prod: dict[tuple[str, str, str], dict] = {}
    for m in raw.get("mappings", []):
        db = (m.get("database_name") or "").strip()
        sch = (m.get("schema_name") or "").strip()
        tbl = (m.get("table_name") or "").strip()
        if not sch or not tbl:
            continue
        by_syn.setdefault((sch, tbl), m)
        by_prod.setdefault((db.lower(), sch.lower(), tbl.lower()), m)
    return by_syn, by_prod


def split_uc(uc_table_raw: str) -> tuple[str, str, str]:
    """Normalize 'cat.schema.table' or 'schema.table' to (cat, sch, tbl) lower.
    Two-part names get 'main.' catalog (mapping convention), except pii_data."""
    t = (uc_table_raw or "").strip().lstrip("`").rstrip("`")
    parts = t.split(".")
    if len(parts) == 2:
        sch_l = parts[0].lower()
        if sch_l == "pii_data":
            return ("pii_data", sch_l, parts[1].lower())
        return ("main", sch_l, parts[1].lower())
    if len(parts) == 3:
        return (parts[0].lower(), parts[1].lower(), parts[2].lower())
    return ("", "", "")


# ----------------------------- UC fetch -----------------------------

def fetch_uc_coverage(targets: list[tuple[str, str, str]]) -> dict[tuple[str, str, str], dict]:
    if not targets:
        return {}
    from databricks import sql
    host = os.environ.get("DATABRICKS_SERVER_HOSTNAME",
                          "adb-5142916747090026.6.azuredatabricks.net")
    http_path = os.environ.get("DATABRICKS_HTTP_PATH",
                               "/sql/1.0/warehouses/208214768b0e0308")
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    print(f"Connecting to Databricks ({len(targets)} UC targets in scope)...", flush=True)
    if token:
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
    cur = conn.cursor()

    by_schema: dict[tuple[str, str], set[str]] = defaultdict(set)
    for cat, sch, tbl in targets:
        if cat and sch and tbl:
            by_schema[(cat, sch)].add(tbl)

    out: dict[tuple[str, str, str], dict] = {}
    for (cat, sch), tbls in by_schema.items():
        try:
            cur.execute(
                f"SELECT lower(table_name) AS t, comment "
                f"FROM {cat}.information_schema.tables "
                f"WHERE table_schema = '{sch}'"
            )
            tbl_comments: dict[str, str] = {row[0]: (row[1] or "") for row in cur.fetchall()}
            cur.execute(
                f"SELECT lower(table_name) AS t, "
                f"COUNT(*) AS total_cols, "
                f"SUM(CASE WHEN comment IS NULL OR comment='' THEN 0 ELSE 1 END) AS commented_cols, "
                f"SUM(CASE WHEN comment IN ('T0','T1','T2','T3','T4') THEN 1 ELSE 0 END) AS tier_drift_cols "
                f"FROM {cat}.information_schema.columns "
                f"WHERE table_schema = '{sch}' "
                f"GROUP BY lower(table_name)"
            )
            col_stats: dict[str, tuple[int, int, int]] = {
                row[0]: (int(row[1] or 0), int(row[2] or 0), int(row[3] or 0))
                for row in cur.fetchall()
            }
        except Exception as e:
            print(f"  WARN {cat}.{sch}: schema query failed: {e}", flush=True)
            tbl_comments, col_stats = {}, {}

        for tbl in tbls:
            present = tbl in col_stats or tbl in tbl_comments
            total, commented, tier = col_stats.get(tbl, (0, 0, 0))
            out[(cat, sch, tbl)] = {
                "exists": present,
                "table_comment": tbl_comments.get(tbl, ""),
                "total_cols": total,
                "commented_cols": commented,
                "tier_drift_cols": tier,
            }
        found = sum(1 for t in tbls if t in col_stats)
        print(f"  {cat}.{sch}: {len(tbls)} targets, {found} found", flush=True)
    cur.close()
    conn.close()
    return out


# ----------------------------- classify -----------------------------

def classify(uc: dict | None) -> str:
    if uc is None:
        return "NOT_MAPPED"
    if not uc.get("exists"):
        return "MISSING_IN_UC"
    total = uc["total_cols"]
    commented = uc["commented_cols"]
    tbl_c = (uc["table_comment"] or "").strip()
    if total == 0:
        return "NO_COLUMNS_IN_UC"
    if commented == 0 and not tbl_c:
        return "NO_COMMENTS_AT_ALL"
    if commented == 0 and tbl_c:
        return "ONLY_TABLE_COMMENT"
    if commented < total and (commented / total) < 0.30:
        return "LOW_COL_COVERAGE"
    if commented >= total * 0.30 and not tbl_c:
        return "NO_TABLE_COMMENT"
    return "OK"


# ----------------------------- main -----------------------------

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sources", nargs="*",
                    choices=["SYNAPSE", "PRODSCHEMAS", "UC_GENERATED"],
                    help="Limit to one or more wiki sources")
    ap.add_argument("--skip-uc", action="store_true",
                    help="Skip live UC query (layout-only debug)")
    args = ap.parse_args()

    keep = set(args.sources) if args.sources else None

    discovered: list[dict] = []
    if keep is None or "SYNAPSE" in keep:
        discovered += discover_synapse()
    if keep is None or "PRODSCHEMAS" in keep:
        discovered += discover_prodschemas()
    if keep is None or "UC_GENERATED" in keep:
        discovered += discover_uc_generated()
    print(f"Discovered {len(discovered)} dataset wiki MDs:")
    src_counts = Counter(d["source"] for d in discovered)
    for s, n in src_counts.most_common():
        print(f"  {s:<14} {n:>5}")
    print()

    by_syn, by_prod = load_mapping_indexes()
    print(f"Mapping indexes loaded: {len(by_syn)} synapse keys, {len(by_prod)} prod keys")
    print()

    # Resolve UC target for each discovered wiki
    pairs: list[dict] = []
    for d in discovered:
        uc_cat = uc_sch = uc_tbl = ""
        mapped = False
        if d["source"] == "SYNAPSE":
            m = by_syn.get((d["schema_for_mapping"], d["table_for_mapping"]))
            if m:
                uc_cat, uc_sch, uc_tbl = split_uc(m.get("uc_table", ""))
                mapped = bool(uc_tbl)
        elif d["source"] == "PRODSCHEMAS":
            m = by_prod.get((d["db_for_mapping"].lower(),
                             d["schema_for_mapping"].lower(),
                             d["table_for_mapping"].lower()))
            if m:
                uc_cat, uc_sch, uc_tbl = split_uc(m.get("uc_table", ""))
                mapped = bool(uc_tbl)
        elif d["source"] == "UC_GENERATED":
            uc_cat = d["uc_catalog"]
            uc_sch = d["uc_schema"]
            uc_tbl = d["uc_table_name"]
            mapped = True
        d["uc_cat"], d["uc_sch"], d["uc_tbl"] = uc_cat, uc_sch, uc_tbl
        d["mapped"] = mapped
        pairs.append(d)

    n_mapped = sum(1 for p in pairs if p["mapped"])
    print(f"Mapped to a UC target: {n_mapped}/{len(pairs)}")
    print()

    # Build distinct UC targets
    targets = sorted({(p["uc_cat"], p["uc_sch"], p["uc_tbl"]) for p in pairs if p["mapped"]})
    if args.skip_uc:
        print("--skip-uc set, leaving UC coverage empty.")
        cov: dict = {}
    else:
        cov = fetch_uc_coverage(targets)

    # Score each pair
    rows = []
    bucket_counts = Counter()
    src_bucket = defaultdict(Counter)
    for p in pairs:
        key = (p["uc_cat"], p["uc_sch"], p["uc_tbl"])
        if p["mapped"]:
            uc = cov.get(key, {"exists": False, "table_comment": "",
                               "total_cols": 0, "commented_cols": 0, "tier_drift_cols": 0})
        else:
            uc = None
        bucket = classify(uc)
        bucket_counts[bucket] += 1
        src_bucket[p["source"]][bucket] += 1
        rows.append({
            "source": p["source"],
            "wiki_md": str(p["md"].relative_to(REPO)).replace("\\", "/"),
            "kind": p["kind"],
            "db": p.get("db_for_mapping", "") or "",
            "schema": p.get("schema_for_mapping", "") or p.get("uc_schema", ""),
            "table": p.get("table_for_mapping", "") or p.get("uc_table_name", ""),
            "uc_target": (f"{p['uc_cat']}.{p['uc_sch']}.{p['uc_tbl']}" if p["mapped"] else ""),
            "mapped": "yes" if p["mapped"] else "no",
            "uc_exists": "yes" if (uc and uc["exists"]) else "no",
            "uc_table_comment_set": "yes" if (uc and (uc["table_comment"] or "").strip()) else "no",
            "uc_total_cols": uc["total_cols"] if uc else 0,
            "uc_commented_cols": uc["commented_cols"] if uc else 0,
            "uc_tier_drift_cols": uc["tier_drift_cols"] if uc else 0,
            "uc_col_coverage_pct": (
                round(100 * uc["commented_cols"] / uc["total_cols"], 1)
                if uc and uc["total_cols"] else 0.0
            ),
            "bucket": bucket,
        })

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print()
    print("=" * 78)
    print(f"Audit complete. Detail CSV: {OUT_CSV.relative_to(REPO).as_posix()}")
    print()
    print("Overall bucket counts:")
    for b, n in bucket_counts.most_common():
        print(f"  {b:<22} {n:>6}")
    print()
    print("By source × bucket:")
    for src in sorted(src_bucket):
        parts = ", ".join(f"{b}={n}" for b, n in src_bucket[src].most_common())
        print(f"  {src:<14} {parts}")
    print()

    gap_buckets = (
        "NO_COMMENTS_AT_ALL", "ONLY_TABLE_COMMENT",
        "LOW_COL_COVERAGE", "NO_TABLE_COMMENT", "MISSING_IN_UC",
    )
    # Worst gap: NO_COMMENTS_AT_ALL — UC table exists but is entirely bare
    bare = [r for r in rows if r["bucket"] == "NO_COMMENTS_AT_ALL"]
    print(f"NO_COMMENTS_AT_ALL (top 30 of {len(bare)}, sorted by cols desc):")
    for r in sorted(bare, key=lambda x: -x["uc_total_cols"])[:30]:
        print(f"  [{r['source']:<13}] [{r['uc_total_cols']:>3d} cols] "
              f"{r['uc_target']:<70} <- {r['wiki_md']}")
    print()
    only = [r for r in rows if r["bucket"] == "ONLY_TABLE_COMMENT"]
    if only:
        print(f"ONLY_TABLE_COMMENT (top 20 of {len(only)}):")
        for r in sorted(only, key=lambda x: -x["uc_total_cols"])[:20]:
            print(f"  [{r['source']:<13}] [{r['uc_total_cols']:>3d} cols] "
                  f"{r['uc_target']:<70} <- {r['wiki_md']}")


if __name__ == "__main__":
    main()
