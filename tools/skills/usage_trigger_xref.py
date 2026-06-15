#!/usr/bin/env python3
"""
Cross-reference ad-hoc Databricks usage against deployed skill triggers + required_tables
to surface trigger gaps, coverage gaps, and Genie-space registration mismatches.

Pulls `system.query.history` filtered to interactive client_applications (Genie Space,
SQL Editor, MCP) over a configurable lookback window. Parses each SQL for table FQNs
and column tokens. Cross-references against every YAML-frontmatter skill in
`knowledge/skills/**/*.md` (hubs + sub-skills). Emits four gap classes:

  A — Hub trigger gap     : a sub-skill OWNS a heavily-used table but its hub has
                             no trigger matching the user vocabulary against that table.
                             ACTION: promote phrases to hub triggers.
  B — Sub-skill trigger gap: a sub-skill BODY mentions a column/concept that real
                             users query, but the sub-skill triggers don't include it.
                             ACTION: add to sub-skill triggers.
  C — Coverage gap        : a table is queried ≥ threshold times but is in no
                             skill's required_tables. ACTION: document the table.
  D — Genie-space mismatch: a Genie space's data_sources.tables (registered) diverge
                             from actually-used tables — over-registered or
                             under-documented.

Auth: same as Cursor MCP — `WorkspaceClient(profile)` from `databricks-sdk`.

Usage:
  python tools/skills/usage_trigger_xref.py                          # 7d default
  python tools/skills/usage_trigger_xref.py --lookback-days 30
  python tools/skills/usage_trigger_xref.py --lookback-days 365      # annual discovery
  python tools/skills/usage_trigger_xref.py --genie-space-id 01f0... # spot-check one space
  python tools/skills/usage_trigger_xref.py --min-query-count 10 --lookback-days 90
  python tools/skills/usage_trigger_xref.py --skip-fetch              # re-classify against cache

Output:
  audits/_usage_trigger_xref_<UTC timestamp>/
    queries.parquet           # raw pulled rows (cached for --skip-fetch)
    report.csv                # one row per gap (all four classes)
    report.md                 # narrative summary grouped by class
    proposed_trigger_diff.json # machine-readable promotions for downstream apply

Exit codes:
  0  — no gaps found
  1  — gaps found (for CI/automation gating)
  2  — error
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"
GENIE_INDEX = SKILLS / "_genie_spaces_index.json"
AUDIT_BASE = ROOT / "audits"

# -----------------------------------------------------------------------------
# SQL — pull ad-hoc traffic from system.query.history
# -----------------------------------------------------------------------------

DEFAULT_CLIENT_APPS = (
    "Databricks SQL Genie Space",
    "Databricks SQL Editor",
    "Databricks SQL MCP",
)

QUERY_HISTORY_SQL = """
SELECT
  statement_id,
  executed_by,
  client_application,
  query_source.genie_space_id AS genie_space_id,
  start_time,
  execution_status,
  total_duration_ms,
  read_bytes,
  read_rows,
  produced_rows,
  statement_text,
  error_message
FROM system.query.history
WHERE start_time >= current_date() - INTERVAL {lookback_days} DAYS
  AND client_application IN ({client_apps_in})
  {extra_filter}
"""


def build_sql(lookback_days: int, client_apps: tuple[str, ...], genie_space_id: str | None) -> str:
    apps_in = ", ".join("'" + a.replace("'", "''") + "'" for a in client_apps)
    extra = ""
    if genie_space_id:
        gid = genie_space_id.replace("'", "''")
        extra = f"AND query_source.genie_space_id = '{gid}'"
    return QUERY_HISTORY_SQL.format(
        lookback_days=int(lookback_days),
        client_apps_in=apps_in,
        extra_filter=extra,
    ).strip()


# -----------------------------------------------------------------------------
# Skill parsing — walk knowledge/skills/**/*.md, extract frontmatter + body
# -----------------------------------------------------------------------------

YAML_FENCE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def parse_skill_file(path: Path) -> dict | None:
    """Return {'id', 'path', 'is_hub', 'triggers', 'required_tables', 'body_lc'} or None."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    m = YAML_FENCE.match(text)
    if not m:
        return None
    fm_raw = m.group(1)
    body = text[m.end():]
    try:
        import yaml
        fm = yaml.safe_load(fm_raw) or {}
    except Exception:
        return None
    if not isinstance(fm, dict):
        return None

    skill_id = str(fm.get("id") or "").strip()
    triggers_raw = fm.get("triggers") or []
    required_tables_raw = fm.get("required_tables") or []
    triggers = [str(t).strip().lower() for t in triggers_raw if isinstance(t, (str, int))]
    required_tables = [str(t).strip().lower() for t in required_tables_raw if isinstance(t, (str, int))]

    return {
        "id": skill_id,
        "path": str(path.relative_to(ROOT)).replace("\\", "/"),
        "is_hub": path.name == "SKILL.md",
        "triggers": triggers,
        "required_tables": required_tables,
        "body_lc": body.lower(),
    }


