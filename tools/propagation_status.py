"""Generate the enriched UC column-comment propagation status CSV.

Pulls every UC object in `main` + `lower_environments` (with column-comment
counts) and joins against local wiki / deploy-index / propagation-progress
artifacts + config blacklists.

Scope model (per user direction 2026-05-15):

- HARD DROP from output: `*_stg` schemas, `information_schema`, system
  internals. They never appear in the CSV; their counts go to the stderr
  summary only.
- Everything else is in-scope by default. There is NO schema-level
  allowlist. `main.etoro_kpi`, `main.risk`, `main.experience`, `main.wallet`,
  etc. are all included.
- Per-table `exclude_reason` only fires for table-level reasons:
  failures (deploy / propagation), name-pattern pruning, explicit
  blacklist, foreign-federation, empty.
- "Deploy overrides blacklist" — if an object is `Deployed`/`Generated`,
  pattern and blacklist excludes (priorities 6-10) are bypassed.

Spec: `.cursor/commands/propagation-status` (the slash-command in this repo).

Usage:
  python tools/propagation_status.py                  # fresh fetch + classify
  python tools/propagation_status.py --no-fetch       # re-classify cached pull
  python tools/propagation_status.py --out path.csv   # custom output path
"""
from __future__ import annotations

import argparse
import csv
import fnmatch
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"

# ============================================================================
# Schema-level HARD DROP — these schemas don't appear in the output CSV at
# all (not as excluded, not as in-scope — entirely absent). They're still
# fetched into the raw cache so `--no-fetch` re-runs see the full universe.
#
# Per user direction (2026-05-14): everything else in `main` and
# `lower_environments` is in-scope by default. No schema-level allowlist.
# Per-table excludes only.
# ============================================================================
CATALOGS_TO_QUERY = ["main", "lower_environments"]


def should_drop_schema(catalog: str, schema: str) -> bool:
    """HARD DROP — row is removed from the output CSV entirely.

    - `*_stg` (any case): staging tier, not a documentation target
    - `information_schema`: meta
    - system internal catalogs
    """
    if catalog.startswith("__databricks_internal") or catalog == "system":
        return True
    if schema == "information_schema":
        return True
    if schema.lower().endswith("_stg"):
        return True
    return False

# ============================================================================
# Synapse-name parsing. UC names follow `gold_sql_dp_prod_we_{schema}_{object}`
# where {schema} is the lowercase Synapse schema with `_dbo` (or the bare name
# for EXW_Wallet). Sorted longest-first so prefix match is unambiguous.
# ============================================================================
UC_GOLD_PREFIX = "gold_sql_dp_prod_we_"
SYNAPSE_SCHEMA_FOLDERS = {
    "dwh_dbo": "DWH_dbo",
    "bi_db_dbo": "BI_DB_dbo",
    "dealing_dbo": "Dealing_dbo",
    "emoney_dbo": "eMoney_dbo",
    "exw_dbo": "EXW_dbo",
    "exw_wallet": "EXW_Wallet",
}
SYNAPSE_SCHEMA_PREFIXES = sorted(SYNAPSE_SCHEMA_FOLDERS.keys(), key=len, reverse=True)

# ============================================================================
# Name-pattern blacklist (priority 7, 8). The keyword list is permissive —
# each keyword must appear as its own underscore-delimited token (or at the
# end of the name) to match. We do NOT match substring within a token to
# avoid false positives like `holding_*` matching `hold`.
# ============================================================================
PRUNED_KEYWORDS = [
    "backup", "bak", "bck", "snapshot", "tmp", "temp", "test", "archive",
    "hold", "junk", "copy", "legacy", "deprecated", "old", "obsolete",
    "deleted", "stale", "scratch", "debug", "dev", "sandbox", "wip",
]
DEV_PREFIXES = ["ofir_", "guyman_", "tmp_", "temp_", "test_"]

