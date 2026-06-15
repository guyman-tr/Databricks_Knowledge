#!/usr/bin/env python3
"""
DDR parity check: Synapse (PROD) vs Databricks Unity Catalog.

Per DateID since 2025-01-01, compares 5 metrics:
  1. deposits     : SUM(AmountUSD)             FROM ddr_fact_mimo_allplatforms WHERE MIMOAction='Deposit'
  2. tp_equity    : SUM(TotalEquityTP)         FROM ddr_fact_aum
  3. sdrt         : SUM(Amount)                FROM ddr_fact_revenue_generating_actions WHERE Metric='SDRT'
  4. upnl_change  : SUM(UnrealizedPnLChange)   FROM ddr_fact_pnl
  5. funded       : SUM(IsFunded)              FROM ddr_customer_daily_status

Output: CSV of DateIDs where ANY metric mismatches between Synapse and UC.
Tolerance: integer counts must match exactly; decimals tolerate |delta| <= 0.01
(ignored if both sides are NULL/zero).
"""
from __future__ import annotations

import os
import sys
import time
from decimal import Decimal

# ---- Synapse PROD ---------------------------------------------------------
# NOTE: synapse_connect.py's AAD path is hardcoded to STG (the no-retention
# snapshot of PROD). We MUST connect directly to PROD here to avoid silently
# comparing UC against a stale STG snapshot.
import pyodbc

SYN_PROD_SERVER = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
SYN_PROD_DB = "sql_dp_prod_we"
SYN_UID = "guyman@etoro.com"


def syn_prod_connect():
    conn_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={SYN_PROD_SERVER};"
        f"Database={SYN_PROD_DB};"
        "Authentication=ActiveDirectoryIntegrated;"
        "Encrypt=yes;TrustServerCertificate=no;"
        "Connection Timeout=60;"
    )
    conn = pyodbc.connect(conn_str, timeout=60)
    conn.timeout = 600
    return conn


def syn_run(conn, query):
    cursor = conn.cursor()
    cursor.execute(query)
    if cursor.description is None:
        return [], []
    cols = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    return cols, rows

# ---- Databricks UC --------------------------------------------------------
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

DBX_PROFILE = (
    os.environ.get("DATABRICKS_MCP_PROFILE")
    or os.environ.get("DATABRICKS_CONFIG_PROFILE")
    or "guyman"
)
DBX_WAREHOUSE = "208214768b0e0308"

START_DATEID = 20250101

SYN_SQL = f"""
WITH mimo AS (
  SELECT DateID, SUM(AmountUSD) AS deposits
  FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms
  WHERE DateID >= {START_DATEID} AND MIMOAction = 'Deposit'
  GROUP BY DateID
),
aum AS (
  SELECT DateID, SUM(TotalEquityTP) AS tp_equity
  FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM
  WHERE DateID >= {START_DATEID}
  GROUP BY DateID
),
rev AS (
  SELECT DateID, SUM(Amount) AS sdrt
  FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
  WHERE DateID >= {START_DATEID} AND Metric = 'SDRT'
  GROUP BY DateID
),
pnl AS (
  SELECT DateID, SUM(UnrealizedPnLChange) AS upnl_change
  FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL
  WHERE DateID >= {START_DATEID}
  GROUP BY DateID
),
cds AS (
  SELECT DateID, SUM(CAST(IsFunded AS BIGINT)) AS funded
  FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
  WHERE DateID >= {START_DATEID}
  GROUP BY DateID
),
all_dates AS (
  SELECT DateID FROM mimo
  UNION SELECT DateID FROM aum
  UNION SELECT DateID FROM rev
  UNION SELECT DateID FROM pnl
  UNION SELECT DateID FROM cds
)
SELECT d.DateID,
       mimo.deposits, aum.tp_equity, rev.sdrt, pnl.upnl_change, cds.funded
FROM all_dates d
LEFT JOIN mimo ON mimo.DateID = d.DateID
LEFT JOIN aum  ON aum.DateID  = d.DateID
LEFT JOIN rev  ON rev.DateID  = d.DateID
LEFT JOIN pnl  ON pnl.DateID  = d.DateID
LEFT JOIN cds  ON cds.DateID  = d.DateID
ORDER BY d.DateID
"""

UC_SQL = f"""
WITH mimo AS (
  SELECT DateID, SUM(AmountUSD) AS deposits
  FROM main.de_output.de_output_ddr_fact_mimo_allplatforms
  WHERE DateID >= {START_DATEID} AND MIMOAction = 'Deposit'
  GROUP BY DateID
),
aum AS (
  SELECT DateID, SUM(TotalEquityTP) AS tp_equity
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  WHERE DateID >= {START_DATEID}
  GROUP BY DateID
),
rev AS (
  SELECT DateID, SUM(Amount) AS sdrt
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
  WHERE DateID >= {START_DATEID} AND Metric = 'SDRT'
  GROUP BY DateID
),
pnl AS (
  SELECT DateID, SUM(UnrealizedPnLChange) AS upnl_change
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
  WHERE DateID >= {START_DATEID}
  GROUP BY DateID
),
cds AS (
  SELECT DateID, SUM(CAST(IsFunded AS BIGINT)) AS funded
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
  WHERE DateID >= {START_DATEID}
  GROUP BY DateID
),
all_dates AS (
  SELECT DateID FROM mimo
  UNION SELECT DateID FROM aum
  UNION SELECT DateID FROM rev
  UNION SELECT DateID FROM pnl
  UNION SELECT DateID FROM cds
)
SELECT d.DateID,
       mimo.deposits, aum.tp_equity, rev.sdrt, pnl.upnl_change, cds.funded
FROM all_dates d
LEFT JOIN mimo ON mimo.DateID = d.DateID
LEFT JOIN aum  ON aum.DateID  = d.DateID
LEFT JOIN rev  ON rev.DateID  = d.DateID
LEFT JOIN pnl  ON pnl.DateID  = d.DateID
LEFT JOIN cds  ON cds.DateID  = d.DateID
ORDER BY d.DateID
"""