def load_all_skills(skill_root: Path) -> list[dict]:
    out: list[dict] = []
    if not skill_root.exists():
        return out
    for p in skill_root.rglob("*.md"):
        # skip workbench docs that start with _
        if p.name.startswith("_"):
            continue
        parsed = parse_skill_file(p)
        if parsed:
            out.append(parsed)
    return out


# -----------------------------------------------------------------------------
# SQL vocabulary extraction
# -----------------------------------------------------------------------------

TABLE_FQN_RE = re.compile(
    r"\bmain\.([a-z0-9_]+)\.([a-z0-9_]+)\b",
    re.IGNORECASE,
)

# Identifier tokens we want to extract (column names, concept names)
# Skip very common SQL keywords + extremely short tokens.
SQL_STOPWORDS = frozenset(
    """
    select from where and or not case when then else end as is null order group
    by having limit distinct count sum avg max min desc asc left right inner
    outer join on union all with cast int bigint smallint tinyint varchar string
    char date timestamp double float decimal boolean true false like ilike in
    between interval current_date current_timestamp current_user coalesce nvl
    round floor ceil ceiling abs date_sub date_add date_format date_trunc
    to_date to_timestamp date_diff datediff substring length lower upper trim
    ltrim rtrim split concat collect_list collect_set array struct map filter
    transform exists reduce aggregate first last any_value dense_rank
    row_number rank over partition window lateral explode using describe show
    create alter drop insert update delete table view function set values
    if elseif elif begin commit rollback transaction yes no main system
    information_schema bi_db dwh etoro_kpi etoro_kpi_prep etoro_kpi_stg
    bi_compliance bi_compliance_stg compliance regtech billing general
    wallet emoney pii_data pii_data_stg de_output de_output_stg
    gold bronze silver dbo gold_sql_dp_prod_we sql_dp_prod_we
    sql dp prod we bronze_etoro bronze_etorogeneral gold_etoro mart
    tab1 t1 t2 t3 t4 col1 col2 cnt
    name country region date time year month day week hour minute second
    type status code value amount total count id uid key flag active inactive
    yes no none null true false created updated modified deleted enabled
    disabled current previous next first last min max desc asc number text
    dateid fromdateid todateid datetime utc local timezone tz user users
    new old current default test prod stage staging dev development production
    try_divide try_cast try_subtract try_add try_multiply try_to_timestamp
    read_files read_csv read_json read_parquet skiprows multiline header
    delimiter escape quote charset compression option options recursive
    binary parquet csv tsv json xml zstd snappy lzo deflate gzip bzip2
    quarter milli micro nano second_micro hour_micro day_micro
    israel normal admin support staging stage real demo test1 test2 sample
    data_rooms volumes catalog catalogs schemas tables columns metric_view
    metric_views functions procedures pipelines jobs warehouses clusters
    instances pools repos workspaces databases reads writes nullable
    """.split()
)

TOKEN_RE = re.compile(r"\b[a-zA-Z_][a-zA-Z_0-9]{3,}\b")


def extract_tables(sql: str) -> set[str]:
    """Extract every distinct main.<schema>.<table> FQN, lower-cased, backticks stripped."""
    clean = sql.replace("`", "")
    return {f"main.{m.group(1).lower()}.{m.group(2).lower()}" for m in TABLE_FQN_RE.finditer(clean)}


def extract_tokens(sql: str) -> set[str]:
    """Identifier tokens, lower-cased, stop-words removed, ≥4 chars."""
    clean = sql.replace("`", " ")
    out = set()
    for m in TOKEN_RE.finditer(clean):
        t = m.group(0).lower()
        if t in SQL_STOPWORDS:
            continue
        out.add(t)
    return out


# -----------------------------------------------------------------------------
# Skill matching helpers
# -----------------------------------------------------------------------------