DATE_8DIGIT_RE = re.compile(r"_\d{8}$")
DATE_DASHED_RE = re.compile(r"_\d{4}_\d{2}_\d{2}$")
VERSION_SUFFIX_RE = re.compile(r"_v\d+$")
EXTERNAL_PREFIX_RE = re.compile(r"^external_", re.I)


# ----------------------------------------------------------------------------
# Config loader
# ----------------------------------------------------------------------------
def load_config() -> dict:
    """Read the explicit + name-pattern blacklists from the spec config."""
    cfg_path = REPO / ".specify" / "Configs" / "dwh-semantic-doc-config.json"
    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    bl = cfg["databases"]["synapse_dwh"].get("object_blacklist", {})
    return {
        "name_patterns": [p["pattern"] for p in bl.get("name_patterns", [])],
        "explicit_blacklist": [
            (e["schema"], e["table"]) for e in bl.get("explicit_blacklist", [])
        ],
        "schema_blacklist": [
            s["schema"] for s in bl.get("schema_blacklist", [])
        ],
    }


# ----------------------------------------------------------------------------
# UC inventory fetch
# ----------------------------------------------------------------------------
def _connect():
    """Reuse redeploy_schema._connect_databricks (databricks-sql-connector,
    same auth pattern as scan_uc_comment_gaps.py)."""
    sys.path.insert(0, str(REPO / "tools"))
    from redeploy_schema import _connect_databricks  # type: ignore
    return _connect_databricks()


def fetch_uc_inventory(conn) -> list[dict]:
    """One query per catalog. LEFT JOIN onto column-aggregates so empty
    objects (zero columns) are still returned as rows."""
    cur = conn.cursor()
    rows: list[dict] = []
    for catalog in CATALOGS_TO_QUERY:
        sql = f"""
            SELECT
              t.table_catalog AS catalog_name,
              t.table_schema  AS schema_name,
              t.table_name    AS object_name,
              t.table_type    AS object_type,
              COALESCE(cc.total_columns, 0)         AS total_columns,
              COALESCE(cc.columns_with_comments, 0) AS columns_with_comments
            FROM {catalog}.information_schema.tables t
            LEFT JOIN (
              SELECT
                table_catalog,
                table_schema,
                table_name,
                COUNT(*) AS total_columns,
                SUM(CASE WHEN comment IS NOT NULL AND TRIM(comment) <> ''
                         THEN 1 ELSE 0 END) AS columns_with_comments
              FROM {catalog}.information_schema.columns
              GROUP BY 1, 2, 3
            ) cc
              ON cc.table_catalog = t.table_catalog
             AND cc.table_schema  = t.table_schema
             AND cc.table_name    = t.table_name
            WHERE t.table_schema NOT IN ('information_schema')
            ORDER BY t.table_schema, t.table_name
        """
        print(f"  Querying {catalog}.information_schema ...", file=sys.stderr)
        cur.execute(sql)
        for r in cur.fetchall():
            cat, sch, obj, otype, total, commented = r
            rows.append({
                "catalog_name": cat,
                "schema_name": sch,
                "object_name": obj,
                "object_type": otype,
                "total_columns": int(total) if total is not None else 0,
                "columns_with_comments": int(commented) if commented is not None else 0,
            })
    cur.close()
    return rows


def save_raw_cache(rows: list[dict], cache_path: Path) -> None:
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = ["catalog_name", "schema_name", "object_name", "object_type",
                  "total_columns", "columns_with_comments"]
    with cache_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow(r)


def load_raw_cache(cache_path: Path) -> list[dict]:
    if not cache_path.is_file():
        raise FileNotFoundError(
            f"--no-fetch requires {cache_path.relative_to(REPO).as_posix()} "
            f"from a prior run. Run without --no-fetch first."
        )
    rows: list[dict] = []
    with cache_path.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            rows.append({
                "catalog_name": r["catalog_name"],
                "schema_name": r["schema_name"],
                "object_name": r["object_name"],
                "object_type": r["object_type"],
                "total_columns": int(r["total_columns"]),
                "columns_with_comments": int(r["columns_with_comments"]),
            })
    return rows


