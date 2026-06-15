"""Corpus-wide column-description weakness inventory.

Scans every UC column across the schemas we own (or partially own), cross-
references each against the wiki corpus, and tags every column with one of
seven actionable buckets:

  RICH_OK                    — comment >150 chars, has predicates/literals.
                               Leave alone.
  EMPTY_HAS_WIKI             — UC empty, wiki §4 has a non-trivial row.
                               → auto-deploy wiki text.
  EMPTY_NO_WIKI              — UC empty, no wiki coverage (or wiki row
                               itself is trivial). → flag for wiki authoring.
  WEAK_TRIVIAL_HAS_RICHER    — UC ≤80 chars or matches a trivial pattern,
                               and a richer source exists (wiki §4 row OR
                               sibling wiki). → run converger.
  WEAK_TRIVIAL_NO_SIGNAL     — Weak comment, nothing better available.
                               → flag as orphan.
  MEDIUM_HAS_RICHER          — UC 81–150, a richer source exists
                               (sibling or §4 with more literals).
                               → optional converger pass.
  MEDIUM_OK                  — UC 81–150, no clear improvement available.
                               Leave alone for now.

Outputs:
  audits/_weakness_inventory/inventory_master.csv     (every classified row)
  audits/_weakness_inventory/inventory_<schema>.csv   (per-schema slices)
  audits/_weakness_inventory/inventory_summary.json   (bucket counts + stats)
"""
from __future__ import annotations
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

# Make sibling modules importable
sys.path.insert(0, str(Path(__file__).resolve().parent))
from wiki_parse import parse_wiki  # noqa: E402
from _uc_wiki_match import find_wiki_for_uc, WIKI_INDEX  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "audits" / "_weakness_inventory"
OUT_DIR.mkdir(parents=True, exist_ok=True)

OWNED_SCHEMAS = (
    "bi_db", "bi_output", "dwh", "etoro_kpi_prep",
    "finance", "pii_data", "general", "dealing", "emoney",
)

# Trivial patterns — wider catalog than classify.py because we want to
# catch "Direct from X.Y", "Passthrough via SCD JOIN", "FK to dictionary",
# "GROUP BY pass-through" etc. as weak even when their length sneaks above 30.
TRIVIAL_RX = [
    re.compile(r"^\s*Direct(?:\s+from\s+\S+)?\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*Same\s+as\s+upstream\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*Same\s+lineage\s+as\s+\S+\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*Passthrough(?:\s+(?:via|from)\s+[^.()]{0,80})?\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*FK\s+to\s+\S+\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*GROUP\s+BY\s+pass-?through\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*Inherited\s+from\s+\S+\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*Join\s+key\s+to\s+\S+\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*Lookup(?:\s+to\s+\S+)?\s*(?:\(Tier[^)]*\))?\s*\.?\s*$", re.IGNORECASE),
    re.compile(r"^\s*\(Tier\s*\d[^)]*\)\s*$", re.IGNORECASE),
]

# Literal-density patterns (richness score)
LITERAL_RX = [
    re.compile(r"\b[A-Z][A-Za-z_]*ID\s*(?:=|IN|<>|≠|!=|>=|<=|<|>)\s*'?\(?\s*\d+", re.IGNORECASE),
    re.compile(r"\b[A-Za-z][A-Za-z_]+\s*(?:=|<>|!=|≠|>=|<=|>|<)\s*'[^']*'"),
    re.compile(r"\b[A-Za-z_][A-Za-z0-9_]{2,}\.[A-Z][A-Za-z0-9_]{2,}\b"),
    re.compile(r"@[A-Za-z][A-Za-z0-9_]+"),
    re.compile(r"(?:=|IN|>=|<=)\s*\("),
    re.compile(r"\bCASE\s+WHEN\b", re.IGNORECASE),
    re.compile(r"\b(?:COALESCE|NULLIF|ISNULL|IIF)\s*\(", re.IGNORECASE),
    re.compile(r"\b(?:SUM|AVG|MIN|MAX|COUNT)\s*\(", re.IGNORECASE),
]


def is_trivial(text: str) -> bool:
    if not text:
        return False
    return any(rx.search(text.strip()) for rx in TRIVIAL_RX)


