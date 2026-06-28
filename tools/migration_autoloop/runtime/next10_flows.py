from __future__ import annotations

import json
import re
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _fetch_missing() -> list[str]:
    p = Path("tools/migration_autoloop/out/migration_missing_procs.txt")
    if not p.exists():
        return []
    return [x.strip().lower() for x in p.read_text(encoding="utf-8").splitlines() if x.strip()]


def _fetch_body(proc: str) -> str:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = (
        "SELECT routine_definition "
        "FROM system.information_schema.routines "
        "WHERE routine_catalog='dwh_daily_process' "
        "AND routine_schema='migration_tables' "
        f"AND routine_name='{proc}'"
    )
    _, rows = execute_sql(w, sql_text=q, warehouse_id=wid, poll_deadline_sec=1200.0)
    return str(rows[0][0] or "") if rows else ""


def _has_date_param(proc: str) -> bool:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = (
        "SELECT COUNT(*) AS c "
        "FROM system.information_schema.parameters "
        "WHERE specific_catalog='dwh_daily_process' "
        "AND specific_schema='migration_tables' "
        f"AND specific_name='{proc}'"
    )
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    if not rows:
        return False
    c_idx = cols.index("c")
    return int(rows[0][c_idx] or 0) > 0


def _complexity(proc: str, body: str) -> dict[str, object]:
    refs = set(
        re.findall(
            r"dwh_daily_process\.migration_tables\.([A-Za-z0-9_]+)",
            body,
            flags=re.IGNORECASE,
        )
    )
    refs.discard(proc)
    join_count = len(re.findall(r"\bJOIN\b", body, flags=re.IGNORECASE))
    merge_count = len(re.findall(r"\bMERGE\s+INTO\b", body, flags=re.IGNORECASE))
    insert_count = len(re.findall(r"\bINSERT\s+INTO\b", body, flags=re.IGNORECASE))
    extractxml_count = len(re.findall(r"ExtractXMLValue", body, flags=re.IGNORECASE))
    temp_count = len(re.findall(r"\bTEMP_TABLE_", body, flags=re.IGNORECASE))
    dateadd_datediff_zero = len(re.findall(r"DATEDIFF\s*\(\s*0\s*,", body, flags=re.IGNORECASE))
    tasks = 1 + len(refs)
    score = (
        1.2 * len(refs)
        + 0.25 * join_count
        + 0.8 * merge_count
        + 0.2 * insert_count
        + 0.8 * extractxml_count
        + 0.4 * temp_count
        + 1.0 * dateadd_datediff_zero
    )
    if score < 8:
        band = "S"
    elif score < 18:
        band = "M"
    elif score < 35:
        band = "L"
    else:
        band = "XL"
    return {
        "tasks_estimate": tasks,
        "score": round(score, 2),
        "band": band,
        "refs_count": len(refs),
        "join_count": join_count,
        "merge_count": merge_count,
        "insert_count": insert_count,
        "extractxml_count": extractxml_count,
        "temp_count": temp_count,
        "datediff0_count": dateadd_datediff_zero,
    }


def main() -> int:
    missing = _fetch_missing()
    # Prioritize flow entrypoints first.
    dl = [p for p in missing if p.startswith("sp_") and p.endswith("_dl_to_synapse")]
    others = [p for p in missing if p not in dl]
    ordered = dl + others

    out = []
    for proc in ordered[:25]:
        body = _fetch_body(proc)
        comp = _complexity(proc, body)
        out.append(
            {
                "flow_id": proc,
                "has_date_param": _has_date_param(proc),
                **comp,
            }
        )

    # Highest complexity among the top candidate pool is a better first cut.
    # Keep entrypoints only for the "next 10 flows" list.
    entrypoint_rows = [r for r in out if r["flow_id"].endswith("_dl_to_synapse")] or out
    entrypoint_rows.sort(key=lambda x: (-x["score"], -x["tasks_estimate"], x["flow_id"]))
    next10 = entrypoint_rows[:10]

    p = Path("tools/migration_autoloop/out/next10_flows.json")
    p.write_text(json.dumps(next10, indent=2), encoding="utf-8")
    print(json.dumps({"next10_count": len(next10), "artifact": str(p), "rows": next10}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