# ----------------------------------------------------------------------------
# Local artifact scanners
# ----------------------------------------------------------------------------
def parse_synapse_name(uc_object: str) -> tuple[str, str]:
    """`gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_periodicreview` ->
    ('BI_DB_dbo', 'BI_DB_AML_PeriodicReview' lowercase parts).

    Returns (synapse_schema_folder, synapse_table_lower) — empty strings if
    the UC name does not match the gold-prefix pattern.
    """
    name = uc_object.lower()
    if not name.startswith(UC_GOLD_PREFIX):
        return "", ""
    rest = name[len(UC_GOLD_PREFIX):]
    for prefix in SYNAPSE_SCHEMA_PREFIXES:
        if rest.startswith(prefix + "_"):
            schema_folder = SYNAPSE_SCHEMA_FOLDERS[prefix]
            table_lower = rest[len(prefix) + 1:]
            return schema_folder, table_lower
    return "", ""


def scan_wiki_authored() -> set[tuple[str, str]]:
    """Return {(synapse_schema, synapse_table_lower)} for every wiki .md
    that exists under knowledge/synapse/Wiki/{schema}/(Tables|Views|Functions)/.
    Lower-cased table name so it matches parse_synapse_name output."""
    out: set[tuple[str, str]] = set()
    if not WIKI_ROOT.is_dir():
        return out
    for schema_dir in WIKI_ROOT.iterdir():
        if not schema_dir.is_dir():
            continue
        if schema_dir.name.startswith("_"):
            continue
        for sub in ("Tables", "Views", "Functions"):
            d = schema_dir / sub
            if not d.is_dir():
                continue
            for md in d.glob("*.md"):
                if md.name.endswith(".lineage.md"):
                    continue
                if md.name.endswith(".review-needed.md"):
                    continue
                table_lower = md.stem.lower()
                out.add((schema_dir.name, table_lower))
    return out


# Match a deploy-index row of the form:
#   | [Schema.Object](Tables/Object.md) | Deployed (Batch 9) — 2026-05-03|
DEPLOY_ROW_RE = re.compile(
    r"^\|\s*\[(?P<schema>[^.\]]+)\.(?P<obj>[^\]]+)\]\([^)]+\)\s*\|\s*(?P<status_block>.*?)\s*\|?\s*$"
)
DEPLOY_STATUS_RE = re.compile(
    r"^(Deployed|Failed|Stub only|Generated|Pending|Stale)\b",
    re.I,
)


def scan_deploy_indices() -> dict[tuple[str, str], str]:
    """Return {(synapse_schema_folder, synapse_table_lower) -> status_label}.

    Only scans `_deploy-index.md` under `knowledge/synapse/Wiki/` (Synapse
    universe). The ProdSchemas indices reference upstream production wikis
    on a separate deploy track (bronze leg) and aren't part of this gate.
    """
    out: dict[tuple[str, str], str] = {}
    if not WIKI_ROOT.is_dir():
        return out
    for idx in WIKI_ROOT.glob("*/_deploy-index.md"):
        schema_folder = idx.parent.name
        try:
            text = idx.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line in text.splitlines():
            m = DEPLOY_ROW_RE.match(line)
            if not m:
                continue
            obj = m.group("obj").strip()
            status_block = m.group("status_block").strip()
            sm = DEPLOY_STATUS_RE.match(status_block)
            if not sm:
                continue
            status = sm.group(1).strip()
            # Normalise capitalisation
            status = {
                "deployed": "Deployed",
                "failed": "Failed",
                "stub only": "Stub only",
                "generated": "Generated",
                "pending": "Pending",
                "stale": "Stale",
            }.get(status.lower(), status)
            out[(schema_folder, obj.lower())] = status
    return out