def richness(text: str) -> int:
    if not text:
        return 0
    return sum(len(rx.findall(text)) for rx in LITERAL_RX)


def clean_cell(text: str) -> str:
    """Strip markdown/backticks/bold for length and richness comparison."""
    if not text:
        return ""
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def fetch_uc_columns():
    """Pull (schema, table, column, comment) for the owned schemas."""
    from databricks import sql
    import os
    DBX_HOST = "adb-5142916747090026.6.azuredatabricks.net"
    DBX_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"
    schemas_in = ", ".join(f"'{s}'" for s in OWNED_SCHEMAS)
    q = (
        "SELECT table_schema, table_name, column_name, comment, ordinal_position "
        "FROM system.information_schema.columns "
        f"WHERE table_catalog='main' AND table_schema IN ({schemas_in}) "
        "ORDER BY table_schema, table_name, ordinal_position"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
    if token:
        conn = sql.connect(server_hostname=DBX_HOST, http_path=DBX_HTTP_PATH, access_token=token)
    else:
        from databricks.sdk import WorkspaceClient
        wc = WorkspaceClient(profile=os.environ.get("DATABRICKS_MCP_PROFILE", "guyman"))
        conn = sql.connect(
            server_hostname=DBX_HOST,
            http_path=DBX_HTTP_PATH,
            credentials_provider=lambda: wc.config.authenticate,
        )
    cur = conn.cursor()
    cur.execute(q)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    print(f"  Fetched {len(rows)} UC columns")
    return [(r[0], r[1], r[2], r[3] or "", int(r[4])) for r in rows]


def build_wiki_corpus():
    """{column_name_lower: [(wiki_path, semantic_cell, tier, source)]}"""
    print(f"  Walking wiki corpus...")
    wiki_dir = ROOT / "knowledge" / "synapse" / "Wiki"
    sibling_index: dict[str, list[dict]] = defaultdict(list)
    wiki_table_rows: dict[Path, dict[str, dict]] = {}
    parsed = skipped = 0
    for path in wiki_dir.rglob("*.md"):
        if path.name.endswith(".lineage.md") or path.name.endswith(".review-needed.md"):
            continue
        try:
            pt = parse_wiki(path)
        except Exception as e:
            print(f"    WARN: parse failed {path.relative_to(ROOT)}: {e}")
            continue
        if pt.skipped_reason:
            skipped += 1
            continue
        parsed += 1
        wiki_table_rows[path] = {}
        for r in pt.rows:
            col_l = r.column.lower().strip()
            if not col_l:
                continue
            cell = clean_cell(r.semantic_cell)
            entry = {
                "wiki_path": path,
                "column": r.column,
                "cell": cell,
                "tier": r.tier,
                "source": r.source,
            }
            sibling_index[col_l].append(entry)
            wiki_table_rows[path][col_l] = entry
    print(f"  Parsed: {parsed} wikis, skipped: {skipped}")
    print(f"  Sibling index: {len(sibling_index)} unique column names")
    return sibling_index, wiki_table_rows


def best_sibling(col_lower: str, sibling_index, exclude_path):
    """Return the richest sibling row for this column, excluding own wiki."""
    candidates = [
        c for c in sibling_index.get(col_lower, [])
        if c["wiki_path"] != exclude_path
        and not is_trivial(c["cell"])
        and len(c["cell"]) > 30
    ]
    if not candidates:
        return None
    candidates.sort(
        key=lambda c: (-richness(c["cell"]), -len(c["cell"]))
    )
    return candidates[0]


def classify_row(uc_comment, uc_len, wiki_row, sib):
    """Return (bucket, proposed_action, reason)."""
    uc_clean = clean_cell(uc_comment)
    uc_clean_len = len(uc_clean)
    uc_rich = richness(uc_clean)
    uc_trivial = is_trivial(uc_clean)

    # Empty
    if uc_clean_len == 0:
        if wiki_row and not is_trivial(wiki_row["cell"]) and len(wiki_row["cell"]) > 30:
            return ("EMPTY_HAS_WIKI", "auto_deploy_wiki",
                    f"wiki §4 has {len(wiki_row['cell'])}ch")
        if sib and len(sib["cell"]) > 60:
            return ("EMPTY_HAS_WIKI", "auto_deploy_sibling",
                    f"sibling {sib['wiki_path'].name} has {len(sib['cell'])}ch r={richness(sib['cell'])}")
        return ("EMPTY_NO_WIKI", "needs_authoring", "no usable wiki/sibling")

    # Rich enough already
    if uc_clean_len > 150 and uc_rich >= 1 and not uc_trivial:
        return ("RICH_OK", "leave_alone", f"len={uc_clean_len} r={uc_rich}")

    # Anything trivial-pattern is weak no matter the length
    if uc_trivial:
        if wiki_row and not is_trivial(wiki_row["cell"]) and len(wiki_row["cell"]) > uc_clean_len + 30:
            return ("WEAK_TRIVIAL_HAS_RICHER", "converge_wiki",
                    f"trivial; wiki {len(wiki_row['cell'])}ch r={richness(wiki_row['cell'])}")
        if sib and len(sib["cell"]) > uc_clean_len + 50:
            return ("WEAK_TRIVIAL_HAS_RICHER", "converge_sibling",
                    f"trivial; sibling {sib['wiki_path'].name} {len(sib['cell'])}ch r={richness(sib['cell'])}")
        return ("WEAK_TRIVIAL_NO_SIGNAL", "orphan", "trivial; no usable upstream")

    # Short comment
    if uc_clean_len <= 80:
        if wiki_row and not is_trivial(wiki_row["cell"]) and len(wiki_row["cell"]) > uc_clean_len + 50:
            return ("WEAK_TRIVIAL_HAS_RICHER", "converge_wiki",
                    f"short; wiki {len(wiki_row['cell'])}ch r={richness(wiki_row['cell'])}")
        if sib and len(sib["cell"]) > uc_clean_len + 80:
            return ("WEAK_TRIVIAL_HAS_RICHER", "converge_sibling",
                    f"short; sibling {sib['wiki_path'].name} {len(sib['cell'])}ch r={richness(sib['cell'])}")
        return ("WEAK_TRIVIAL_NO_SIGNAL", "orphan", "short; no richer source")

    # Medium 81-150
    if 81 <= uc_clean_len <= 150:
        sib_rich = richness(sib["cell"]) if sib else 0
        wiki_rich = richness(wiki_row["cell"]) if wiki_row else 0
        if wiki_rich > uc_rich + 1 or (wiki_row and len(wiki_row["cell"]) > uc_clean_len + 80):
            return ("MEDIUM_HAS_RICHER", "converge_wiki",
                    f"medium; wiki r={wiki_rich} > uc r={uc_rich}")
        if sib_rich > uc_rich + 1 or (sib and len(sib["cell"]) > uc_clean_len + 100):
            return ("MEDIUM_HAS_RICHER", "converge_sibling",
                    f"medium; sibling r={sib_rich} > uc r={uc_rich}")
        return ("MEDIUM_OK", "leave_alone", f"medium; no clear win uc r={uc_rich}")

    # >150 but no literal richness
    if uc_clean_len > 150 and uc_rich == 0:
        if wiki_row and richness(wiki_row["cell"]) > 0:
            return ("MEDIUM_HAS_RICHER", "converge_wiki",
                    f"long-but-no-literals; wiki has r={richness(wiki_row['cell'])}")
        if sib and richness(sib["cell"]) > 0:
            return ("MEDIUM_HAS_RICHER", "converge_sibling",
                    f"long-but-no-literals; sibling has r={richness(sib['cell'])}")
        return ("MEDIUM_OK", "leave_alone", "long-but-no-literals; nothing better")

    return ("RICH_OK", "leave_alone", f"len={uc_clean_len} r={uc_rich}")


def main():
    print("Step 1: Building wiki corpus")
    sibling_index, wiki_table_rows = build_wiki_corpus()
    print()

    print("Step 2: Fetching UC columns")
    uc_rows = fetch_uc_columns()
    print()

    print("Step 3: Classifying every column")
    fields = [
        "schema", "table", "column", "ordinal", "current_len",
        "current_rich", "is_trivial", "bucket", "action", "reason",
        "wiki_path", "wiki_len", "wiki_rich",
        "best_sibling_path", "best_sibling_len", "best_sibling_rich",
        "current_comment", "wiki_cell", "best_sibling_cell",
    ]
    by_schema: dict[str, list[dict]] = defaultdict(list)
    bucket_counts: dict[str, int] = defaultdict(int)
    bucket_by_schema: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))

    for sch, tbl, col, comment, ordinal in uc_rows:
        fqn = f"main.{sch}.{tbl}"
        wiki_path = find_wiki_for_uc(fqn)
        wiki_row = (
            wiki_table_rows.get(wiki_path, {}).get(col.lower())
            if wiki_path else None
        )
        sib = best_sibling(col.lower(), sibling_index, wiki_path)

        uc_clean = clean_cell(comment)
        bucket, action, reason = classify_row(comment, len(uc_clean), wiki_row, sib)
        bucket_counts[bucket] += 1
        bucket_by_schema[sch][bucket] += 1

        row = {
            "schema": sch,
            "table": tbl,
            "column": col,
            "ordinal": ordinal,
            "current_len": len(uc_clean),
            "current_rich": richness(uc_clean),
            "is_trivial": is_trivial(uc_clean),
            "bucket": bucket,
            "action": action,
            "reason": reason,
            "wiki_path": (
                str(wiki_path.relative_to(ROOT)).replace("\\", "/")
                if wiki_path else ""
            ),
            "wiki_len": len(wiki_row["cell"]) if wiki_row else 0,
            "wiki_rich": richness(wiki_row["cell"]) if wiki_row else 0,
            "best_sibling_path": (
                str(sib["wiki_path"].relative_to(ROOT)).replace("\\", "/")
                if sib else ""
            ),
            "best_sibling_len": len(sib["cell"]) if sib else 0,
            "best_sibling_rich": richness(sib["cell"]) if sib else 0,
            "current_comment": (uc_clean[:500]),
            "wiki_cell": (wiki_row["cell"][:500] if wiki_row else ""),
            "best_sibling_cell": (sib["cell"][:500] if sib else ""),
        }
        by_schema[sch].append(row)

    print()
    print("Step 4: Writing CSVs")
    master = OUT_DIR / "inventory_master.csv"
    with master.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        for sch in OWNED_SCHEMAS:
            for r in by_schema[sch]:
                w.writerow(r)
    print(f"  Master: {master.relative_to(ROOT)}  ({sum(len(v) for v in by_schema.values())} rows)")

    for sch, rows in by_schema.items():
        path = OUT_DIR / f"inventory_{sch}.csv"
        with path.open("w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=fields)
            w.writeheader()
            for r in rows:
                w.writerow(r)

    summary = {
        "total_columns": sum(bucket_counts.values()),
        "buckets": dict(bucket_counts),
        "by_schema": {sch: dict(b) for sch, b in bucket_by_schema.items()},
        "owned_schemas": list(OWNED_SCHEMAS),
    }
    (OUT_DIR / "inventory_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )

    print()
    print("=" * 76)
    print(f"{'Bucket':<28}{'Count':>10}{'% of total':>14}")
    print("-" * 76)
    total = sum(bucket_counts.values())
    bucket_order = [
        "RICH_OK", "MEDIUM_OK", "MEDIUM_HAS_RICHER",
        "EMPTY_HAS_WIKI", "EMPTY_NO_WIKI",
        "WEAK_TRIVIAL_HAS_RICHER", "WEAK_TRIVIAL_NO_SIGNAL",
    ]
    for b in bucket_order:
        c = bucket_counts.get(b, 0)
        pct = (100 * c / total) if total else 0
        print(f"{b:<28}{c:>10}{pct:>13.1f}%")
    print("-" * 76)
    print(f"{'TOTAL':<28}{total:>10}")
    print()
    print("By schema:")
    print(f"{'schema':<18}", *[f"{b[:18]:>20}" for b in bucket_order])
    for sch in OWNED_SCHEMAS:
        if sch not in bucket_by_schema:
            continue
        cells = [
            f"{bucket_by_schema[sch].get(b, 0):>20}" for b in bucket_order
        ]
        print(f"{sch:<18}", *cells)
    print()
    print(f"Summary JSON: {(OUT_DIR / 'inventory_summary.json').relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
