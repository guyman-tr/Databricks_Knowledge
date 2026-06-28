#!/usr/bin/env python3
"""DDR recurring-investment decoupling canary.

Background
----------
As of 2026-06 a Recurring Investment position can be funded straight from the
user's available USD balance — no deposit required. That decoupled the recurring
*trade* from the recurring *deposit*: a successful position can now exist with a
NULL DepositID.

The DDR pipeline (Synapse) was audited and is decoupling-safe: every consumer of
the positions bridge keys on PositionID, never on DepositID. This canary guards
against a REGRESSION of that property on the Databricks side — i.e. someone
re-introducing a deposit dependency that would silently drop balance-funded
positions.

What it checks (volume-independent structural invariant — no flaky thresholds)
------------------------------------------------------------------------------
Bridge  = main.bi_output.bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet
            (PositionID, DepositID) — feeds Synapse BI_DB_RecurringInvestment_Positions.
Source  = main.general.bronze_recurringinvestment_recurringinvestment_planinstances
            (per-execution log; PositionStatus, DepositID, OrderID, ...).

Metrics:
  bridge_total            total rows in the bridge
  bridge_balance_funded   rows with a PositionID but NULL/0 DepositID
                          (= deposit-less recurring positions that made it through)
  src_balfunded           planinstances rows: PositionStatus=1 AND DepositID IS NULL
  src_balfunded_withorder  ... AND OrderID IS NOT NULL (resolvable to a position)

Verdict:
  FAIL  bridge_total == 0
          -> bridge empty / pipeline stalled.
  FAIL  src_balfunded > 0 AND bridge_balance_funded == 0
          -> source has deposit-less positions but the bridge carries NONE:
             the decoupling regressed (re-gated on deposit) => data loss.
  WARN  src_balfunded_withorder > 0
          AND bridge_balance_funded < src_balfunded_withorder * 0.5
          -> bridge carrying materially fewer deposit-less positions than the
             source has resolvable ones; possible partial loss, eyeball it.
  WARN  prior run's bridge_total > 0 AND bridge_total dropped > 50% since then
          -> pipeline shrank unexpectedly.
  OK    otherwise (including the all-zero rollout case: nothing to lose).

State is persisted to out/last_run.json so trend regressions can be caught.

Run
---
  set DATABRICKS_MCP_PROFILE=guyman
  python tools/ddr_recurring_canary/check.py
  python tools/ddr_recurring_canary/check.py --no-email   # local dry run

Auth: same as the Cursor Databricks MCP (WorkspaceClient + ~/.databrickscfg).
"""
from __future__ import annotations

import argparse
import datetime as _dt
import importlib.util
import json
import os
import sys
import traceback
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent  # tools/ddr_recurring_canary -> tools -> repo root
OUT_DIR = HERE / "out"
STATE_FILE = OUT_DIR / "last_run.json"

BRIDGE = "main.bi_output.bi_output_finance_tables_bi_db_recurringinvestment_positions_parquet"
SOURCE = "main.general.bronze_recurringinvestment_recurringinvestment_planinstances"

METRICS_SQL = f"""
SELECT b.bridge_total,
       b.bridge_balance_funded,
       s.src_balfunded,
       s.src_balfunded_withorder
FROM (
  SELECT COUNT(*) AS bridge_total,
         SUM(CASE WHEN PositionID IS NOT NULL AND (DepositID IS NULL OR DepositID = 0)
                  THEN 1 ELSE 0 END) AS bridge_balance_funded
  FROM {BRIDGE}
) b
CROSS JOIN (
  SELECT SUM(CASE WHEN PositionStatus = 1 AND DepositID IS NULL
                  THEN 1 ELSE 0 END) AS src_balfunded,
         SUM(CASE WHEN PositionStatus = 1 AND DepositID IS NULL AND OrderID IS NOT NULL
                  THEN 1 ELSE 0 END) AS src_balfunded_withorder
  FROM {SOURCE}
) s
""".strip()