def scan_propagation_progress() -> dict[str, dict]:
    """Return {uc_fqn -> {'run': True, 'failed_stmts': N}}.

    Looks for `*propagation-progress*.json` anywhere under `knowledge/`.
    Each file is expected to be a JSON dict/list with per-statement records;
    we extract any `target` or `uc_table` field and an `error` / `status`
    field. Missing/malformed files are skipped silently — propagation runs
    with this naming convention may not yet exist.
    """
    out: dict[str, dict] = {}
    progress_files = list((REPO / "knowledge").rglob("*propagation-progress*.json"))
    progress_files += list((REPO / "knowledge").rglob("*propagation_progress*.json"))
    for p in progress_files:
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        # Normalise to a list of statement records
        records: list = []
        if isinstance(data, list):
            records = data
        elif isinstance(data, dict):
            for key in ("statements", "records", "results", "batches", "log"):
                if isinstance(data.get(key), list):
                    records = data[key]
                    break
        for rec in records:
            if not isinstance(rec, dict):
                continue
            fqn = (
                rec.get("uc_fqn")
                or rec.get("target")
                or rec.get("uc_table")
                or rec.get("table")
                or ""
            ).strip().lower()
            if not fqn:
                continue
            entry = out.setdefault(fqn, {"run": True, "failed_stmts": 0})
            status = (rec.get("status") or "").lower()
            err = rec.get("error") or rec.get("error_message") or ""
            if status in {"failed", "error"} or err:
                entry["failed_stmts"] += 1
    return out


# ----------------------------------------------------------------------------
# Cascade classification
# ----------------------------------------------------------------------------
def _name_token_match(name_lower: str, keyword: str) -> bool:
    """True if `keyword` appears as its own _-delimited token in name (case
    already lowered). Avoids false positives like `holding` matching `hold`.
    """
    tokens = re.split(r"[_.]", name_lower)
    return keyword in tokens


def _matches_glob(name: str, pattern: str) -> bool:
    """fnmatch with case-insensitive comparison."""
    return fnmatch.fnmatchcase(name.lower(), pattern.lower())


