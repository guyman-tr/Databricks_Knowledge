"""Generate UC bronze ALTER COMMENT scripts from Tier 1 ProdSchemas wikis.

Reads knowledge/ProdSchemas/_bronze_scope.json (built by build_bronze_scope.py),
parses each ready wiki via tools.uc_bronze.wiki_parser, and writes one
.alter.sql file per ready row, colocated with the wiki:

    knowledge/ProdSchemas/{repo}/{db}/Wiki/{schema}/Tables/{schema}.{table}.alter.sql

Plus one _deploy-index.md per database tracking generation status:

    knowledge/ProdSchemas/{repo}/{db}/_deploy-index.md

Output format mirrors the existing Synapse alter scripts so the same
deploy_alter_batch.py tooling can later consume them.

Usage:
  python -m tools.uc_bronze.generate_bronze_alters                # all ready rows
  python -m tools.uc_bronze.generate_bronze_alters --db FiatDwhDB # filter
  python -m tools.uc_bronze.generate_bronze_alters --limit 5      # smoke test
  python -m tools.uc_bronze.generate_bronze_alters --dry-run      # no writes
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

from tools.uc_bronze.wiki_parser import parse_wiki

REPO_ROOT = Path(__file__).resolve().parents[2]
SCOPE_FILE = REPO_ROOT / "knowledge" / "ProdSchemas" / "_bronze_scope.json"

UC_CATALOG = "main"
TABLE_COMMENT_LIMIT = 4000
COLUMN_COMMENT_LIMIT = 1024
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%d")


# ---- SQL helpers ------------------------------------------------------------

def esc(text: str) -> str:
    return text.replace("'", "''")


def truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    return text[: limit - 3].rstrip() + "..."


def uc_full_target(uc_table: str) -> str:
    """Convert mapping uc_table (e.g. 'billing.bronze_x_y_z') to full UC path."""
    parts = uc_table.split(".")
    if len(parts) == 2:
        return f"{UC_CATALOG}.{uc_table}"
    return uc_table


# ---- Tag construction -------------------------------------------------------

def build_table_tags(row: dict) -> dict[str, str]:
    """Tags applied to the bronze table itself."""
    tags: dict[str, str] = {
        "layer": "bronze",
        "source_system": "SQL Server",
        "source_database": row["database_name"],
        "source_schema": row["schema_name"],
        "source_table": row["table_name"],
        "business_group": row["business_group"],
        "pipeline": "generic_pipeline",
        "doc_source": "tier1_wiki",
        "doc_generated": NOW,
    }
    cs = row.get("copy_strategy")
    if cs:
        tags["copy_strategy"] = cs
    fm = row.get("frequency_minutes")
    if fm:
        tags["refresh_minutes"] = str(fm)
    return tags


# ---- Comment construction ---------------------------------------------------

def compose_table_comment(parsed, row: dict) -> str:
    """Build the table-level COMMENT.

    Combines the wiki's H1 blockquote (or §1 first paragraph) with provenance
    that explains where the data came from and how it lands in bronze.
    """
    base = parsed.description or f"{parsed.object_name} (no description in upstream wiki)."
    provenance = (
        f"Source: {row['database_name']}.{row['schema_name']}.{row['table_name']} "
        f"on the {row['database_name']} production database, ingested via the Generic Pipeline "
        f"({row.get('copy_strategy', 'unknown')} strategy"
    )
    fm = row.get("frequency_minutes")
    if fm:
        provenance += f", {fm}-minute refresh"
    provenance += ")."
    full = f"{base} {provenance} Doc source: Tier 1 wiki ({row.get('wiki_path', parsed.path)})."
    return truncate(full, TABLE_COMMENT_LIMIT)


def compose_column_comment(col, row: dict) -> str:
    """Bronze columns inherit the upstream wiki description verbatim and
    get a (Tier 1 - upstream wiki) tag for traceability."""
    desc = col.description or "(no description in upstream wiki)"
    tag = f"(Tier 1 - upstream wiki, {row['database_name']}.{row['schema_name']}.{row['table_name']})"
    full = f"{desc} {tag}"
    return truncate(full, COLUMN_COMMENT_LIMIT)


# ---- File rendering ---------------------------------------------------------

def _render_target_block(parsed, row: dict) -> list[str]:
    """Render ALTER statements for one UC target."""
    target = uc_full_target(row["uc_table"])
    tags = build_table_tags(row)
    table_comment = compose_table_comment(parsed, row)
    out: list[str] = []
    out.append(f"-- ---- UC Target: {target} (business_group={row['business_group']}) ----")
    out.append(f"ALTER TABLE {target} SET TBLPROPERTIES (")
    out.append(f"    'comment' = '{esc(table_comment)}'")
    out.append(");")
    out.append("")
    if tags:
        out.append(f"ALTER TABLE {target} SET TAGS (")
        tag_lines = [f"    '{k}' = '{esc(str(v))}'" for k, v in tags.items()]
        out.append(",\n".join(tag_lines))
        out.append(");")
        out.append("")
    out.append("-- Column Comments")
    for col in parsed.columns:
        comment = compose_column_comment(col, row)
        out.append(
            f"ALTER TABLE {target} ALTER COLUMN {col.name} COMMENT '{esc(comment)}';"
        )
    out.append("")
    return out


def render_alter_file(parsed, rows: list[dict]) -> str:
    """Render an alter file covering one source wiki and one or more UC targets.

    When a single source table is mirrored to multiple bronze tables (e.g. a
    PII source + a masked view in a different catalog), all UC targets share
    the wiki's column descriptions and are rendered as separate ALTER blocks
    in one file.
    """
    if not rows:
        return ""
    head = rows[0]
    targets = [uc_full_target(r["uc_table"]) for r in rows]

    lines: list[str] = []
    lines.append("-- =============================================================================")
    lines.append(f"-- Databricks ALTER Script: bronze {head['database_name']}.{head['schema_name']}.{head['table_name']}")
    lines.append(f"-- Generated: {NOW} | tools/uc_bronze/generate_bronze_alters.py")
    lines.append(f"-- Source wiki: {head['wiki_path']}")
    lines.append(f"-- Layer: bronze")
    if len(rows) == 1:
        lines.append(f"-- UC Target: {targets[0]}")
    else:
        lines.append(f"-- UC Targets ({len(rows)}):")
        for t in targets:
            lines.append(f"--   {t}")
    lines.append("-- =============================================================================")
    lines.append("")

    for r in rows:
        lines.extend(_render_target_block(parsed, r))

    return "\n".join(lines) + "\n"


def alter_path_for(row: dict) -> Path:
    """Where the .alter.sql file should be written, mirroring the wiki layout.

    Tier 1 wikis use {schema}.{table}.md, so we cannot rely on Path.with_suffix
    (which treats every dot as a suffix boundary). Strip exactly the trailing
    '.md' and append '.alter.sql'.
    """
    wiki_rel = row["wiki_path"]
    if not wiki_rel:
        raise ValueError(f"row has no wiki_path: {row}")
    wiki_full = REPO_ROOT / wiki_rel
    name = wiki_full.name
    if name.lower().endswith(".md"):
        name = name[:-3]
    return wiki_full.with_name(name + ".alter.sql")


# ---- Per-db deploy index ----------------------------------------------------

def db_root_for(row: dict) -> Path:
    """The {repo}/{db}/ root, derived from wiki_root."""
    return REPO_ROOT / row["wiki_root"].rsplit("/Wiki", 1)[0]


def _db_key_for(row: dict) -> str:
    """Build a stable {repo}/{db} key from the wiki_root.

    wiki_root is e.g. 'knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki', so the
    repo segment is parts[2]. Fall back to database_name if wiki_root is absent.
    """
    if not row.get("wiki_root"):
        return row.get("database_name", "<unknown>")
    parts = Path(row["wiki_root"]).parts
    if len(parts) >= 4:
        return f"{parts[2]}/{row['database_name']}"
    return row["database_name"]


_DEPLOYED_STATUS_RE = re.compile(r"^\s*Deployed\b", re.IGNORECASE)
_FRONT_BATCH_RE   = re.compile(r"^last_deploy_batch:\s*(\d+)\s*$", re.IGNORECASE | re.MULTILINE)
_FRONT_LASTDEP_RE = re.compile(r"^last_deployed:\s*\"?([^\"\n]+)\"?\s*$", re.IGNORECASE | re.MULTILINE)
_TABLE_ROW_RE = re.compile(
    r"^\|\s*(?:\[[^\]]+\]\([^)]*\)|[^|]+?)\s*\|\s*`([^`]+)`\s*\|\s*(.+?)\s*\|\s*$",
    re.MULTILINE,
)


def _read_existing_index(out: Path) -> tuple[dict[str, str], int, str]:
    """Return (uc_target -> previous status, last_deploy_batch, last_deployed_date).

    Carries forward any "Deployed (Batch N) - YYYY-MM-DD" rows so a regen does
    NOT wipe the audit trail. Returns ({}, 0, "") if no existing index.
    """
    if not out.is_file():
        return {}, 0, ""
    text = out.read_text(encoding="utf-8")
    prev: dict[str, str] = {}
    for m in _TABLE_ROW_RE.finditer(text):
        uc_target = m.group(1).strip()
        status    = m.group(2).strip()
        if _DEPLOYED_STATUS_RE.match(status):
            prev[uc_target.lower()] = status
    batch_match = _FRONT_BATCH_RE.search(text)
    lastdep_match = _FRONT_LASTDEP_RE.search(text)
    return (
        prev,
        int(batch_match.group(1)) if batch_match else 0,
        lastdep_match.group(1).strip() if lastdep_match else "",
    )


def write_deploy_index(db_key: str, ready_rows: list[dict], failed_rows: list[dict]) -> Path:
    """Write a per-db _deploy-index.md tracking which tables have alter files generated.

    Preserves "Deployed" status from any existing index so a regen never wipes
    the deployment audit trail. New rows that did not exist before show as
    "Generated"; rows that were previously "Deployed" keep their full
    "Deployed (Batch N) - YYYY-MM-DD" label.
    """
    if not ready_rows and not failed_rows:
        raise ValueError(f"no rows for db {db_key}")
    sample = ready_rows[0] if ready_rows else failed_rows[0]
    db_root = db_root_for(sample)
    db_name = sample["database_name"]
    out = db_root / "_deploy-index.md"

    prev_deployed, prev_batch, prev_lastdep = _read_existing_index(out)

    deployed_count = 0
    rendered: list[tuple[str, str, str]] = []   # (sort_key, line, status_for_count)
    for r in ready_rows:
        uc_full = uc_full_target(r["uc_table"])
        carried = prev_deployed.get(uc_full.lower())
        status = carried if carried else "Generated"
        if carried:
            deployed_count += 1
        obj = f"{r['schema_name']}.{r['table_name']}"
        if r.get("wiki_path") and r.get("wiki_root"):
            link_target = Path(r["wiki_path"]).relative_to(Path(r["wiki_root"]).parent).as_posix()
            wiki_link = f"[{obj}]({link_target})"
        else:
            wiki_link = obj
        rendered.append((
            (status.startswith("Deployed") and "0" or "1") + f"|{r['schema_name']}|{r['table_name']}",
            f"| {wiki_link} | `{uc_full}` | {status} |",
            status,
        ))
    for r in failed_rows:
        uc_full = uc_full_target(r["uc_table"])
        obj = f"{r['schema_name']}.{r['table_name']}"
        if r.get("wiki_path") and r.get("wiki_root"):
            link_target = Path(r["wiki_path"]).relative_to(Path(r["wiki_root"]).parent).as_posix()
            wiki_link = f"[{obj}]({link_target})"
        else:
            wiki_link = obj
        rendered.append((
            "2" + f"|{r['schema_name']}|{r['table_name']}",
            f"| {wiki_link} | `{uc_full}` | Failed |",
            "Failed",
        ))
    rendered.sort(key=lambda x: x[0])

    generated_count = sum(1 for _, _, s in rendered if s == "Generated")
    failed_count    = sum(1 for _, _, s in rendered if s == "Failed")

    lines: list[str] = []
    lines.append("---")
    lines.append("")
    lines.append(f"## bronze: {db_name}")
    lines.append("")
    lines.append(f"db_key: {db_key}")
    lines.append(f"total_deployable: {len(ready_rows) + len(failed_rows)}")
    lines.append(f"generated: {generated_count}")
    lines.append(f"failed: {failed_count}")
    lines.append(f"deployed: {deployed_count}")
    lines.append(f"last_generated: \"{NOW}\"")
    if prev_batch > 0:
        lines.append(f"last_deploy_batch: {prev_batch}")
    if prev_lastdep:
        lines.append(f"last_deployed: \"{prev_lastdep}\"")
    lines.append("source_tool: tools/uc_bronze/generate_bronze_alters.py")
    lines.append("")
    lines.append("## Bronze ALTER Generation Status")
    lines.append("")
    lines.append("| Object | UC Target | Status |")
    lines.append("|--------|-----------|--------|")
    for _, line, _ in rendered:
        lines.append(line)

    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return out


# ---- Driver -----------------------------------------------------------------

def load_scope() -> dict:
    if not SCOPE_FILE.is_file():
        sys.exit(f"FATAL: missing {SCOPE_FILE}; run build_bronze_scope.py first")
    with SCOPE_FILE.open(encoding="utf-8") as fh:
        return json.load(fh)


def filter_rows(scope: dict, only_db: str | None, limit: int | None) -> list[dict]:
    rows = [r for r in scope["rows"] if r["status"] in ("ready", "ready_case_match")]
    if only_db:
        rows = [r for r in rows if r["database_name"] == only_db]
    if limit:
        rows = rows[:limit]
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--db", default=None, help="Filter to one database_name")
    ap.add_argument("--limit", type=int, default=None, help="Cap number of files (smoke test)")
    ap.add_argument("--dry-run", action="store_true", help="Print plan, don't write files")
    ap.add_argument("--no-index", action="store_true", help="Skip writing _deploy-index.md files")
    args = ap.parse_args()

    scope = load_scope()
    rows = filter_rows(scope, args.db, args.limit)
    if not rows:
        print("No ready rows match the filter.")
        return 0

    print(f"Plan: generate {len(rows)} bronze ALTER files"
          + (f" (db={args.db})" if args.db else "")
          + (f" (limit={args.limit})" if args.limit else "")
          + (" -- dry run" if args.dry_run else ""))

    grouped: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        grouped[row["wiki_path"]].append(row)

    by_db: dict[str, list[dict]] = defaultdict(list)
    failed_by_db: dict[str, list[dict]] = defaultdict(list)
    counter: Counter[str] = Counter()

    for wiki_rel, group in grouped.items():
        sample = group[0]
        db_key = _db_key_for(sample)
        wiki_path = REPO_ROOT / wiki_rel
        try:
            parsed = parse_wiki(wiki_path)
        except Exception as exc:
            print(f"  PARSE ERROR {sample['uc_table']}: {exc}")
            counter["parse_error"] += len(group)
            failed_by_db[db_key].extend(group)
            continue
        if parsed is None:
            print(f"  SKIP no Elements section: {wiki_rel}")
            counter["no_elements"] += len(group)
            failed_by_db[db_key].extend(group)
            continue
        if not parsed.columns:
            print(f"  SKIP empty Elements: {wiki_rel}")
            counter["empty_elements"] += len(group)
            failed_by_db[db_key].extend(group)
            continue

        sql = render_alter_file(parsed, group)
        out_path = alter_path_for(sample)
        if args.dry_run:
            counter["would_write"] += 1
            counter["targets_covered"] += len(group)
            by_db[db_key].extend(group)
            tag = f" [{len(group)} targets]" if len(group) > 1 else ""
            print(f"  (dry) {out_path.relative_to(REPO_ROOT).as_posix()}  cols={len(parsed.columns)}{tag}")
            continue

        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(sql, encoding="utf-8")
        counter["written"] += 1
        counter["targets_covered"] += len(group)
        by_db[db_key].extend(group)

    if not args.dry_run and not args.no_index:
        all_db_keys = set(by_db.keys()) | set(failed_by_db.keys())
        for db_key in sorted(all_db_keys):
            try:
                idx = write_deploy_index(db_key, by_db.get(db_key, []), failed_by_db.get(db_key, []))
                print(f"  index: {idx.relative_to(REPO_ROOT).as_posix()}")
            except Exception as exc:
                print(f"  INDEX ERROR for {db_key}: {exc}")

    print("\nResult:")
    for k, v in counter.most_common():
        print(f"  {k:<18} {v:>5}")
    print(f"  databases touched: {len(by_db)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