def skills_owning_table(skills: list[dict], table_fqn: str) -> list[dict]:
    """All skills whose required_tables list contains `table_fqn` (case-insensitive)."""
    t = table_fqn.lower()
    return [s for s in skills if t in s["required_tables"]]


def skills_with_token_in_triggers(skills: list[dict], token: str) -> list[dict]:
    """All skills whose triggers contain `token` (as substring of any trigger)."""
    t = token.lower()
    return [s for s in skills if any(t in trg or trg in t for trg in s["triggers"])]


def skills_with_token_in_body(skills: list[dict], token: str) -> list[dict]:
    """All skills whose body mentions `token` (case-insensitive substring)."""
    t = token.lower()
    return [s for s in skills if t in s["body_lc"]]


def hub_for_skill(skills: list[dict], skill: dict) -> dict | None:
    """If `skill` is a sub-skill, return the SKILL.md in the same folder. Else None."""
    if skill["is_hub"]:
        return None
    folder = Path(skill["path"]).parent.as_posix()
    for s in skills:
        if s["is_hub"] and Path(s["path"]).parent.as_posix() == folder:
            return s
    return None


# -----------------------------------------------------------------------------
# Databricks SQL — pull via WorkspaceClient (same auth as MCP)
# -----------------------------------------------------------------------------

def warehouse_id_from_env() -> str:
    path = os.environ.get("DATABRICKS_HTTP_PATH", "")
    m = re.search(r"/warehouses/([a-f0-9]+)", path, re.I)
    if m:
        return m.group(1)
    wid = (os.environ.get("DATABRICKS_WAREHOUSE_ID") or "").strip()
    if wid:
        return wid
    return "208214768b0e0308"


def profile_from_env() -> str:
    return (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "guyman"
    )


def run_sql(profile: str, warehouse_id: str, sql_text: str, wait_timeout: str = "50s",
            poll_deadline_sec: float = 1200.0) -> tuple[list[str], list[list]]:
    try:
        from databricks.sdk import WorkspaceClient
        from databricks.sdk.service.sql import StatementState
    except ImportError:
        print("ERROR: pip install databricks-sdk", file=sys.stderr)
        sys.exit(2)

    w = WorkspaceClient(profile=profile)
    print(f"[dbx] profile={profile} warehouse={warehouse_id}", file=sys.stderr)

    resp = w.statement_execution.execute_statement(
        warehouse_id=warehouse_id,
        statement=sql_text,
        wait_timeout=wait_timeout,
    )
    sid = resp.statement_id
    state = resp.status.state
    deadline = time.time() + poll_deadline_sec

    while state in (StatementState.PENDING, StatementState.RUNNING):
        if time.time() > deadline:
            raise TimeoutError(f"statement {sid} did not finish before {poll_deadline_sec}s")
        time.sleep(3.0)
        resp = w.statement_execution.get_statement(sid)
        state = resp.status.state

    if state != StatementState.SUCCEEDED:
        err = resp.status.error
        raise RuntimeError(f"SQL FAILED state={state} err={err.message if err else 'unknown'}")

    cols = [c.name for c in resp.manifest.schema.columns]
    rows = (resp.result.data_array if resp.result else []) or []

    # Stream the rest if there are chunks
    total_chunks = resp.manifest.total_chunk_count or 1
    for i in range(1, total_chunks):
        chunk = w.statement_execution.get_statement_result_chunk_n(sid, i)
        rows.extend(chunk.data_array or [])

    return cols, rows


# -----------------------------------------------------------------------------
# Pipeline
# -----------------------------------------------------------------------------

def build_table_to_skill_index(skills: list[dict]) -> dict[str, list[dict]]:
    idx: dict[str, list[dict]] = defaultdict(list)
    for s in skills:
        for t in s["required_tables"]:
            idx[t].append(s)
    return idx