def classify(
    row: dict,
    deploy_index: dict[tuple[str, str], str],
    wiki_files: set[tuple[str, str]],
    progress: dict[str, dict],
    config: dict,
) -> tuple[bool, str, str, dict]:
    """Apply the per-table exclude cascade. Returns (excluded, reason,
    category, extras). Schema-level filtering (HARD DROP) is handled
    upstream by `should_drop_schema()` — by the time we get here, every
    row is in a candidate-in-scope schema.

    Default verdict is `excluded=false`. Tags only fire for table-specific
    reasons (failures, name patterns, explicit blacklist, foreign-federation,
    empty). The user's pivot filters on `excluded=false` for the true %.
    """
    catalog = row["catalog_name"]
    schema = row["schema_name"]
    obj = row["object_name"]
    obj_lower = obj.lower()
    obj_type = (row["object_type"] or "").upper()

    syn_schema, syn_table = parse_synapse_name(obj)
    fqn = f"{catalog}.{schema}.{obj}".lower()

    deploy_status = ""
    if syn_schema and syn_table:
        deploy_status = deploy_index.get((syn_schema, syn_table), "")

    wiki_authored = bool(syn_schema) and (syn_schema, syn_table) in wiki_files

    prog_entry = progress.get(fqn)
    propagation_run = prog_entry is not None
    propagation_failed_stmts = prog_entry["failed_stmts"] if prog_entry else 0

    extras = {
        "synapse_schema": syn_schema,
        "synapse_table": syn_table,
        "wiki_authored": "true" if wiki_authored else "false",
        "deploy_status": deploy_status,
        "propagation_run": "true" if propagation_run else "false",
        "propagation_failed_stmts": propagation_failed_stmts,
    }

    # "Deploy overrides blacklist" — if we explicitly authored / deployed
    # this object it counts as in scope, regardless of name patterns or
    # explicit-blacklist membership. Universal exclude reasons (foreign,
    # empty, deploy-failed, propagation-failed) still apply.
    deploy_protects = deploy_status in {"Deployed", "Generated"}

    # --- Universal table-level excludes (deploy_protects does NOT bypass) ---

    # Foreign federation tables — we have SELECT but not MODIFY, no point
    # measuring coverage on them.
    if obj_type in {"FOREIGN", "FOREIGN_TABLE"}:
        return True, "foreign_federation_table", "infrastructure", extras

    # Empty object — 0 columns, nothing to comment on.
    if row["total_columns"] == 0:
        return True, "empty_object", "no_columns", extras

    # Deploy-index outcomes (Synapse universe only — tables we explicitly
    # tried to author/deploy and failed).
    if deploy_status == "Failed":
        return True, "wiki_deploy_failed", "wiki_failure", extras
    if deploy_status == "Stub only":
        return True, "wiki_stub_only", "stub_no_uc_target", extras

    # Downstream propagation failed for this object (e.g. PERMISSION_DENIED).
    if propagation_failed_stmts > 0:
        return True, "propagation_failed", "propagation_failure", extras

    # --- Pattern / blacklist excludes (deploy_protects bypasses these) ---

    if not deploy_protects:
        # 8-digit date suffix (frozen point-in-time snapshots).
        if DATE_8DIGIT_RE.search(obj_lower) or DATE_DASHED_RE.search(obj_lower):
            return True, "name_pattern_pruned_date", "pruned_pattern", extras

        # Keyword / version-suffix pruning. Tokenized to avoid false
        # positives like `holding_*` matching `hold`.
        for kw in PRUNED_KEYWORDS:
            if _name_token_match(obj_lower, kw):
                return True, "name_pattern_pruned_keyword", "pruned_pattern", extras
        if VERSION_SUFFIX_RE.search(obj_lower):
            return True, "name_pattern_pruned_keyword", "pruned_pattern", extras

        # Config name_patterns globs (Synapse-side casing).
        check_name = syn_table if syn_table else obj_lower
        for patt in config["name_patterns"]:
            if _matches_glob(check_name, patt):
                return True, "name_pattern_pruned_keyword", "pruned_pattern", extras

        # Dev prefixes (legacy scratch tables).
        for prefix in DEV_PREFIXES:
            if obj_lower.startswith(prefix):
                return True, "name_pattern_pruned_dev_prefix", "pruned_pattern", extras

        # External_* (bronze-leg pipeline owns these — they're documented
        # via the production source-DB wikis under knowledge/ProdSchemas/).
        if EXTERNAL_PREFIX_RE.match(syn_table or ""):
            return True, "name_pattern_pruned_external", "pruned_pattern", extras

        # Explicit Synapse-side blacklist (e.g. BI_DB_DDR_CID_Level
        # decommissioned, BI_DB_DDR_Daily_Aggregated deferred).
        if syn_schema and syn_table:
            for bl_schema, bl_table in config["explicit_blacklist"]:
                if (syn_schema.lower() == bl_schema.lower()
                    and syn_table.lower() == bl_table.lower()):
                    return True, "wiki_explicit_blacklist", "blacklisted", extras
            # Schema-level Synapse blacklist (DWH_staging, Dealing_staging,
            # CopyFromLake) — applies when the gold-prefix parser places
            # the row in a Synapse-side blacklisted schema.
            for bl_schema in config["schema_blacklist"]:
                if syn_schema.lower() == bl_schema.lower():
                    return True, "wiki_explicit_blacklist", "blacklisted", extras

    # In scope — what the pivot's "true %" measures.
    return False, "", "", extras


# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------
OUTPUT_FIELDS = [
    "catalog_name", "schema_name", "object_name", "object_type",
    "total_columns", "columns_with_comments", "pct_with_comments",
    "synapse_schema", "synapse_table",
    "wiki_authored", "deploy_status",
    "propagation_run", "propagation_failed_stmts",
    "excluded", "exclude_reason", "exclude_category",
]