DECIMAL_TOL = Decimal("0.01")
METRICS = ["deposits", "tp_equity", "sdrt", "upnl_change", "funded"]


def _to_dec(v):
    if v is None:
        return None
    if isinstance(v, Decimal):
        return v
    return Decimal(str(v))


def fetch_synapse():
    print(f"[synapse] connecting to {SYN_PROD_SERVER} / {SYN_PROD_DB}...", file=sys.stderr, flush=True)
    conn = syn_prod_connect()
    try:
        t0 = time.time()
        cols, rows = syn_run(conn, SYN_SQL)
        print(f"[synapse-prod] {len(rows)} dateids in {time.time() - t0:.1f}s", file=sys.stderr, flush=True)
    finally:
        conn.close()
    out = {}
    for r in rows:
        out[int(r[0])] = {
            "deposits": _to_dec(r[1]),
            "tp_equity": _to_dec(r[2]),
            "sdrt": _to_dec(r[3]),
            "upnl_change": _to_dec(r[4]),
            "funded": int(r[5]) if r[5] is not None else None,
        }
    return out


def fetch_uc():
    print(f"[uc] connecting (profile={DBX_PROFILE})...", file=sys.stderr, flush=True)
    w = WorkspaceClient(profile=DBX_PROFILE)
    t0 = time.time()
    resp = w.statement_execution.execute_statement(
        warehouse_id=DBX_WAREHOUSE,
        statement=UC_SQL,
        wait_timeout="50s",
    )
    sid = resp.statement_id
    deadline = time.time() + 600
    while resp.status.state in (StatementState.PENDING, StatementState.RUNNING):
        if time.time() > deadline:
            raise TimeoutError("UC query did not finish in 10 min")
        time.sleep(2)
        resp = w.statement_execution.get_statement(sid)
    if resp.status.state != StatementState.SUCCEEDED:
        raise RuntimeError(f"UC query failed: {resp.status.error.message if resp.status.error else resp.status.state}")

    rows = (resp.result.data_array or []) if resp.result else []
    cols = [c.name for c in resp.manifest.schema.columns]
    print(f"[uc] {len(rows)} dateids in {time.time() - t0:.1f}s", file=sys.stderr, flush=True)

    # If chunked (>~25k rows usually), fetch additional chunks. ~488 rows fits in one chunk.
    next_link = getattr(resp.result, "next_chunk_internal_link", None) if resp.result else None
    while next_link:
        chunk_resp = w.api_client.do("GET", next_link)
        rows.extend(chunk_resp.get("data_array") or [])
        next_link = chunk_resp.get("next_chunk_internal_link")

    out = {}
    for r in rows:
        out[int(r[0])] = {
            "deposits": _to_dec(r[1]),
            "tp_equity": _to_dec(r[2]),
            "sdrt": _to_dec(r[3]),
            "upnl_change": _to_dec(r[4]),
            "funded": int(r[5]) if r[5] is not None else None,
        }
    return out


def values_match(metric: str, syn_v, uc_v) -> bool:
    if syn_v is None and uc_v is None:
        return True
    if syn_v is None or uc_v is None:
        return False
    if metric == "funded":
        return int(syn_v) == int(uc_v)
    return abs(Decimal(syn_v) - Decimal(uc_v)) <= DECIMAL_TOL


def fmt(v):
    if v is None:
        return ""
    return str(v)


def main():
    syn = fetch_synapse()
    uc = fetch_uc()

    all_dates = sorted(set(syn) | set(uc))
    syn_only = sorted(set(syn) - set(uc))
    uc_only = sorted(set(uc) - set(syn))

    headers = ["DateID"]
    for m in METRICS:
        headers += [f"syn_{m}", f"uc_{m}", f"diff_{m}"]
    headers += ["mismatch_metrics"]

    mismatch_rows = []
    for d in all_dates:
        s = syn.get(d) or {m: None for m in METRICS}
        u = uc.get(d) or {m: None for m in METRICS}
        bad = []
        for m in METRICS:
            if not values_match(m, s[m], u[m]):
                bad.append(m)
        if not bad and d in syn and d in uc:
            continue
        if d not in syn:
            bad.insert(0, "MISSING_IN_SYNAPSE")
        if d not in uc:
            bad.insert(0, "MISSING_IN_UC")
        row = [str(d)]
        for m in METRICS:
            sv, uv = s[m], u[m]
            if sv is None or uv is None:
                diff = ""
            elif m == "funded":
                diff = str(int(sv) - int(uv))
            else:
                diff = str(Decimal(sv) - Decimal(uv))
            row += [fmt(sv), fmt(uv), diff]
        row.append("|".join(bad))
        mismatch_rows.append(row)

    print(",".join(headers))
    for r in mismatch_rows:
        print(",".join(r))

    print(
        f"\n[summary] synapse_dates={len(syn)}  uc_dates={len(uc)}  "
        f"mismatched_dates={len(mismatch_rows)}  syn_only={len(syn_only)}  uc_only={len(uc_only)}",
        file=sys.stderr,
        flush=True,
    )


if __name__ == "__main__":
    sys.stdout.reconfigure(line_buffering=True)
    main()
