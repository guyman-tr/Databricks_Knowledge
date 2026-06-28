#!/usr/bin/env python3
"""Prove one non-job ADF pipeline orchestration with full QA parity checks."""
from __future__ import annotations

import argparse
import csv
import datetime as dt
from dataclasses import dataclass
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


PROC_OVERRIDE_BY_TABLE = {
    "dim_customer": "sp_dim_customer",
    "dim_historysplitratio": "sp_dim_historysplitratio_dl_to_synapse",
    "dim_mirror": "sp_dim_mirror_dl_to_synapse",
    "fact_cashout_state": "sp_fact_cashout_state",
    "fact_currencypricewithsplit": "sp_fact_currencypricewithsplit_dl_to_synapse",
    "fact_deposit_state": "sp_fact_deposit_state",
}


@dataclass
class TablePair:
    migration_table: str
    gold_table: str
    procedure_name: str
    has_date_param: bool


def _read_first_candidate(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            if (row.get("matched_job") or "0").strip() == "0":
                name = (row.get("pipeline_name") or "").strip()
                if name:
                    return name
    raise RuntimeError("No unmatched candidate found in candidate_not_in_jobs.csv")


def _read_pipeline_tables(path: Path, pipeline_name: str) -> list[str]:
    out: list[str] = []
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            if (row.get("pipeline_name") or "").strip() != pipeline_name:
                continue
            table = (row.get("uc_table") or "").strip()
            if table:
                out.append(table)
    if not out:
        raise RuntimeError(f"No table mapping rows for pipeline: {pipeline_name}")
    return out


def _base_name(fqn: str) -> str:
    return fqn.split(".")[-1].lower()


def _snapshot_freshness(w: Any, warehouse_id: str) -> dict[str, Any]:
    query = """
SELECT table_name, last_altered
FROM system.information_schema.tables
WHERE table_catalog='dwh_daily_process' AND table_schema='daily_snapshot'
ORDER BY last_altered DESC
LIMIT 1
""".strip()
    cols, rows = execute_sql(w, sql_text=query, warehouse_id=warehouse_id)
    if not rows:
        return {"table_name": "", "last_altered": "", "age_hours": None}
    idx_name = cols.index("table_name")
    idx_ts = cols.index("last_altered")
    table_name = str(rows[0][idx_name])
    ts_raw = str(rows[0][idx_ts])
    snapshot_ts = dt.datetime.fromisoformat(ts_raw.replace("Z", "+00:00"))
    now = dt.datetime.now(dt.timezone.utc)
    age_hours = (now - snapshot_ts).total_seconds() / 3600.0
    return {"table_name": table_name, "last_altered": ts_raw, "age_hours": round(age_hours, 2)}


def _resolve_gold_tables(w: Any, warehouse_id: str, migration_tables: list[str]) -> dict[str, str]:
    in_clause = ", ".join(f"'{t}'" for t in migration_tables)
    query = f"""
SELECT migration_table_name, gold_table_name
FROM dwh_daily_process.qa.gold_phase_table_mapping
WHERE migration_table_name IN ({in_clause})
""".strip()
    cols, rows = execute_sql(w, sql_text=query, warehouse_id=warehouse_id)
    if not rows:
        return {}
    idx_m = cols.index("migration_table_name")
    idx_g = cols.index("gold_table_name")
    return {str(r[idx_m]): str(r[idx_g]) for r in rows if r[idx_m] and r[idx_g]}


def _proc_has_date_param(w: Any, warehouse_id: str, proc_name: str) -> bool:
    query = f"""
SELECT COUNT(*) AS c
FROM system.information_schema.parameters
WHERE specific_catalog='dwh_daily_process'
  AND specific_schema='migration_tables'
  AND specific_name='{proc_name}'
""".strip()
    cols, rows = execute_sql(w, sql_text=query, warehouse_id=warehouse_id)
    if not rows:
        return False
    idx = cols.index("c")
    return int(rows[0][idx]) > 0


def _build_pairs(w: Any, warehouse_id: str, migration_tables: list[str]) -> list[TablePair]:
    gold_map = _resolve_gold_tables(w, warehouse_id, migration_tables)
    pairs: list[TablePair] = []
    for migration in migration_tables:
        table = _base_name(migration)
        proc = PROC_OVERRIDE_BY_TABLE.get(table)
        if not proc:
            continue
        gold = gold_map.get(migration)
        if not gold:
            continue
        has_dt = _proc_has_date_param(w, warehouse_id, proc)
        pairs.append(
            TablePair(
                migration_table=migration,
                gold_table=gold,
                procedure_name=proc,
                has_date_param=has_dt,
            )
        )
    if not pairs:
        raise RuntimeError("No relevant table/procedure pairs resolved")
    return pairs


def _run_orchestration(w: Any, warehouse_id: str, pairs: list[TablePair]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for pair in pairs:
        if pair.has_date_param:
            stmt = (
                "CALL dwh_daily_process.migration_tables."
                f"{pair.procedure_name}(DATEADD(DAY, -1, CURRENT_DATE()))"
            )
        else:
            stmt = f"CALL dwh_daily_process.migration_tables.{pair.procedure_name}()"
        execute_sql(w, sql_text=stmt, warehouse_id=warehouse_id, poll_deadline_sec=1800.0)
        out.append(
            {
                "procedure_name": pair.procedure_name,
                "has_date_param": pair.has_date_param,
                "status": "ok",
            }
        )
    return out


def _qa_full_parity(w: Any, warehouse_id: str, pairs: list[TablePair]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for pair in pairs:
        stmt = f"""
SELECT
  (SELECT COUNT(*) FROM {pair.migration_table}) AS migration_rows,
  (SELECT COUNT(*) FROM {pair.gold_table}) AS gold_rows,
  (
    SELECT COUNT(*) FROM (
      SELECT * FROM {pair.migration_table}
      EXCEPT
      SELECT * FROM {pair.gold_table}
    ) x
  ) AS only_in_migration,
  (
    SELECT COUNT(*) FROM (
      SELECT * FROM {pair.gold_table}
      EXCEPT
      SELECT * FROM {pair.migration_table}
    ) y
  ) AS only_in_gold
""".strip()
        cols, rows = execute_sql(w, sql_text=stmt, warehouse_id=warehouse_id, poll_deadline_sec=1800.0)
        r = rows[0]
        idx = {c: i for i, c in enumerate(cols)}
        migration_rows = int(r[idx["migration_rows"]])
        gold_rows = int(r[idx["gold_rows"]])
        only_m = int(r[idx["only_in_migration"]])
        only_g = int(r[idx["only_in_gold"]])
        parity = only_m == 0 and only_g == 0
        out.append(
            {
                "migration_table": pair.migration_table,
                "gold_table": pair.gold_table,
                "procedure_name": pair.procedure_name,
                "migration_rows": migration_rows,
                "gold_rows": gold_rows,
                "only_in_migration": only_m,
                "only_in_gold": only_g,
                "parity_pass": parity,
            }
        )
    return out


def _write_report(
    path: Path,
    pipeline_name: str,
    freshness: dict[str, Any],
    pairs: list[TablePair],
    orchestration: list[dict[str, Any]],
    qa_results: list[dict[str, Any]],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    all_pass = all(r["parity_pass"] for r in qa_results) if qa_results else False
    lines = [
        f"# ADF Pipeline POC Proof — {pipeline_name}",
        "",
        "## Candidate selection proof",
        f"- Candidate source: `tools/migration_autoloop/runtime/candidate_not_in_jobs.csv`",
        f"- Selected pipeline: `{pipeline_name}` (unmatched to Databricks jobs)",
        "",
        "## Snapshot readiness check",
        f"- Latest `daily_snapshot` table alter: `{freshness['last_altered']}`",
        f"- Sample table: `{freshness['table_name']}`",
        f"- Snapshot age hours: `{freshness['age_hours']}`",
        "",
        "## Relevant items resolved",
        "| Migration table | Gold table | Procedure | Date param |",
        "|---|---|---|---|",
    ]
    for pair in pairs:
        lines.append(
            f"| `{pair.migration_table}` | `{pair.gold_table}` | `{pair.procedure_name}` | `{pair.has_date_param}` |"
        )
    lines.extend(
        [
            "",
            "## Orchestration execution",
            "| Procedure | Status |",
            "|---|---|",
        ]
    )
    for proc in orchestration:
        lines.append(f"| `{proc['procedure_name']}` | `{proc['status']}` |")

    lines.extend(
        [
            "",
            "## Full QA parity (migration vs gold)",
            "| Migration table | Gold table | migration_rows | gold_rows | only_in_migration | only_in_gold | parity_pass |",
            "|---|---:|---:|---:|---:|---:|---|",
        ]
    )
    for row in qa_results:
        lines.append(
            f"| `{row['migration_table']}` | `{row['gold_table']}` | "
            f"{row['migration_rows']} | {row['gold_rows']} | "
            f"{row['only_in_migration']} | {row['only_in_gold']} | `{row['parity_pass']}` |"
        )
    lines.extend(["", f"## Verdict", f"- Full QA parity pass: `{all_pass}`", ""])
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--candidate-csv",
        default="tools/migration_autoloop/runtime/candidate_not_in_jobs.csv",
        help="Selector output csv",
    )
    ap.add_argument(
        "--table-map-csv",
        default="tools/migration_autoloop/seeds/pipeline_table_map.csv",
        help="Pipeline->table map csv",
    )
    ap.add_argument(
        "--pipeline-name",
        default="",
        help="Optional explicit pipeline name (else first unmatched candidate).",
    )
    ap.add_argument(
        "--report-md",
        default="tools/migration_autoloop/runtime/proof_report.md",
        help="Output report path",
    )
    args = ap.parse_args()

    pipeline_name = args.pipeline_name.strip() or _read_first_candidate(Path(args.candidate_csv))
    migration_tables = _read_pipeline_tables(Path(args.table_map_csv), pipeline_name)

    w = make_workspace_client()
    warehouse_id = warehouse_id_from_env()

    freshness = _snapshot_freshness(w, warehouse_id)
    pairs = _build_pairs(w, warehouse_id, migration_tables)
    orchestration = _run_orchestration(w, warehouse_id, pairs)
    qa_results = _qa_full_parity(w, warehouse_id, pairs)

    report_path = Path(args.report_md)
    _write_report(report_path, pipeline_name, freshness, pairs, orchestration, qa_results)
    all_pass = all(r["parity_pass"] for r in qa_results)

    print(f"pipeline={pipeline_name}")
    print(f"report={report_path}")
    print(f"full_qa_parity_pass={all_pass}")
    return 0 if all_pass else 2


if __name__ == "__main__":
    raise SystemExit(main())

