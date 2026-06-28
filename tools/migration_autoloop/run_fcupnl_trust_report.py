#!/usr/bin/env python3
"""Generate trust-grade stepwise FCUPNL migration report."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from decimal import Decimal
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.snapshot_guard import ensure_snapshot_date

MIGRATION_TABLE = "dwh_daily_process.migration_tables.fact_customerunrealized_pnl"
GOLD_TABLE = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl"
TECHNICAL_EXCLUDE = {"updatedate", "etr_y", "etr_ym", "etr_ymd"}
KEY_COLS = ["CID", "DateModified"]


def _q_scalar(sql: str, poll_deadline_sec: float = 1800.0) -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    _, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=poll_deadline_sec)
    if not rows:
        return 0
    val = rows[0][0]
    return int(val) if val is not None else 0


def _q_one_row(sql: str, poll_deadline_sec: float = 1800.0) -> dict[str, object]:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=poll_deadline_sec)
    if not rows:
        return {}
    return {c: rows[0][i] for i, c in enumerate(cols)}


def _exec(sql: str, poll_deadline_sec: float = 1800.0) -> None:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=poll_deadline_sec)


def _ensure_autopoc_procs(target_date: str) -> dict[str, object]:
    patch_script = Path(__file__).with_name("patch_customerunrealized_autopoc.py")
    cmd = [sys.executable, str(patch_script), "--run-date", target_date]
    run = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return {"run_date": target_date, "stdout": run.stdout.strip()}


def _date_id(d: str) -> int:
    return int(d.replace("-", ""))


def _get_business_columns() -> list[str]:
    sql = f"""
SELECT column_name
FROM system.information_schema.columns
WHERE table_catalog='dwh_daily_process'
  AND table_schema='migration_tables'
  AND table_name='fact_customerunrealized_pnl'
ORDER BY ordinal_position
""".strip()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    _, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    cols = [r[0] for r in rows]
    keep: list[str] = []
    for c in cols:
        if c in KEY_COLS:
            continue
        if c.lower() in TECHNICAL_EXCLUDE:
            continue
        keep.append(c)
    return keep


def _refresh_special_snapshot_views(target_date: str) -> dict[str, object]:
    d = dt.date.fromisoformat(target_date)
    d_prev = d - dt.timedelta(days=1)

    def _path(day: dt.date) -> str:
        iso = day.isoformat()
        return (
            "abfss://internal-sources@dldataplatformprodwe.dfs.core.windows.net/"
            f"Bronze/DailySnapshot/etr_y={day.year}/etr_ym={day.year}-{day.month:02d}/etr_ymd={iso}/"
            "etoro/History/BackOfficeCustomer"
        )

    _exec(
        "CREATE OR REPLACE VIEW dwh_daily_process.migration_tables.vw_fcupnl_backofficecustomer_target "
        "AS "
        f"SELECT * FROM parquet.`{_path(d)}` UNION ALL SELECT * FROM parquet.`{_path(d_prev)}`",
        poll_deadline_sec=1200.0,
    )
    _exec(
        "CREATE OR REPLACE VIEW dwh_daily_process.migration_tables.vw_fcupnl_currencypricemaxdate_target "
        "AS SELECT * FROM dwh_daily_process.daily_snapshot.pricelog_candles_currencypricemaxdatewithsplitview",
        poll_deadline_sec=1200.0,
    )
    return {"refreshed": True, "backoffice_days": [target_date, d_prev.isoformat()]}


def _current_version() -> int:
    row = _q_one_row(f"SELECT MAX(version) AS v FROM (DESCRIBE HISTORY {MIGRATION_TABLE})")
    return int(row["v"])


def _counts_for_dates(date_ids: list[int], version: int | None = None) -> dict[str, int]:
    where_in = ",".join(str(x) for x in date_ids)
    version_clause = f" VERSION AS OF {version}" if version is not None else ""
    sql = f"""
SELECT DateModified, COUNT(*) AS c
FROM {MIGRATION_TABLE}{version_clause}
WHERE DateModified IN ({where_in})
GROUP BY DateModified
""".strip()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    _, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    out = {str(d): 0 for d in date_ids}
    for d, c in rows:
        out[str(int(d))] = int(c)
    return out


def _signature_diff_counts(date_id: int, before_version: int, business_cols: list[str]) -> dict[str, int]:
    sig_parts = ", ".join([f"COALESCE(CAST({c} AS STRING),'∅')" for c in business_cols])
    sql = f"""