def classify_gaps(
    rows: list[dict],
    skills: list[dict],
    min_count: int,
) -> dict[str, list[dict]]:
    """Return {'A': [...], 'B': [...], 'C': [...], 'D': [...]}."""

    # Aggregate per-table + per-token + per-(genie_space, table) counters
    table_counts: Counter = Counter()
    table_users: dict[str, set[str]] = defaultdict(set)
    token_counts: Counter = Counter()
    token_to_tables: dict[str, set[str]] = defaultdict(set)
    space_to_tables: dict[str, Counter] = defaultdict(Counter)

    failed_per_token: Counter = Counter()

    for r in rows:
        sql = (r.get("statement_text") or "").strip()
        if not sql:
            continue
        tables = extract_tables(sql)
        tokens = extract_tokens(sql)
        user = (r.get("executed_by") or "").lower()
        space = r.get("genie_space_id") or ""
        is_failed = (r.get("execution_status") or "").upper() == "FAILED"

        for t in tables:
            table_counts[t] += 1
            if user:
                table_users[t].add(user)
            if space:
                space_to_tables[space][t] += 1

        # Tokens — count once per statement (set semantics)
        for tok in tokens:
            token_counts[tok] += 1
            token_to_tables[tok].update(tables)
            if is_failed:
                failed_per_token[tok] += 1

    table_to_skill = build_table_to_skill_index(skills)

    A: list[dict] = []  # hub-trigger gaps
    B: list[dict] = []  # sub-skill-trigger gaps
    C: list[dict] = []  # coverage gaps
    D: list[dict] = []  # Genie space mismatches

    # ---- Class C: tables hit ≥min_count but not owned by any skill
    for table, cnt in table_counts.most_common():
        if cnt < min_count:
            continue
        if not table_to_skill.get(table):
            C.append({
                "class": "C",
                "table_fqn": table,
                "query_count": cnt,
                "unique_users": len(table_users[table]),
                "suggested_action": "DOCUMENT — table queried but not in any skill's required_tables",
                "owning_skill_id": "",
                "hub_skill_id": "",
                "phrase": "",
            })

    # A token is a promotable concept only if it doesn't co-occur with too many tables
    # (universal identifiers like 'realcid' / 'cid' / 'accountid' co-occur with hundreds
    # of tables and are not useful as triggers — they match everything).
    MAX_TABLE_BREADTH = 25

    # ---- Class A: vocabulary used heavily on a table THAT IS documented in a sub-skill,
    #               but the matching hub has no trigger that overlaps the user vocab.
    #               DEDUPED: one row per (phrase, hub_skill_id) — most-strongly-linked sub-skill wins.
    a_best: dict[tuple[str, str], dict] = {}
    for tok, cnt in token_counts.most_common():
        if cnt < min_count:
            continue
        if len(tok) < 6:
            continue
        associated_tables = token_to_tables.get(tok, set())
        if not associated_tables:
            continue
        if len(associated_tables) > MAX_TABLE_BREADTH:
            continue
        # Sub-skills that own AT LEAST ONE of the tables this token co-occurs with
        for sub in (s for s in skills if not s["is_hub"]):
            sub_tables = set(sub["required_tables"])
            overlap = associated_tables & sub_tables
            if not overlap:
                continue
            hub = hub_for_skill(skills, sub)
            if hub is None:
                continue
            hub_has_trigger = any(tok in trg or trg in tok for trg in hub["triggers"])
            if hub_has_trigger:
                continue
            key = (tok, hub["id"])
            existing = a_best.get(key)
            if existing is None or len(overlap) > existing["_overlap_size"]:
                a_best[key] = {
                    "class": "A",
                    "phrase": tok,
                    "query_count": cnt,
                    "unique_users": "",
                    "owning_skill_id": sub["id"],
                    "hub_skill_id": hub["id"],
                    "table_fqn": ", ".join(sorted(overlap)[:3]),
                    "suggested_action": f"PROMOTE phrase '{tok}' to hub '{hub['id']}' triggers (used on {len(overlap)} of its owned tables)",
                    "_overlap_size": len(overlap),
                }
    for row in a_best.values():
        row.pop("_overlap_size", None)
        A.append(row)

    # ---- Class B: phrase appears in skill body AND on a table the skill owns, but
    #               NOT in that skill's triggers. Requires both signals to avoid the
    #               "every skill mentions realcid" explosion.
    #               DEDUPED: one row per (phrase, skill_id), highest-overlap wins.
    b_best: dict[tuple[str, str], dict] = {}
    for tok, cnt in token_counts.most_common():
        if cnt < min_count:
            continue
        if len(tok) < 6:
            continue
        associated_tables = token_to_tables.get(tok, set())
        if not associated_tables:
            continue
        if len(associated_tables) > MAX_TABLE_BREADTH:
            continue
        for s in skills:
            sub_tables = set(s["required_tables"])
            overlap = associated_tables & sub_tables
            if not overlap:
                continue
            if tok not in s["body_lc"]:
                continue
            if any(tok in trg or trg in tok for trg in s["triggers"]):
                continue
            key = (tok, s["id"])
            existing = b_best.get(key)
            if existing is None or len(overlap) > existing["_overlap_size"]:
                b_best[key] = {
                    "class": "B",
                    "phrase": tok,
                    "query_count": cnt,
                    "unique_users": "",
                    "owning_skill_id": s["id"],
                    "hub_skill_id": "",
                    "table_fqn": ", ".join(sorted(overlap)[:3]),
                    "suggested_action": f"ADD phrase '{tok}' to skill '{s['id']}' triggers (in body + queried on {len(overlap)} owned tables)",
                    "_overlap_size": len(overlap),
                }
    for row in b_best.values():
        row.pop("_overlap_size", None)
        B.append(row)

    # ---- Class D: Genie-space mismatch (registered vs actually-used tables)
    genie_index = []
    if GENIE_INDEX.exists():
        try:
            genie_index = json.loads(GENIE_INDEX.read_text(encoding="utf-8"))
        except Exception:
            genie_index = []
    registered_by_space: dict[str, set[str]] = {}
    space_name: dict[str, str] = {}
    for sp in genie_index:
        sid = sp.get("space_id") or ""
        name = sp.get("title") or sp.get("name") or ""
        regs = sp.get("tables") or []
        space_name[sid] = name
        registered_by_space[sid] = {("main." + t.lower()) if not t.lower().startswith("main.") else t.lower()
                                    for t in regs}

    for space_id, table_counter in space_to_tables.items():
        if not space_id:
            continue
        actual_tables = set(table_counter.keys())
        registered = registered_by_space.get(space_id, set())
        unused_registered = registered - actual_tables
        unregistered_used = actual_tables - registered
        used_not_documented = {t for t in actual_tables if not table_to_skill.get(t)}
        if not (unused_registered or unregistered_used or used_not_documented):
            continue
        D.append({
            "class": "D",
            "phrase": "",
            "query_count": sum(table_counter.values()),
            "unique_users": "",
            "owning_skill_id": "",
            "hub_skill_id": "",
            "table_fqn": "",
            "genie_space_id": space_id,
            "genie_space_name": space_name.get(space_id, ""),
            "registered_table_count": len(registered),
            "actual_used_table_count": len(actual_tables),
            "unused_registered_count": len(unused_registered),
            "unregistered_used_count": len(unregistered_used),
            "used_not_documented_count": len(used_not_documented),
            "top_used_tables": ", ".join(t for t, _ in table_counter.most_common(5)),
            "unused_registered_sample": ", ".join(sorted(unused_registered)[:5]),
            "unregistered_used_sample": ", ".join(sorted(unregistered_used)[:5]),
            "used_not_documented_sample": ", ".join(sorted(used_not_documented)[:5]),
            "suggested_action": "REVIEW Genie space registration alignment + skill documentation",
        })

    return {"A": A, "B": B, "C": C, "D": D}