def _load_notify():
    """Import tools/notify/notify.py without depending on package layout."""
    notify_path = REPO_ROOT / "tools" / "notify" / "notify.py"
    spec = importlib.util.spec_from_file_location("notify_helper", notify_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.notify


def profile_from_env() -> str:
    return (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "guyman"
    )


def warehouse_id_from_env() -> str:
    import re

    path = os.environ.get("DATABRICKS_HTTP_PATH", "")
    m = re.search(r"/warehouses/([a-f0-9]+)", path, re.I)
    if m:
        return m.group(1)
    wid = (os.environ.get("DATABRICKS_WAREHOUSE_ID") or "").strip()
    return wid or "208214768b0e0308"  # bi-sql-warehouse-customer


def run_metrics() -> dict:
    from databricks.sdk import WorkspaceClient
    from databricks.sdk.service.sql import StatementState

    w = WorkspaceClient(profile=profile_from_env())
    resp = w.statement_execution.execute_statement(
        warehouse_id=warehouse_id_from_env(),
        statement=METRICS_SQL,
        wait_timeout="50s",
    )
    import time

    sid = resp.statement_id
    deadline = time.time() + 600
    while resp.status.state in (StatementState.PENDING, StatementState.RUNNING):
        if time.time() > deadline:
            raise TimeoutError("metrics query did not finish in 600s")
        time.sleep(2.0)
        resp = w.statement_execution.get_statement(sid)

    if resp.status.state != StatementState.SUCCEEDED:
        err = resp.status.error
        raise RuntimeError(f"metrics query {resp.status.state}: {err.message if err else '?'}")

    row = (resp.result.data_array or [[None, None, None, None]])[0]

    def _int(v):
        return int(v) if v is not None else 0

    return {
        "bridge_total": _int(row[0]),
        "bridge_balance_funded": _int(row[1]),
        "src_balfunded": _int(row[2]),
        "src_balfunded_withorder": _int(row[3]),
    }


def load_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def save_state(metrics: dict, status: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    payload = dict(metrics)
    payload["status"] = status
    payload["ts"] = _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")
    STATE_FILE.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def evaluate(m: dict, prev: dict) -> tuple[str, list[str]]:
    """Return (status, reasons)."""
    reasons: list[str] = []
    status = "ok"

    def bump(new_status):
        nonlocal status
        order = {"ok": 0, "warn": 1, "fail": 2}
        if order[new_status] > order[status]:
            status = new_status

    if m["bridge_total"] == 0:
        bump("fail")
        reasons.append("Bridge is EMPTY (bridge_total=0) — parquet writer / pipeline stalled.")

    if m["src_balfunded"] > 0 and m["bridge_balance_funded"] == 0:
        bump("fail")
        reasons.append(
            f"REGRESSION: source has {m['src_balfunded']} deposit-less recurring positions "
            f"but the bridge carries 0 — balance-funded positions are being dropped "
            f"(bridge re-gated on deposit?)."
        )

    if (
        m["src_balfunded_withorder"] > 0
        and m["bridge_balance_funded"] < m["src_balfunded_withorder"] * 0.5
    ):
        bump("warn")
        reasons.append(
            f"Bridge carries {m['bridge_balance_funded']} deposit-less positions vs "
            f"{m['src_balfunded_withorder']} resolvable in source (<50%) — possible partial loss."
        )

    prev_total = prev.get("bridge_total")
    if prev_total and prev_total > 0 and m["bridge_total"] < prev_total * 0.5:
        bump("warn")
        reasons.append(
            f"Bridge shrank from {prev_total:,} to {m['bridge_total']:,} rows (>50% drop) since last run."
        )

    if status == "ok" and not reasons:
        reasons.append("All decoupling invariants hold — recurring trades flow independent of deposits.")

    return status, reasons


def build_body(m: dict, prev: dict, status: str, reasons: list[str]) -> str:
    prev_line = ""
    if prev:
        prev_line = (
            f"\nPrevious run ({prev.get('ts','?')}): "
            f"bridge_total={prev.get('bridge_total','?')}, "
            f"bridge_balance_funded={prev.get('bridge_balance_funded','?')}, "
            f"status={prev.get('status','?')}"
        )
    return (
        "DDR recurring-investment decoupling canary\n"
        "==========================================\n\n"
        f"Verdict: {status.upper()}\n\n"
        "Why:\n  - " + "\n  - ".join(reasons) + "\n\n"
        "Metrics (live):\n"
        f"  bridge_total            = {m['bridge_total']:,}\n"
        f"  bridge_balance_funded   = {m['bridge_balance_funded']:,}   (PositionID present, DepositID NULL/0)\n"
        f"  src_balfunded           = {m['src_balfunded']:,}   (planinstances PositionStatus=1, DepositID NULL)\n"
        f"  src_balfunded_withorder = {m['src_balfunded_withorder']:,}   (... AND OrderID present)\n"
        f"{prev_line}\n\n"
        "Bridge : " + BRIDGE + "\n"
        "Source : " + SOURCE + "\n\n"
        "Context: recurring trades (volume + revenue) are flagged by PositionID in the Synapse\n"
        "DDR functions and SP_DDR_Fact_Revenue_Generating_Actions (#isRecurring INNER JOIN ON\n"
        "PositionID; DepositID loaded but never used). DDR MIMO counts recurring *deposits* via\n"
        "Fact_BillingDeposit.IsRecurring. A FAIL here means the Databricks positions bridge stopped\n"
        "carrying deposit-less positions — the one way the decoupling could cause data loss.\n\n"
        "Note: the two BI reporting views (bi_output_v_recurring_investment,\n"
        "bi_output_stg.bi_output_recurring_investment_view) are BI-owned (tombo@etoro.com) and\n"
        "NOT covered by this canary."
    )


def main() -> int:
    ap = argparse.ArgumentParser(description="DDR recurring decoupling daily canary")
    ap.add_argument("--no-email", action="store_true", help="Do not send email (local dry run)")
    ap.add_argument("--to", default=None, help="Override recipient (default NOTIFY_DEFAULT_TO)")
    ap.add_argument("--always-email", action="store_true",
                    help="Email even when status is OK (default: email only on WARN/FAIL)")
    args = ap.parse_args()

    prev = load_state()
    try:
        m = run_metrics()
    except Exception:
        tb = traceback.format_exc()
        print(tb, file=sys.stderr, flush=True)
        if not args.no_email:
            notify = _load_notify()
            notify(
                subject="DDR recurring canary — ERROR",
                body="The canary could not query Databricks:\n\n" + tb,
                status="fail",
                channels=["email"],
                to_addr=args.to,
            )
        return 1

    status, reasons = evaluate(m, prev)
    body = build_body(m, prev, status, reasons)
    print(f"[{status.upper()}]\n{body}", flush=True)

    save_state(m, status)

    should_email = (not args.no_email) and (args.always_email or status != "ok")
    if should_email:
        notify = _load_notify()
        res = notify(
            subject=f"DDR recurring decoupling canary — {status.upper()}",
            body=body,
            status=status,
            channels=["email"],
            to_addr=args.to,
        )
        for ch, info in res.items():
            marker = "OK " if info["ok"] else "ERR"
            print(f"[email {marker}] {ch}: {info['detail']}", flush=True)
        if not all(v["ok"] for v in res.values()):
            print("WARNING: notification delivery failed", file=sys.stderr, flush=True)

    return 0 if status != "fail" else 2


if __name__ == "__main__":
    sys.exit(main())