def write_csv(out_path: Path, rows: list[dict]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=OUTPUT_FIELDS)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in OUTPUT_FIELDS})


def print_summary(rows: list[dict],
                  dropped_by_schema: dict[tuple[str, str], int] | None = None) -> None:
    """stderr summary — schema drops, exclude reasons, in-scope coverage."""
    print("", file=sys.stderr)
    print("=" * 72, file=sys.stderr)
    print(f"Total UC objects in output CSV:  {len(rows)}", file=sys.stderr)

    if dropped_by_schema:
        n = sum(dropped_by_schema.values())
        print(f"\nHARD-DROPPED before output ({n} rows from "
              f"{len(dropped_by_schema)} schemas — _stg / system / "
              f"information_schema):", file=sys.stderr)
        for (cat, sch), cnt in sorted(dropped_by_schema.items(), key=lambda x: -x[1])[:15]:
            print(f"  {cat}.{sch:<40} {cnt:>5}", file=sys.stderr)
        if len(dropped_by_schema) > 15:
            print(f"  ... and {len(dropped_by_schema) - 15} more", file=sys.stderr)

    in_scope = [r for r in rows if r["excluded"] != "true"]
    excluded = [r for r in rows if r["excluded"] == "true"]

    print(f"\nIn-scope rows:   {len(in_scope):>6}", file=sys.stderr)
    print(f"Excluded rows:   {len(excluded):>6}", file=sys.stderr)

    if excluded:
        by_reason: dict[str, int] = {}
        for r in excluded:
            by_reason[r["exclude_reason"]] = by_reason.get(r["exclude_reason"], 0) + 1
        print("\nExclude reasons (per-table tags only):", file=sys.stderr)
        for reason in sorted(by_reason, key=lambda r: -by_reason[r]):
            print(f"  {reason:<34} {by_reason[reason]:>5}", file=sys.stderr)

    if in_scope:
        total_cols = sum(r["total_columns"] for r in in_scope)
        commented_cols = sum(r["columns_with_comments"] for r in in_scope)
        pct = round(commented_cols * 100 / total_cols, 2) if total_cols else 0.0
        full_coverage = sum(1 for r in in_scope if r["total_columns"] > 0
                            and r["columns_with_comments"] == r["total_columns"])
        print("", file=sys.stderr)
        print("In-scope coverage (the 'true %' your pivot measures):", file=sys.stderr)
        print(f"  Objects in scope:           {len(in_scope):>6}", file=sys.stderr)
        print(f"  Objects fully covered:      {full_coverage:>6}  "
              f"({round(full_coverage*100/len(in_scope), 1)}%)", file=sys.stderr)
        print(f"  Total columns in scope:     {total_cols:>6}", file=sys.stderr)
        print(f"  Columns with UC comments:   {commented_cols:>6}", file=sys.stderr)
        print(f"  Column-level coverage:      {pct:>6}%", file=sys.stderr)

        # Per-schema breakdown of in-scope coverage so the user can see at
        # a glance which schemas are dragging the % down.
        by_sch: dict[tuple[str, str], dict] = {}
        for r in in_scope:
            key = (r["catalog_name"], r["schema_name"])
            d = by_sch.setdefault(key, {"objs": 0, "cols": 0, "commented": 0})
            d["objs"] += 1
            d["cols"] += r["total_columns"]
            d["commented"] += r["columns_with_comments"]
        print("\nIn-scope schemas (by column count, top 25):", file=sys.stderr)
        print(f"  {'schema':<46} {'objs':>5} {'cols':>6} {'cmt':>6} {'%':>5}",
              file=sys.stderr)
        for (cat, sch), d in sorted(by_sch.items(), key=lambda x: -x[1]["cols"])[:25]:
            sch_pct = round(d["commented"] * 100 / d["cols"], 1) if d["cols"] else 0.0
            print(f"  {cat}.{sch:<{46-len(cat)-1}} {d['objs']:>5} "
                  f"{d['cols']:>6} {d['commented']:>6} {sch_pct:>4}%",
                  file=sys.stderr)
    print("=" * 72, file=sys.stderr)


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-fetch", action="store_true",
                    help="Skip the UC re-fetch and re-classify against the "
                         "last cached pull (knowledge/.uc_propagation_status_raw.csv).")
    ap.add_argument("--out", type=Path,
                    default=REPO / "knowledge" / "uc_propagation_status.csv",
                    help="Output CSV path. Default: knowledge/uc_propagation_status.csv")
    args = ap.parse_args()

    cache_path = REPO / "knowledge" / ".uc_propagation_status_raw.csv"

    # --- Phase 1: UC inventory ---
    if args.no_fetch:
        print(f"--no-fetch: loading cached inventory from "
              f"{cache_path.relative_to(REPO).as_posix()}", file=sys.stderr)
        rows = load_raw_cache(cache_path)
    else:
        print("Fetching UC inventory ...", file=sys.stderr)
        conn = _connect()
        if conn is None:
            print("ERROR: could not connect to Databricks. Is "
                  "databricks-sql-connector installed?", file=sys.stderr)
            return 3
        try:
            rows = fetch_uc_inventory(conn)
        finally:
            conn.close()
        save_raw_cache(rows, cache_path)
        print(f"  Cached raw pull -> {cache_path.relative_to(REPO).as_posix()} "
              f"({len(rows)} rows)", file=sys.stderr)

    # --- Phase 2: load classification inputs ---
    print("Loading local artifacts ...", file=sys.stderr)
    config = load_config()
    deploy_index = scan_deploy_indices()
    wiki_files = scan_wiki_authored()
    progress = scan_propagation_progress()
    print(f"  config: {len(config['name_patterns'])} name patterns, "
          f"{len(config['explicit_blacklist'])} explicit blacklist entries, "
          f"{len(config['schema_blacklist'])} schema blacklist entries",
          file=sys.stderr)
    print(f"  deploy-index entries: {len(deploy_index)}", file=sys.stderr)
    print(f"  wiki .md files:       {len(wiki_files)}", file=sys.stderr)
    print(f"  propagation runs:     {len(progress)}", file=sys.stderr)

    # --- Phase 3: drop schema-level HARD-DROP rows, then classify ---
    print("Classifying ...", file=sys.stderr)
    dropped_by_schema: dict[tuple[str, str], int] = {}
    enriched: list[dict] = []
    for r in rows:
        cat, sch = r["catalog_name"], r["schema_name"]
        if should_drop_schema(cat, sch):
            dropped_by_schema[(cat, sch)] = dropped_by_schema.get((cat, sch), 0) + 1
            continue
        excluded, reason, category, extras = classify(
            r, deploy_index, wiki_files, progress, config,
        )
        total = r["total_columns"]
        commented = r["columns_with_comments"]
        pct = round(commented * 100 / total) if total else 0
        enriched.append({
            **r,
            **extras,
            "pct_with_comments": pct,
            "excluded": "true" if excluded else "false",
            "exclude_reason": reason,
            "exclude_category": category,
        })

    n_dropped = sum(dropped_by_schema.values())
    print(f"  Dropped {n_dropped} rows from {len(dropped_by_schema)} HARD-DROP "
          f"schemas (_stg / system / information_schema)", file=sys.stderr)

    # --- Phase 4: write CSV + summary ---
    out_abs = args.out.resolve()
    write_csv(out_abs, enriched)
    try:
        out_disp = out_abs.relative_to(REPO).as_posix()
    except ValueError:
        out_disp = str(out_abs)
    print(f"\nWrote {out_disp} "
          f"({len(enriched)} rows; {n_dropped} schema-dropped not included)",
          file=sys.stderr)
    print_summary(enriched, dropped_by_schema)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