# -----------------------------------------------------------------------------
# Report writers
# -----------------------------------------------------------------------------

ALL_CLASSES = ("A", "B", "C", "D")

CSV_COLS = [
    "class", "phrase", "table_fqn", "query_count", "unique_users",
    "owning_skill_id", "hub_skill_id", "genie_space_id", "genie_space_name",
    "registered_table_count", "actual_used_table_count",
    "unused_registered_count", "unregistered_used_count", "used_not_documented_count",
    "top_used_tables", "unused_registered_sample", "unregistered_used_sample",
    "used_not_documented_sample", "suggested_action",
]


def write_csv(out_path: Path, gaps: dict[str, list[dict]]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=CSV_COLS, extrasaction="ignore")
        w.writeheader()
        for cls in ALL_CLASSES:
            for row in gaps[cls]:
                w.writerow(row)


def write_md(out_path: Path, gaps: dict[str, list[dict]], meta: dict) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    total = sum(len(gaps[c]) for c in ALL_CLASSES)
    lines: list[str] = []
    lines.append(f"# Usage \u2194 Skills Trigger Cross-Reference Report")
    lines.append("")
    lines.append(f"- Generated: `{meta['generated_at']}`")
    lines.append(f"- Lookback: `{meta['lookback_days']}` days")
    lines.append(f"- Client applications: `{', '.join(meta['client_applications'])}`")
    lines.append(f"- Queries pulled: `{meta['query_count']}`")
    lines.append(f"- Distinct users: `{meta['user_count']}`")
    lines.append(f"- Distinct Genie spaces: `{meta['space_count']}`")
    lines.append(f"- Skills loaded: `{meta['skill_count']}` ({meta['hub_count']} hubs, {meta['sub_count']} sub-skills)")
    lines.append(f"- Min query count for promotion: `{meta['min_query_count']}`")
    lines.append("")
    lines.append(f"**Total gaps: {total}** (A={len(gaps['A'])}, B={len(gaps['B'])}, C={len(gaps['C'])}, D={len(gaps['D'])})")
    lines.append("")

    descriptions = {
        "A": "**Class A — Hub trigger gap**: Sub-skill owns a heavily-used table, but its hub has no trigger matching the user vocabulary. **Action**: promote phrase to hub triggers.",
        "B": "**Class B — Sub-skill trigger gap**: Skill body mentions the phrase, but the skill triggers don't. **Action**: add phrase to skill triggers.",
        "C": "**Class C — Coverage gap**: Table queried \u2265 threshold times but is in no skill's `required_tables`. **Action**: document the table in the appropriate skill.",
        "D": "**Class D — Genie-space mismatch**: A Genie space's registered tables diverge from actually-used tables. **Action**: realign space data_sources and/or skill documentation.",
    }

    for cls in ALL_CLASSES:
        lines.append(f"## Class {cls}")
        lines.append("")
        lines.append(descriptions[cls])
        lines.append("")
        if not gaps[cls]:
            lines.append("_(no gaps)_")
            lines.append("")
            continue
        if cls == "D":
            lines.append("| Genie space | Queries | Registered | Used | Unused regs | Unregistered used | Used not documented | Top used tables |")
            lines.append("|---|---:|---:|---:|---:|---:|---:|---|")
            for r in sorted(gaps[cls], key=lambda x: -int(x.get("query_count", 0)))[:30]:
                lines.append(
                    f"| `{r.get('genie_space_id', '')}` {r.get('genie_space_name', '')} "
                    f"| {r.get('query_count', '')} "
                    f"| {r.get('registered_table_count', '')} "
                    f"| {r.get('actual_used_table_count', '')} "
                    f"| {r.get('unused_registered_count', '')} "
                    f"| {r.get('unregistered_used_count', '')} "
                    f"| {r.get('used_not_documented_count', '')} "
                    f"| {r.get('top_used_tables', '')} |"
                )
        else:
            lines.append("| Phrase / Table | Queries | Owning skill | Hub | Action |")
            lines.append("|---|---:|---|---|---|")
            for r in sorted(gaps[cls], key=lambda x: -int(x.get("query_count", 0)))[:50]:
                key = r.get("phrase") or r.get("table_fqn", "")
                lines.append(
                    f"| `{key}` "
                    f"| {r.get('query_count', '')} "
                    f"| {r.get('owning_skill_id', '')} "
                    f"| {r.get('hub_skill_id', '')} "
                    f"| {r.get('suggested_action', '')} |"
                )
            if len(gaps[cls]) > 50:
                lines.append("")
                lines.append(f"_({len(gaps[cls]) - 50} more rows in `report.csv`)_")
        lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")