WITH pre AS (
  SELECT CID, DateModified, sha2(concat_ws('||', {sig_parts}), 256) AS sig
  FROM {MIGRATION_TABLE} VERSION AS OF {before_version}
  WHERE DateModified = {date_id}
),
post AS (
  SELECT CID, DateModified, sha2(concat_ws('||', {sig_parts}), 256) AS sig
  FROM {MIGRATION_TABLE}
  WHERE DateModified = {date_id}
),
j AS (
  SELECT
    COALESCE(pre.CID, post.CID) AS CID,
    pre.sig AS pre_sig,
    post.sig AS post_sig
  FROM pre
  FULL OUTER JOIN post
    ON pre.CID = post.CID
   AND pre.DateModified = post.DateModified
)
SELECT
  SUM(CASE WHEN pre_sig IS NULL AND post_sig IS NOT NULL THEN 1 ELSE 0 END) AS added_rows,
  SUM(CASE WHEN pre_sig IS NOT NULL AND post_sig IS NULL THEN 1 ELSE 0 END) AS removed_rows,
  SUM(CASE WHEN pre_sig IS NOT NULL AND post_sig IS NOT NULL AND pre_sig <> post_sig THEN 1 ELSE 0 END) AS modified_rows
FROM j
""".strip()
    row = _q_one_row(sql, poll_deadline_sec=2400.0)
    return {
        "added_rows": int(row.get("added_rows") or 0),
        "removed_rows": int(row.get("removed_rows") or 0),
        "modified_rows": int(row.get("modified_rows") or 0),
    }


def _sum_pnl(table: str, date_id: int) -> dict[str, float]:
    row = _q_one_row(
        f"SELECT SUM(PositionPnL) AS sum_pnl, SUM(PositionPnL_old) AS sum_pnl_old, SUM(NOP) AS sum_nop, SUM(Notional) AS sum_notional FROM {table} WHERE DateModified={date_id}",
        poll_deadline_sec=2400.0,
    )
    return {
        "sum_pnl": float(row.get("sum_pnl") or 0.0),
        "sum_pnl_old": float(row.get("sum_pnl_old") or 0.0),
        "sum_nop": float(row.get("sum_nop") or 0.0),
        "sum_notional": float(row.get("sum_notional") or 0.0),
    }


def _dbx_interim_metrics(target_id: int) -> dict[str, dict[str, float]]:
    out: dict[str, dict[str, float]] = {}
    out["Ext_FCUPNL_Trade_Position"] = {
        "rows_cnt": float(
            _q_scalar("SELECT COUNT(*) FROM dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position")
        ),
        "sum_pnl_dollars": float(
            _q_one_row(
                "SELECT SUM(CAST(PnLInDollars AS DECIMAL(38,10))) AS v FROM dwh_daily_process.migration_tables.Ext_FCUPNL_Trade_Position"
            ).get("v")
            or 0.0
        ),
    }
    out["Ext_FCUPNL_History_Position"] = {
        "rows_cnt": float(
            _q_scalar("SELECT COUNT(*) FROM dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position")
        ),
        "sum_pnl_dollars": float(
            _q_one_row(
                "SELECT SUM(CAST(EndOfDayPnLInDollars AS DECIMAL(38,10))) AS v FROM dwh_daily_process.migration_tables.Ext_FCUPNL_History_Position"
            ).get("v")
            or 0.0
        ),
    }
    out["Ext_FCUPNL_CurrencyPriceMaxDateWithSplit"] = {
        "rows_cnt": float(
            _q_scalar(
                "SELECT COUNT(*) FROM dwh_daily_process.migration_tables.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit"
            )
        ),
        "sum_bid_spreaded": float(
            _q_one_row(
                "SELECT SUM(CAST(BidSpreaded AS DECIMAL(38,10))) AS v FROM dwh_daily_process.migration_tables.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit"
            ).get("v")
            or 0.0
        ),
    }
    out["Ext_FCUPNL_Dictionary_Instrument"] = {
        "rows_cnt": float(
            _q_scalar("SELECT COUNT(*) FROM dwh_daily_process.migration_tables.Ext_FCUPNL_Dictionary_Instrument")
        )
    }
    out["Fact_SnapshotEquity@target"] = {
        "rows_cnt": float(
            _q_scalar(
                f"SELECT COUNT(*) FROM dwh_daily_process.migration_tables.Fact_SnapshotEquity a JOIN main.dwh.v_m2m_date_daterange b ON a.DateRangeID=b.DateRangeID WHERE b.DateKey={target_id}"
            )
        )
    }
    return out


def _synapse_metrics(target_id: int) -> dict[str, object]:
    try:
        from synapse_connect import connect, run_query
    except Exception as exc:  # noqa: BLE001
        return {"enabled": False, "error": f"import_failed: {exc}"}

    try:
        conn = connect()
    except Exception as exc:  # noqa: BLE001
        return {"enabled": False, "error": f"connect_failed: {exc}"}

    out: dict[str, object] = {"enabled": True}
    try:
        final_q = f"""
