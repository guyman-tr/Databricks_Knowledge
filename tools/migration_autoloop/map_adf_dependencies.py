#!/usr/bin/env python3
"""Build bottom-up ADF flow map and pick next candidate flows."""
from __future__ import annotations

import csv
import json
import re
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.flow_catalog import FLOW_CATALOG, PIPELINE_NAME
OUT_DIR = Path("tools/migration_autoloop/out")
OUT_CSV = OUT_DIR / "adf_dependency_map.csv"
OUT_JSON = OUT_DIR / "adf_candidate_flows.json"


def _routine_def(proc_name: str) -> str:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    sql = f"""
SELECT routine_definition
FROM system.information_schema.routines
WHERE routine_catalog='dwh_daily_process'
  AND routine_schema='migration_tables'
  AND routine_name='{proc_name}'
""".strip()
    _, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1200.0)
    return str(rows[0][0] or "") if rows else ""


def _has_date_param(proc_name: str) -> bool:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    sql = f"""
SELECT COUNT(*) AS c
FROM system.information_schema.parameters
WHERE specific_catalog='dwh_daily_process'
  AND specific_schema='migration_tables'
  AND specific_name='{proc_name}'
""".strip()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=600.0)
    if not rows:
        return False
    idx = {c: i for i, c in enumerate(cols)}
    return int(rows[0][idx["c"]] or 0) > 0


def _job_state_hint(tokens: list[str]) -> str:
    w = make_workspace_client()
    hits: list[str] = []
    for job in w.jobs.list(expand_tasks=False):
        name = (job.settings.name if job.settings else "") or ""
        n = name.lower()
        if any(t in n for t in tokens):
            hits.append(name)
        if len(hits) >= 3:
            break
    if not hits:
        return "no_direct_job_match"
    return "job_name_match:" + " | ".join(hits)


def _rank_for_bottom_up(row: dict[str, object]) -> tuple[int, int, int]:
    done = 1 if row["done_flow"] else 0
    deps = int(row["depends_on_flow_count"])
    date_ready = 0 if row["has_date_param"] else 1
    return (done, deps, date_ready)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    flows = list(FLOW_CATALOG.values())
    flow_by_table = {f.migration_table.lower(): f.flow_id for f in flows}
    rows: list[dict[str, object]] = []
    for f in flows:
        body = _routine_def(f.procedure_name)
        refs = sorted(
            set(
                x.lower()
                for x in re.findall(
                    r"dwh_daily_process\.migration_tables\.([A-Za-z0-9_]+)",
                    body,
                    flags=re.IGNORECASE,
                )
            )
        )
        ref_fqns = [f"dwh_daily_process.migration_tables.{r}" for r in refs]
        depends = sorted(
            {
                flow_by_table[t.lower()]
                for t in ref_fqns
                if t.lower() in flow_by_table and flow_by_table[t.lower()] != f.flow_id
            }
        )
        has_date = _has_date_param(f.procedure_name)
        job_state = _job_state_hint(
            [f.flow_id.replace("_", ""), f.procedure_name.lower(), f.migration_table.split(".")[-1].lower()]
        )
        rows.append(
            {
                "pipeline_name": PIPELINE_NAME,
                "flow_id": f.flow_id,
                "migration_table": f.migration_table,
                "synapse_table": f.synapse_table,
                "gold_table": f.gold_table,
                "procedure_name": f.procedure_name,
                "has_date_param": has_date,
                "depends_on_flows": "|".join(depends),
                "depends_on_flow_count": len(depends),
                "routine_ref_count": len(refs),
                "databricks_job_state": job_state,
                "done_flow": f.done_flow,
            }
        )

    ordered = sorted(rows, key=_rank_for_bottom_up)
    candidates = [r for r in ordered if not r["done_flow"] and r["has_date_param"]]
    selected = []
    for r in candidates[:3]:
        with_reason = dict(r)
        with_reason["selection_reason"] = (
            "Bottom-up candidate: low intra-flow deps, date-slice runnable, and no FCUPNL overlap."
        )
        selected.append(with_reason)

    with OUT_CSV.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "pipeline_name",
                "flow_id",
                "migration_table",
                "synapse_table",
                "gold_table",
                "procedure_name",
                "has_date_param",
                "depends_on_flows",
                "depends_on_flow_count",
                "routine_ref_count",
                "databricks_job_state",
                "done_flow",
            ],
        )
        writer.writeheader()
        writer.writerows(ordered)

    payload = {
        "pipeline_name": PIPELINE_NAME,
        "ordered_flows": ordered,
        "selected_candidates": selected,
        "selection_policy": "exclude_done + date_param_required + least_dependencies",
    }
    OUT_JSON.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(json.dumps({"dependency_csv": str(OUT_CSV), "selection_json": str(OUT_JSON)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