def write_diff_json(out_path: Path, gaps: dict[str, list[dict]]) -> None:
    """Machine-readable promotions for downstream auto-apply."""
    hub_promotions: dict[str, set[str]] = defaultdict(set)
    sub_promotions: dict[str, set[str]] = defaultdict(set)
    for r in gaps["A"]:
        hub_promotions[r["hub_skill_id"]].add(r["phrase"])
    for r in gaps["B"]:
        sub_promotions[r["owning_skill_id"]].add(r["phrase"])
    payload = {
        "hub_trigger_promotions": {k: sorted(v) for k, v in hub_promotions.items()},
        "sub_trigger_promotions": {k: sorted(v) for k, v in sub_promotions.items()},
        "coverage_gaps": [
            {"table_fqn": r["table_fqn"], "query_count": r["query_count"]}
            for r in gaps["C"]
        ],
        "genie_space_mismatches": [
            {"space_id": r["genie_space_id"], "space_name": r.get("genie_space_name", ""),
             "unused_registered_sample": r.get("unused_registered_sample", ""),
             "unregistered_used_sample": r.get("unregistered_used_sample", ""),
             "used_not_documented_sample": r.get("used_not_documented_sample", "")}
            for r in gaps["D"]
        ],
    }
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--lookback-days", type=int, default=7,
                    help="Lookback window in days (default 7; common: 7, 30, 90, 365)")
    ap.add_argument("--profile", default=None, help="Databricks CLI profile name")
    ap.add_argument("--warehouse-id", default=None, help="SQL warehouse ID")
    ap.add_argument("--output-dir", default=None,
                    help="Output directory (default audits/_usage_trigger_xref_<UTC>)")
    ap.add_argument("--client-applications", nargs="*", default=list(DEFAULT_CLIENT_APPS),
                    help="client_application values to include (default: Genie Space, SQL Editor, MCP)")
    ap.add_argument("--min-query-count", type=int, default=3,
                    help="Minimum query count for a phrase/table to surface as a gap (default 3)")
    ap.add_argument("--genie-space-id", default=None,
                    help="Restrict to a single Genie space (for spot-checks)")
    ap.add_argument("--skill-root", default=str(SKILLS),
                    help="Root directory of skill .md files (default knowledge/skills)")
    ap.add_argument("--skip-fetch", action="store_true",
                    help="Re-classify against cached queries.json from previous run")
    ap.add_argument("--cached-queries-path", default=None,
                    help="Path to cached queries.json (used with --skip-fetch)")
    args = ap.parse_args()

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out_dir = Path(args.output_dir) if args.output_dir else (
        AUDIT_BASE / f"_usage_trigger_xref_{timestamp}"
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    skill_root = Path(args.skill_root).resolve()
    print(f"[skills] root={skill_root}", file=sys.stderr)
    skills = load_all_skills(skill_root)
    hub_count = sum(1 for s in skills if s["is_hub"])
    sub_count = len(skills) - hub_count
    print(f"[skills] loaded {len(skills)} ({hub_count} hubs, {sub_count} sub-skills)", file=sys.stderr)

    cache_path = Path(args.cached_queries_path) if args.cached_queries_path else (out_dir / "queries.json")
    rows: list[dict]

    if args.skip_fetch:
        if not cache_path.exists():
            print(f"ERROR: --skip-fetch but cache not found: {cache_path}", file=sys.stderr)
            return 2
        rows = json.loads(cache_path.read_text(encoding="utf-8"))
        print(f"[fetch] re-using cache: {len(rows)} rows", file=sys.stderr)
    else:
        sql = build_sql(args.lookback_days, tuple(args.client_applications), args.genie_space_id)
        print(f"[fetch] running query ({args.lookback_days}d lookback)...", file=sys.stderr)
        profile = args.profile or profile_from_env()
        warehouse_id = args.warehouse_id or warehouse_id_from_env()
        cols, raw_rows = run_sql(profile, warehouse_id, sql)
        rows = [dict(zip(cols, r)) for r in raw_rows]
        cache_path.write_text(json.dumps(rows, indent=2, default=str), encoding="utf-8")
        print(f"[fetch] pulled {len(rows)} rows -> {cache_path.relative_to(ROOT)}", file=sys.stderr)

    if not rows:
        print("[fetch] no rows in window — nothing to classify", file=sys.stderr)
        return 0

    print(f"[classify] min_query_count={args.min_query_count}", file=sys.stderr)
    gaps = classify_gaps(rows, skills, args.min_query_count)

    user_count = len({(r.get("executed_by") or "").lower() for r in rows if r.get("executed_by")})
    space_count = len({r.get("genie_space_id") for r in rows if r.get("genie_space_id")})

    meta = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "lookback_days": args.lookback_days,
        "client_applications": args.client_applications,
        "min_query_count": args.min_query_count,
        "query_count": len(rows),
        "user_count": user_count,
        "space_count": space_count,
        "skill_count": len(skills),
        "hub_count": hub_count,
        "sub_count": sub_count,
    }

    write_csv(out_dir / "report.csv", gaps)
    write_md(out_dir / "report.md", gaps, meta)
    write_diff_json(out_dir / "proposed_trigger_diff.json", gaps)
    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    total = sum(len(gaps[c]) for c in ALL_CLASSES)
    print(f"[done] {total} gaps  (A={len(gaps['A'])} B={len(gaps['B'])} C={len(gaps['C'])} D={len(gaps['D'])})",
          file=sys.stderr)
    print(f"[done] output -> {out_dir.relative_to(ROOT)}", file=sys.stderr)
    return 0 if total == 0 else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(2)