SELECT COUNT_BIG(*) AS rows_cnt,
       SUM(CAST(PositionPnL AS DECIMAL(38,10))) AS sum_pnl,
       SUM(CAST(PositionPnL_old AS DECIMAL(38,10))) AS sum_pnl_old,
       SUM(CAST(NOP AS DECIMAL(38,10))) AS sum_nop,
       SUM(CAST(Notional AS DECIMAL(38,10))) AS sum_notional
FROM DWH_dbo.Fact_CustomerUnrealized_PnL
WHERE DateModified = {target_id}
""".strip()
        cols, rows = run_query(conn, final_q)
        out["final"] = {c: rows[0][i] for i, c in enumerate(cols)}

        interim_q = f"""
SELECT 'Ext_FCUPNL_Trade_Position' AS table_name, COUNT_BIG(*) AS rows_cnt, SUM(CAST(PnLInDollars AS DECIMAL(38,10))) AS sum_pnl_dollars
FROM DWH_dbo.Ext_FCUPNL_Trade_Position
UNION ALL
SELECT 'Ext_FCUPNL_History_Position' AS table_name, COUNT_BIG(*) AS rows_cnt, SUM(CAST(EndOfDayPnLInDollars AS DECIMAL(38,10))) AS sum_pnl_dollars
FROM DWH_dbo.Ext_FCUPNL_History_Position
UNION ALL
SELECT 'Ext_FCUPNL_CurrencyPriceMaxDateWithSplit' AS table_name, COUNT_BIG(*) AS rows_cnt, SUM(CAST(BidSpreaded AS DECIMAL(38,10))) AS sum_pnl_dollars
FROM DWH_dbo.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit
UNION ALL
SELECT 'Ext_FCUPNL_Dictionary_Instrument' AS table_name, COUNT_BIG(*) AS rows_cnt, CAST(NULL AS DECIMAL(38,10)) AS sum_pnl_dollars
FROM DWH_dbo.Ext_FCUPNL_Dictionary_Instrument
UNION ALL
SELECT 'Fact_SnapshotEquity@target' AS table_name, COUNT_BIG(*) AS rows_cnt, CAST(NULL AS DECIMAL(38,10)) AS sum_pnl_dollars
FROM DWH_dbo.Fact_SnapshotEquity a
JOIN DWH_dbo.V_M2M_Date_DateRange b ON a.DateRangeID = b.DateRangeID
WHERE b.DateKey = {target_id}
""".strip()
        cols2, rows2 = run_query(conn, interim_q)
        interim: dict[str, dict[str, float]] = {}
        for r in rows2:
            rec = {c: r[i] for i, c in enumerate(cols2)}
            name = str(rec["table_name"])
            interim[name] = {
                "rows_cnt": float(rec["rows_cnt"] or 0.0),
                "sum_pnl_dollars": float(rec["sum_pnl_dollars"] or 0.0),
            }
        out["interim"] = interim
    except Exception as exc:  # noqa: BLE001
        out["error"] = str(exc)
    finally:
        conn.close()
    return out


def _json_normalize(obj: object) -> object:
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, dict):
        return {k: _json_normalize(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_json_normalize(x) for x in obj]
    return obj


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--target-date",
        default="",
        help="Run date YYYY-MM-DD. Default: yesterday UTC.",
    )
    ap.add_argument("--seed-baseline-from-gold", action="store_true", default=True)
    ap.add_argument(
        "--out-json",
        default="tools/migration_autoloop/out/fcupnl_trust_report.json",
        help="Output report path.",
    )
    args = ap.parse_args()

    target_date = args.target_date.strip() or (
        dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)
    ).isoformat()
    target = dt.date.fromisoformat(target_date)
    baseline = target - dt.timedelta(days=1)
    target_id = _date_id(target.isoformat())
    baseline_id = _date_id(baseline.isoformat())
    business_cols = _get_business_columns()

    report: dict[str, object] = {
        "target_date": target.isoformat(),
        "target_date_id": target_id,
        "baseline_date": baseline.isoformat(),
        "baseline_date_id": baseline_id,
        "business_columns_compared": len(business_cols),
    }
    report["autopoc_proc_regen"] = _ensure_autopoc_procs(target.isoformat())

    report["snapshot_guard"] = ensure_snapshot_date(
        warehouse_id=warehouse_id_from_env(),
        target_date=target.isoformat(),
        proc_name="sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc",
        auto_refresh=False,
    )
    report["special_snapshot_views"] = _refresh_special_snapshot_views(target.isoformat())

    report["pre_seed_counts"] = _counts_for_dates([baseline_id, target_id])
    if args.seed_baseline_from_gold:
        _exec(
            f"DELETE FROM {MIGRATION_TABLE} WHERE DateModified IN ({baseline_id},{target_id})",
            poll_deadline_sec=1800.0,
        )
        _exec(
            f"INSERT INTO {MIGRATION_TABLE} SELECT * FROM {GOLD_TABLE} WHERE DateModified={baseline_id}",
            poll_deadline_sec=2400.0,
        )
    report["post_seed_counts"] = _counts_for_dates([baseline_id, target_id])

    before_run_version = _current_version()
    report["before_run_version"] = before_run_version
    report["time_travel_counts_before_run"] = _counts_for_dates([baseline_id, target_id], version=before_run_version)

    _exec(
        f"CALL dwh_daily_process.migration_tables.sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc(TIMESTAMP '{target.isoformat()}')",
        poll_deadline_sec=5400.0,
    )
    _exec(
        f"CALL dwh_daily_process.migration_tables.sp_fact_customerunrealized_pnl_autopoc(TIMESTAMP '{target.isoformat()}')",
        poll_deadline_sec=5400.0,
    )

    after_run_version = _current_version()
    report["after_run_version"] = after_run_version
    report["post_run_counts"] = _counts_for_dates([baseline_id, target_id])

    report["delta_rows"] = {
        "target_added_rows": report["post_run_counts"][str(target_id)] - report["post_seed_counts"][str(target_id)],
        "target_removed_rows": max(
            0, report["post_seed_counts"][str(target_id)] - report["post_run_counts"][str(target_id)]
        ),
    }
    report["signature_diff_baseline"] = _signature_diff_counts(baseline_id, before_run_version, business_cols)
    report["signature_diff_target"] = _signature_diff_counts(target_id, before_run_version, business_cols)

    mig_pnl_target = _sum_pnl(MIGRATION_TABLE, target_id)
    gold_pnl_target = _sum_pnl(GOLD_TABLE, target_id)
    report["target_business_metric_check"] = {
        "migration": mig_pnl_target,
        "gold": gold_pnl_target,
        "delta_sum_pnl": mig_pnl_target["sum_pnl"] - gold_pnl_target["sum_pnl"],
        "delta_sum_pnl_old": mig_pnl_target["sum_pnl_old"] - gold_pnl_target["sum_pnl_old"],
        "delta_sum_nop": mig_pnl_target["sum_nop"] - gold_pnl_target["sum_nop"],
        "delta_sum_notional": mig_pnl_target["sum_notional"] - gold_pnl_target["sum_notional"],
    }
    report["interim_dbx"] = _dbx_interim_metrics(target_id)
    synapse_eval = _synapse_metrics(target_id)
    report["synapse_eval"] = synapse_eval
    if synapse_eval.get("enabled") and synapse_eval.get("final"):
        s = synapse_eval["final"]
        report["target_vs_synapse"] = {
            "delta_rows": report["post_run_counts"][str(target_id)] - int(s.get("rows_cnt") or 0),
            "delta_sum_pnl": mig_pnl_target["sum_pnl"] - float(s.get("sum_pnl") or 0.0),
            "delta_sum_pnl_old": mig_pnl_target["sum_pnl_old"] - float(s.get("sum_pnl_old") or 0.0),
            "delta_sum_nop": mig_pnl_target["sum_nop"] - float(s.get("sum_nop") or 0.0),
            "delta_sum_notional": mig_pnl_target["sum_notional"] - float(s.get("sum_notional") or 0.0),
        }
        if synapse_eval.get("interim"):
            interim_delta: dict[str, dict[str, float]] = {}
            for name, dbx_vals in report["interim_dbx"].items():
                syn_vals = synapse_eval["interim"].get(name, {})
                interim_delta[name] = {
                    "delta_rows": float(dbx_vals.get("rows_cnt") or 0.0) - float(syn_vals.get("rows_cnt") or 0.0),
                    "delta_sum_pnl_dollars": float(dbx_vals.get("sum_pnl_dollars") or 0.0)
                    - float(syn_vals.get("sum_pnl_dollars") or 0.0),
                }
            report["interim_dbx_vs_synapse"] = interim_delta
    report["qa_pass"] = (
        report["post_run_counts"][str(target_id)] == _q_scalar(f"SELECT COUNT(*) FROM {GOLD_TABLE} WHERE DateModified={target_id}")
        and abs(report["target_business_metric_check"]["delta_sum_pnl"]) <= 0.000001
        and abs(report["target_business_metric_check"]["delta_sum_pnl_old"]) <= 0.02
        and abs(report["target_business_metric_check"]["delta_sum_nop"]) <= 0.000001
        and abs(report["target_business_metric_check"]["delta_sum_notional"]) <= 0.000001
    )

    report = _json_normalize(report)  # type: ignore[assignment]

    out_path = Path(args.out_json)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"report": str(out_path), "target_date": target.isoformat()}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

