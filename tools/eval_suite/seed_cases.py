"""Seed eval cases from the available reference truth sources.

V1 streams:

1. DDR - the 8 etoro_kpi.ddr_* views (email-distributed report).
2. Tableau - top-25 Databricks-backed workbooks by views.
3. Genie benchmarks - every accessible Genie space's `benchmarks.questions[]`.
4. Known failures - the 2026-06-08 routing-failure trio.

For each case we emit a YAML under `tools/eval_suite/cases/`. `expected_value`
starts as `type: PENDING`; the pinning pass (`pin_ground_truth.py`) runs the
SQL once at `asof` and writes the cached `value` back.

Skill coverage tagging: a case is `covered` when at least one
`canonical_tables` entry appears in any skill body, `partial` when the table
appears only in a router file, and `missing` otherwise.

Usage:
    python tools/eval_suite/seed_cases.py --asof 2026-06-08
    python tools/eval_suite/seed_cases.py --asof 2026-06-08 --only ddr
    python tools/eval_suite/seed_cases.py --asof 2026-06-08 --dry-run
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
CASES_DIR = HERE / "cases"
DBX_CLI = Path(r"C:\Users\guyman\databricks-cli-new\databricks.exe")

SKILLS_GLOBS = [
    REPO_ROOT / ".cursor" / "skills",
    Path.home() / ".cursor" / "skills",
    REPO_ROOT / "knowledge" / "skills",
]
TABLEAU_INDEX = REPO_ROOT / "knowledge" / "tableau" / "_index"
DDR_VIEWS_DIR = REPO_ROOT / "knowledge" / "UC_generated" / "etoro_kpi" / "Views"

FQN_RE = re.compile(r"\b(main|hive_metastore)\.([a-z0-9_]+)\.([a-z0-9_]+)\b", re.IGNORECASE)
# Backtick-quoted FQNs: `main`.`etoro_kpi`.`ddr_revenue_v`
FQN_BACKTICK_RE = re.compile(r"`(main|hive_metastore)`\.`([a-z0-9_]+)`\.`([a-z0-9_]+)`", re.IGNORECASE)


def _all_fqns(text: str) -> list[str]:
    out = {".".join(m.groups()).lower() for m in FQN_RE.finditer(text)}
    out.update(".".join(m.groups()).lower() for m in FQN_BACKTICK_RE.finditer(text))
    return sorted(out)


# ----------------------------- skill coverage --------------------------------

@dataclass
class SkillCorpus:
    fqn_to_files: dict[str, list[Path]] = field(default_factory=lambda: defaultdict(list))
    file_hubs: dict[Path, str] = field(default_factory=dict)

    def hub_for_fqn(self, fqn: str) -> tuple[str, str] | None:
        files = self.fqn_to_files.get(fqn.lower(), [])
        if not files:
            return None
        for f in files:
            stem = f.stem.lower()
            parent = f.parent.name
            if "router" not in stem and "_index" not in stem:
                return (parent if parent.startswith("domain-") else f.stem, "covered")
        return (self.file_hubs.get(files[0], files[0].stem), "partial")


def build_skill_corpus() -> SkillCorpus:
    corpus = SkillCorpus()
    for root in SKILLS_GLOBS:
        if not root.exists():
            continue
        for md in root.rglob("*.md"):
            try:
                body = md.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            corpus.file_hubs[md] = md.parent.name if md.parent.name.startswith("domain-") else md.stem
            for fqn in _all_fqns(body):
                corpus.fqn_to_files[fqn].append(md)
    return corpus


# ------------------------------- DDR stream ----------------------------------

DDR_QUESTION_TEMPLATES: dict[str, list[dict]] = {
    "ddr_revenue_v": [
        {
            "id_suffix": "total_revenue_total",
            "question": "What was eToro's total revenue on {asof}?",
            "sql": (
                "SELECT SUM(RevenueAmount) AS total_revenue\n"
                "FROM main.etoro_kpi.ddr_revenue_v\n"
                "WHERE Date = DATE'{asof}'\n"
                "  AND IncludedInTotalRevenue = 1"
            ),
            "expected_filters": ["IncludedInTotalRevenue = 1"],
            "anti_sources": ["main.etoro_kpi_prep.v_revenue_conversionfee"],
        },
        {
            "id_suffix": "total_revenue_by_category",
            "question": "Break down eToro's total revenue on {asof} by RevenueMetricCategory.",
            "sql": (
                "SELECT RevenueMetricCategory, SUM(RevenueAmount) AS revenue\n"
                "FROM main.etoro_kpi.ddr_revenue_v\n"
                "WHERE Date = DATE'{asof}'\n"
                "  AND IncludedInTotalRevenue = 1\n"
                "GROUP BY RevenueMetricCategory ORDER BY revenue DESC"
            ),
            "expected_type": "tabular",
            "expected_filters": ["IncludedInTotalRevenue = 1"],
        },
        {
            "id_suffix": "commissions_amount",
            "question": "How much commission revenue did eToro book on {asof}?",
            "sql": (
                "SELECT SUM(RevenueAmount) AS commissions\n"
                "FROM main.etoro_kpi.ddr_revenue_v\n"
                "WHERE Date = DATE'{asof}'\n"
                "  AND Metric = 'FullCommission'"
            ),
        },
    ],
    "ddr_mimo_v": [
        {
            "id_suffix": "total_deposits_usd",
            "question": "What was eToro's total deposit amount in USD on {asof}?",
            "sql": (
                "SELECT SUM(AmountUSD) AS total_deposits_usd\n"
                "FROM main.etoro_kpi.ddr_mimo_v\n"
                "WHERE Date = DATE'{asof}'\n"
                "  AND MIMOAction = 'Deposit'"
            ),
        },
        {
            "id_suffix": "deposits_count",
            "question": "How many deposits landed on {asof} across all platforms?",
            "sql": (
                "SELECT COUNT(*) AS deposit_events\n"
                "FROM main.etoro_kpi.ddr_mimo_v\n"
                "WHERE Date = DATE'{asof}'\n"
                "  AND MIMOAction = 'Deposit'"
            ),
        },
    ],
    "ddr_aum_v": [
        {
            "id_suffix": "total_global_aum",
            "question": "What was eToro's total global AUM on {asof}?",
            "sql": (
                "SELECT SUM(EquityGlobal) AS aum_global\n"
                "FROM main.etoro_kpi.ddr_aum_v\n"
                "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)"
            ),
        },
        {
            "id_suffix": "tp_aum",
            "question": "What was eToro's Trading Platform total equity on {asof}?",
            "sql": (
                "SELECT SUM(EquityTradingPlatform) AS tp_equity\n"
                "FROM main.etoro_kpi.ddr_aum_v\n"
                "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)"
            ),
        },
    ],
    "ddr_pnl_v": [
        {
            "id_suffix": "unrealized_pnl_change",
            "question": "What was the total unrealized P&L change for eToro customers on {asof}?",
            "sql": (
                "SELECT SUM(UnrealizedPnLChange) AS pnl_change\n"
                "FROM main.etoro_kpi.ddr_pnl_v\n"
                "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)"
            ),
        },
        {
            "id_suffix": "realized_net_profit",
            "question": "What was the total realized net profit on closed positions on {asof}?",
            "sql": (
                "SELECT SUM(NetProfit) AS net_profit\n"
                "FROM main.etoro_kpi.ddr_pnl_v\n"
                "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)"
            ),
        },
    ],
    "ddr_trading_volumes_and_amounts_v": [
        {
            "id_suffix": "trading_volume_total",
            "question": "What was eToro's total trading volume on {asof}?",
            "sql": (
                "SELECT SUM(TotalVolume) AS volume\n"
                "FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v\n"
                "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)"
            ),
        },
        {
            "id_suffix": "volume_open",
            "question": "What was the total notional volume of positions opened on {asof}?",
            "sql": (
                "SELECT SUM(VolumeOpen) AS volume_open\n"
                "FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v\n"
                "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)"
            ),
        },
    ],
    "ddr_customer_dailystatus": [
        {
            "id_suffix": "active_traders",
            "question": "How many customers were Active Traders on {asof}?",
            "sql": (
                "SELECT COUNT(DISTINCT RealCID) AS active_traders\n"
                "FROM main.etoro_kpi.ddr_customer_dailystatus\n"
                "WHERE FromDateID <= CAST(REPLACE('{asof}','-','') AS INT)\n"
                "  AND ToDateID >= CAST(REPLACE('{asof}','-','') AS INT)\n"
                "  AND IsActiveTrade = 1"
            ),
            "notes": "ddr_customer_dailystatus is SCD-style with FromDateID/ToDateID. Column is IsActiveTrade (no 'r'), not IsActiveTrader.",
        },
        {
            "id_suffix": "funded_customers",
            "question": "How many funded customers did eToro have on {asof}?",
            "sql": (
                "SELECT COUNT(DISTINCT RealCID) AS funded\n"
                "FROM main.etoro_kpi.ddr_customer_dailystatus\n"
                "WHERE FromDateID <= CAST(REPLACE('{asof}','-','') AS INT)\n"
                "  AND ToDateID >= CAST(REPLACE('{asof}','-','') AS INT)\n"
                "  AND IsFunded = 1"
            ),
        },
    ],
    "ddr_customer_snapshot_scd_v": [
        {
            "id_suffix": "customer_count",
            "question": "How many customers were on the platform as of {asof}?",
            "sql": (
                "SELECT COUNT(*) AS customers\n"
                "FROM main.etoro_kpi.ddr_customer_snapshot_scd_v\n"
                "WHERE FromDateID <= CAST(REPLACE('{asof}','-','') AS INT)\n"
                "  AND ToDateID >= CAST(REPLACE('{asof}','-','') AS INT)"
            ),
        },
        {
            "id_suffix": "valid_customer_count",
            "question": "How many valid customers (IsValidCustomer=1) were on the platform as of {asof}?",
            "sql": (
                "SELECT COUNT(*) AS valid_customers\n"
                "FROM main.etoro_kpi.ddr_customer_snapshot_scd_v\n"
                "WHERE FromDateID <= CAST(REPLACE('{asof}','-','') AS INT)\n"
                "  AND ToDateID >= CAST(REPLACE('{asof}','-','') AS INT)\n"
                "  AND IsValidCustomer = 1"
            ),
        },
    ],
    "ddr_customer_current_flags": [
        {
            "id_suffix": "current_active",
            "question": "How many customers currently have IsActiveTrade=1?",
            "sql": (
                "SELECT COUNT(*) AS active_customers\n"
                "FROM main.etoro_kpi.ddr_customer_current_flags\n"
                "WHERE IsActiveTrade = 1"
            ),
            "notes": "Current-state view; asof is captured but the view always reflects latest.",
        },
        {
            "id_suffix": "current_funded",
            "question": "How many customers currently have IsFunded=1?",
            "sql": (
                "SELECT COUNT(*) AS funded_customers\n"
                "FROM main.etoro_kpi.ddr_customer_current_flags\n"
                "WHERE IsFunded = 1"
            ),
        },
    ],
}

DDR_HUB_DEFAULTS: dict[str, str] = {
    "ddr_revenue_v": "domain-revenue-and-fees",
    "ddr_mimo_v": "domain-payments",
    "ddr_aum_v": "domain-aum-and-aua",
    "ddr_pnl_v": "domain-trading",
    "ddr_trading_volumes_and_amounts_v": "domain-trading",
    "ddr_customer_dailystatus": "domain-customer-and-identity",
    "ddr_customer_snapshot_scd_v": "domain-customer-and-identity",
    "ddr_customer_current_flags": "domain-customer-and-identity",
}


def seed_ddr(asof: str, corpus: SkillCorpus) -> list[dict]:
    out: list[dict] = []
    for view, templates in DDR_QUESTION_TEMPLATES.items():
        view_md = DDR_VIEWS_DIR / f"{view}.md"
        if not view_md.exists():
            print(f"[seed:ddr] WARN missing wiki for {view}, still seeding cases")
        canonical_table = f"main.etoro_kpi.{view}"
        hub_match = corpus.hub_for_fqn(canonical_table)
        if hub_match:
            hub, status = hub_match
        else:
            hub, status = (DDR_HUB_DEFAULTS.get(view, "_none_"), "missing")
        for tpl in templates:
            case_id = f"ddr__{view}__{tpl['id_suffix']}"
            case = {
                "id": case_id,
                "question": tpl["question"].format(asof=asof),
                "source": "ddr",
                "asof": asof,
                "ground_truth_sql": tpl["sql"].format(asof=asof),
                "expected_value": {
                    "type": tpl.get("expected_type", "PENDING"),
                    "tolerance_pct": tpl.get("tolerance_pct", 0.5),
                },
                "expected_skill_hub": DDR_HUB_DEFAULTS.get(view, hub),
                "skill_coverage_status": status,
                "canonical_tables": [canonical_table],
                "anti_sources": tpl.get("anti_sources", []),
                "expected_filters": tpl.get("expected_filters", []),
                "notes": tpl.get("notes", ""),
                "tags": ["ddr", view],
                "max_replicas": 3,
            }
            out.append(case)
    return out


# ----------------------------- Tableau stream --------------------------------

def _split_dbx_tables(field_value: str) -> list[str]:
    if not field_value:
        return []
    return [t.strip().lower() for t in field_value.split(",") if t.strip().startswith("main.")]


def seed_tableau(asof: str, corpus: SkillCorpus, top_n: int = 25) -> list[dict]:
    usage_csv = TABLEAU_INDEX / "usage.csv"
    dbx_csv = TABLEAU_INDEX / "databricks_workbooks.csv"
    if not (usage_csv.exists() and dbx_csv.exists()):
        print(f"[seed:tableau] missing CSVs in {TABLEAU_INDEX}; skipping")
        return []

    usage: dict[str, dict] = {}
    with usage_csv.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            usage[row["workbook_luid"]] = row

    dbx_workbooks: list[tuple[int, dict]] = []
    with dbx_csv.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            luid = row["workbook_luid"]
            views = usage.get(luid, {}).get("total_views") or "0"
            try:
                views_i = int(views)
            except ValueError:
                views_i = 0
            if views_i <= 0:
                continue
            row["_views"] = views_i
            row["_name"] = usage.get(luid, {}).get("workbook_name") or row.get("workbook_name") or "unnamed"
            dbx_workbooks.append((views_i, row))

    dbx_workbooks.sort(key=lambda x: x[0], reverse=True)
    top = dbx_workbooks[:top_n]
    print(f"[seed:tableau] {len(top)} workbooks selected (top {top_n} by views)")

    out: list[dict] = []
    for views, row in top:
        luid = row["workbook_luid"]
        wname = row["_name"] or f"workbook_{luid[:8]}"
        slug = re.sub(r"[^a-z0-9]+", "_", wname.lower()).strip("_") or luid[:8]
        tables = _split_dbx_tables(row.get("databricks_tables_sample", ""))[:3]
        if not tables:
            continue
        for i, tbl in enumerate(tables):
            hub_match = corpus.hub_for_fqn(tbl)
            if hub_match:
                hub, status = hub_match
            else:
                hub, status = ("_none_", "missing")
            case_id = f"tableau__{luid[:8]}__{slug[:40]}__{i}"
            sql = (
                f"SELECT COUNT(*) AS row_count\n"
                f"FROM {tbl}\n"
                f"-- workbook: {wname} (luid {luid}) views={views}"
            )
            case = {
                "id": case_id,
                "question": (
                    f"Open the {wname!r} dashboard. What does the headline "
                    f"figure (row 1 of the primary view) for {asof} show?"
                ),
                "source": f"tableau:{luid}",
                "asof": asof,
                "ground_truth_sql": sql,
                "expected_value": {"type": "PENDING", "tolerance_pct": 1.0},
                "expected_skill_hub": hub,
                "skill_coverage_status": status,
                "canonical_tables": [tbl],
                "anti_sources": [],
                "expected_filters": [],
                "notes": (
                    f"Auto-generated Tableau probe. Rewrite the SQL to match the "
                    f"specific KPI the dashboard renders before pinning. "
                    f"Workbook total_views={views}."
                ),
                "tags": ["tableau", f"views_{views}"],
                "max_replicas": 3,
            }
            out.append(case)
    return out


# ------------------------- Genie-benchmark stream ----------------------------

def _run_dbx_json(args: list[str], timeout: int = 120) -> dict | list | None:
    """Run a databricks CLI subcommand and parse JSON stdout.

    Uses bytes mode + utf-8 decode to avoid Windows cp1255 mojibake on
    Hebrew-named Genie spaces / Confluence content. Returns None on any error.
    """
    try:
        proc = subprocess.run(args, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"[seed:genie] timeout: {' '.join(args[-3:])}")
        return None
    if proc.returncode != 0:
        err = (proc.stderr or b"").decode("utf-8", errors="replace").strip()[:200]
        print(f"[seed:genie] cli failed ({proc.returncode}): {err}")
        return None
    raw = (proc.stdout or b"").decode("utf-8", errors="replace")
    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"[seed:genie] json decode error: {e} (first 80 bytes: {raw[:80]!r})")
        return None


def _list_genie_spaces() -> list[dict]:
    if not DBX_CLI.exists():
        print(f"[seed:genie] {DBX_CLI} not found - skipping")
        return []
    data = _run_dbx_json([str(DBX_CLI), "genie", "list-spaces", "-o", "json"])
    if data is None:
        return []
    spaces = data.get("spaces") if isinstance(data, dict) else data
    if not isinstance(spaces, list):
        return []
    return spaces


def _get_space_serialized(space_id: str) -> dict | None:
    outer = _run_dbx_json(
        [str(DBX_CLI), "genie", "get-space", space_id, "--include-serialized-space", "-o", "json"]
    )
    if not isinstance(outer, dict):
        return None
    serialized = outer.get("serialized_space")
    if not serialized:
        return None
    try:
        return json.loads(serialized)
    except (json.JSONDecodeError, TypeError):
        return None


def _extract_sql_from_answer(answers) -> str | None:
    """Real Genie shape: answer[].format=='SQL', answer[].content is a list of
    string fragments to concatenate. Older shapes also tolerated."""
    if not isinstance(answers, list):
        return None
    for ans in answers:
        if not isinstance(ans, dict):
            continue
        fmt = (ans.get("format") or "").upper()
        content = ans.get("content")
        if isinstance(content, list):
            if all(isinstance(c, str) for c in content):
                joined = "".join(content).strip()
                if fmt == "SQL" or joined.lower().startswith(("select", "with")):
                    return joined
            for c in content:
                if isinstance(c, dict):
                    if c.get("type") in ("query", "sql") and c.get("sql"):
                        return c["sql"]
                    if isinstance(c.get("text"), str) and c["text"].strip().lower().startswith(("select", "with")):
                        return c["text"]
        elif isinstance(content, str) and content.strip().lower().startswith(("select", "with")):
            return content
    return None


def _extract_question(question_field) -> str | None:
    if isinstance(question_field, str):
        return question_field.strip() or None
    if isinstance(question_field, list) and question_field:
        first = question_field[0]
        if isinstance(first, str):
            return first.strip() or None
    return None


def seed_genie_benchmarks(asof: str, corpus: SkillCorpus, max_per_space: int = 5) -> list[dict]:
    spaces = _list_genie_spaces()
    if not spaces:
        return []
    print(f"[seed:genie] {len(spaces)} spaces accessible")
    out: list[dict] = []
    for sp in spaces:
        space_id = sp.get("space_id") or sp.get("id")
        title = sp.get("title") or "(untitled)"
        if not space_id:
            continue
        serialized = _get_space_serialized(space_id)
        if not serialized:
            continue
        benchmarks = (serialized.get("benchmarks") or {}).get("questions") or []
        if not benchmarks:
            continue
        n_seeded = 0
        for q in benchmarks:
            if n_seeded >= max_per_space:
                break
            nl_q = _extract_question(q.get("question") or q.get("text"))
            sql = _extract_sql_from_answer(q.get("answer") or q.get("answers") or [])
            if not nl_q or not sql:
                continue
            fqns = _all_fqns(sql)
            if not fqns:
                continue
            hub = "_none_"
            status = "missing"
            for fqn in fqns:
                h = corpus.hub_for_fqn(fqn)
                if h:
                    hub, status = h
                    break
            slug_title = re.sub(r"[^a-z0-9]+", "_", title.lower()).strip("_")[:30]
            slug_q = re.sub(r"[^a-z0-9]+", "_", str(nl_q).lower()).strip("_")[:40]
            case_id = f"genie__{slug_title}__{slug_q}__{n_seeded}"
            out.append({
                "id": case_id,
                "question": nl_q,
                "source": f"genie_benchmark:{space_id}",
                "asof": asof,
                "ground_truth_sql": sql,
                "expected_value": {"type": "PENDING", "tolerance_pct": 0.5},
                "expected_skill_hub": hub,
                "skill_coverage_status": status,
                "canonical_tables": fqns[:3],
                "anti_sources": [],
                "expected_filters": [],
                "notes": f"Seeded from Genie space {title!r} ({space_id}) benchmark question.",
                "tags": ["genie_benchmark", slug_title],
                "max_replicas": 3,
            })
            n_seeded += 1
        print(f"[seed:genie] {title[:40]:40s} -> {n_seeded} benchmark cases")
    return out


# --------------------------- Known-failure stream ----------------------------

KNOWN_FAILURES = [
    {
        "id": "known_failure__conversion_fee_rollup_2026_05",
        "question": "How much conversion fee revenue did eToro book yesterday?",
        "source": "known_failure",
        "ground_truth_sql": (
            "SELECT SUM(Amount) AS conversion_fee\n"
            "FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions\n"
            "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)\n"
            "  AND IncludedInTotalRevenue = 1\n"
            "  AND Metric = 'ConversionFee'"
        ),
        "expected_skill_hub": "domain-revenue-and-fees",
        "canonical_tables": ["main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"],
        "anti_sources": [
            "main.etoro_kpi_prep.v_revenue_conversionfee",
            "main.etoro_kpi_prep.v_revenue_",
        ],
        "expected_filters": ["IncludedInTotalRevenue = 1", "Metric = 'ConversionFee'"],
        "notes": (
            "2026-06-08 routing-failure case. MCP previously routed to v_revenue_* "
            "instead of the DDR fact for rollups. See decisions.md 2026-06-08 "
            "'Sub-skill primary anchor contradicts hub fast-path rule'."
        ),
        "tags": ["known_failure", "routing_2026_06"],
    },
    {
        "id": "known_failure__iban_trading_volume_2026_05",
        "question": "What was the total trading volume opened from IBAN yesterday?",
        "source": "known_failure",
        "ground_truth_sql": (
            "SELECT SUM(VolumeOpen) AS iban_volume_open\n"
            "FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v\n"
            "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)\n"
            "  AND IsOpenedFromIBAN = '1'"
        ),
        "expected_skill_hub": "domain-trading",
        "canonical_tables": ["main.etoro_kpi.ddr_trading_volumes_and_amounts_v"],
        "anti_sources": [
            "main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban",
            "main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban",
        ],
        "expected_filters": ["IsOpenedFromIBAN = '1'"],
        "notes": (
            "2026-06-08 routing-failure case. Embedder name-bias scored the "
            "3-column ETL lookup tables high; correct source is the DDR volume "
            "fact filtered on IsOpenedFromIBAN='1' (note: STRING not int per DDL)."
        ),
        "tags": ["known_failure", "routing_2026_06"],
    },
    {
        "id": "known_failure__cfd_open_volume_2026_05",
        "question": "What was the CFD open volume yesterday?",
        "source": "known_failure",
        "ground_truth_sql": (
            "SELECT SUM(VolumeOpen) AS cfd_open_volume\n"
            "FROM main.etoro_kpi.ddr_trading_volumes_and_amounts_v\n"
            "WHERE DateID = CAST(REPLACE('{asof}','-','') AS INT)\n"
            "  AND IsSettled = 0"
        ),
        "expected_skill_hub": "domain-trading",
        "canonical_tables": ["main.etoro_kpi.ddr_trading_volumes_and_amounts_v"],
        "anti_sources": [],
        "expected_filters": ["IsSettled = 0"],
        "notes": (
            "2026-06-08 routing-failure case. MCP relevance floor (~0.55) silenced "
            "the correct domain-trading match (scored 0.514, ranked 3rd). The "
            "answer was found and then discarded. CFD = IsSettled=0 across all "
            "instrument types (not a specific InstrumentTypeID)."
        ),
        "tags": ["known_failure", "routing_2026_06"],
    },
]


def seed_known_failures(asof: str, corpus: SkillCorpus) -> list[dict]:
    out: list[dict] = []
    for tpl in KNOWN_FAILURES:
        case = dict(tpl)
        case["asof"] = asof
        case["ground_truth_sql"] = case["ground_truth_sql"].format(asof=asof)
        case["expected_value"] = {"type": "PENDING", "tolerance_pct": 0.5}
        for fqn in case.get("canonical_tables", []):
            h = corpus.hub_for_fqn(fqn)
            if h:
                case["expected_skill_hub"] = h[0]
                case["skill_coverage_status"] = h[1]
                break
        else:
            case["skill_coverage_status"] = "covered"
        case["max_replicas"] = 3
        out.append(case)
    return out


# --------------------------------- writer ------------------------------------

def write_cases(cases: Iterable[dict], dry_run: bool) -> int:
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    n = 0
    for case in cases:
        out = CASES_DIR / f"{case['id']}.yaml"
        if dry_run:
            print(f"[seed] DRY {out.relative_to(REPO_ROOT)}")
            n += 1
            continue
        out.write_text(yaml.safe_dump(case, sort_keys=False, allow_unicode=True), encoding="utf-8")
        n += 1
    return n


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--asof", required=True, help="Pinned snapshot date YYYY-MM-DD")
    parser.add_argument("--only", choices=["ddr", "tableau", "genie", "known_failures"], help="Restrict to one stream")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--top-n-tableau", type=int, default=25)
    parser.add_argument("--max-per-genie-space", type=int, default=5)
    args = parser.parse_args()

    print("[seed] building skill corpus index ...")
    corpus = build_skill_corpus()
    print(f"[seed] {len(corpus.fqn_to_files)} unique FQNs across {len(corpus.file_hubs)} skill files")

    cases: list[dict] = []
    if args.only in (None, "ddr"):
        c = seed_ddr(args.asof, corpus)
        print(f"[seed:ddr] +{len(c)} cases")
        cases.extend(c)
    if args.only in (None, "tableau"):
        c = seed_tableau(args.asof, corpus, top_n=args.top_n_tableau)
        print(f"[seed:tableau] +{len(c)} cases")
        cases.extend(c)
    if args.only in (None, "genie"):
        c = seed_genie_benchmarks(args.asof, corpus, max_per_space=args.max_per_genie_space)
        print(f"[seed:genie] +{len(c)} cases")
        cases.extend(c)
    if args.only in (None, "known_failures"):
        c = seed_known_failures(args.asof, corpus)
        print(f"[seed:known_failures] +{len(c)} cases")
        cases.extend(c)

    n = write_cases(cases, args.dry_run)
    print(f"[seed] wrote {n} cases ({'dry-run' if args.dry_run else CASES_DIR})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
