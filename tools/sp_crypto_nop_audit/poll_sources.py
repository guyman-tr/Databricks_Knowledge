"""Poll every upstream source feeding BI_DB_dbo.SP_Crypto_NOP and record a
fingerprint (row count + signal sums + freshness timestamp) per source per
invocation.

Run this twice a day (04:00 and 09:00 via Windows Task Scheduler). The companion
`make_report.py` diffs the two snapshots and produces a markdown report.

Output: tools/sp_crypto_nop_audit/snapshots/<YYYY-MM-DD>_<HHMM>.csv
       (target_date = the @Date the SP would have been run with — yesterday by default)
"""
from __future__ import annotations

import argparse
import csv
import datetime
import json
import os
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Tuple

import pyodbc

# ---------------------------------------------------------------------------
# Connection: SQL auth ONLY, no AAD fallback path is even reachable.
# We deliberately do NOT import synapse_connect.py — that module has an AAD
# interactive fallback that could pop a sign-in window if SQL auth ever fails.
# At 04:00 unattended, that would silently hang the scheduled task forever.
# ---------------------------------------------------------------------------
PROD_SERVER   = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
PROD_DATABASE = "sql_dp_prod_we"
CONNECT_TIMEOUT = 30
QUERY_TIMEOUT   = 600

_CRED_FILE = Path.home() / ".cursor" / "synapse-credentials.env"


def _load_sql_credentials() -> Tuple[str, str]:
    """Read SYNAPSE_SQL_USER + SYNAPSE_SQL_PASS (or SYNAPSE_SQL_PASSWORD) from
    the cred file. Raises SystemExit if either is missing — we will NEVER fall
    through to interactive auth from a scheduled task."""
    user = os.environ.get("SYNAPSE_SQL_USER", "").strip()
    pwd  = os.environ.get("SYNAPSE_SQL_PASSWORD", "") or os.environ.get("SYNAPSE_SQL_PASS", "")

    if (not user or not pwd) and _CRED_FILE.exists():
        for line in _CRED_FILE.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"')
            if k == "SYNAPSE_SQL_USER" and not user:
                user = v
            elif k in ("SYNAPSE_SQL_PASS", "SYNAPSE_SQL_PASSWORD") and not pwd:
                pwd = v

    if not user or not pwd:
        raise SystemExit(
            f"FATAL: SYNAPSE_SQL_USER / SYNAPSE_SQL_PASS not found. "
            f"Expected in env or {_CRED_FILE}. Aborting before any interactive "
            f"auth fallback can pop a window."
        )
    return user, pwd


def connect_sql_only(verbose: bool = True):
    """Direct pyodbc.connect with SQL Server authentication. No AAD path exists
    in this function — if pyodbc.connect raises, we re-raise. No popup, no hang."""
    user, pwd = _load_sql_credentials()
    pwd_esc = pwd.replace("}", "}}")  # ODBC brace-escape
    conn_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={PROD_SERVER};"
        f"Database={PROD_DATABASE};"
        f"UID={user};"
        f"PWD={{{pwd_esc}}};"
        "Encrypt=yes;TrustServerCertificate=no;"
        f"Connection Timeout={CONNECT_TIMEOUT};"
    )
    if verbose:
        print(
            f"Connecting to Synapse ({PROD_SERVER} / {PROD_DATABASE}) "
            f"using SQL login {user} [SQL-only, no AAD fallback]...",
            flush=True,
        )
    conn = pyodbc.connect(conn_str, timeout=CONNECT_TIMEOUT)
    conn.timeout = QUERY_TIMEOUT
    if verbose:
        print("Connected (SQL authentication).\n", flush=True)
    return conn


def run_query(conn, query: str) -> Tuple[List[str], List[Any]]:
    cursor = conn.cursor()
    cursor.execute(query)
    if cursor.description is None:
        return [], []
    cols = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    return cols, rows

OUT_ROOT = Path(__file__).resolve().parent / "snapshots"
OUT_ROOT.mkdir(parents=True, exist_ok=True)


def date_to_dateid(d: datetime.date) -> int:
    return d.year * 10000 + d.month * 100 + d.day


# ---------------------------------------------------------------------------
# Source fingerprint definitions
# Each entry: id, label, scope (description), query (parameterized via @date / @dateid).
# The query MUST return exactly one row with columns we can JSON-encode.
# Keep queries cheap (aggregates over the @DateID partition only).
# ---------------------------------------------------------------------------
SOURCES: List[Dict[str, Any]] = [
    {
        "id": "BI_DB_PositionPnL",
        "label": "BI_DB_dbo.BI_DB_PositionPnL",
        "scope": "WHERE DateID = @dateid (crypto + non-crypto; SP filters crypto downstream)",
        "query": """
            SELECT
                COUNT_BIG(*)                                            AS row_count,
                COUNT(DISTINCT CID)                                     AS distinct_cids,
                COUNT(DISTINCT InstrumentID)                            AS distinct_instruments,
                COUNT(DISTINCT PositionID)                              AS distinct_positions,
                ISNULL(SUM(CAST(NOP AS DECIMAL(38,4))), 0)              AS sum_nop,
                ISNULL(SUM(CAST(AmountInUnitsDecimal AS DECIMAL(38,8))),0) AS sum_units,
                ISNULL(SUM(CAST(Amount AS DECIMAL(38,4))), 0)           AS sum_amount,
                ISNULL(SUM(CAST(PositionPnL AS DECIMAL(38,4))), 0)      AS sum_position_pnl
            FROM BI_DB_dbo.BI_DB_PositionPnL
            WHERE DateID = {dateid}
        """,
    },
    {
        "id": "BI_DB_PositionPnL_crypto_only",
        "label": "BI_DB_dbo.BI_DB_PositionPnL (joined to crypto Dim_Instrument)",
        "scope": "Exactly what #pnl_posDist produces in the SP",
        "query": """
            SELECT
                COUNT_BIG(*)                                            AS row_count,
                COUNT(DISTINCT bdppl.CID)                               AS distinct_cids,
                COUNT(DISTINCT bdppl.InstrumentID)                      AS distinct_instruments,
                ISNULL(SUM(CAST(bdppl.NOP AS DECIMAL(38,4))), 0)        AS sum_nop,
                ISNULL(SUM(CAST(bdppl.AmountInUnitsDecimal AS DECIMAL(38,8))),0) AS sum_units
            FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
            JOIN DWH_dbo.Dim_Instrument di
              ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID = 10
            WHERE bdppl.DateID = {dateid}
        """,
    },
    {
        "id": "Dim_Position_matched_to_crypto_PnL",
        "label": "DWH_dbo.Dim_Position (intersected with crypto PositionPnL @dateid)",
        "scope": ("Mirrors the SP's #pos join: only positions whose PositionID is in "
                  "crypto PositionPnL @dateid AND satisfy OpenDateID <= @dateid AND "
                  "(CloseDateID > @dateid OR CloseDateID = 0)"),
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT dp.PositionID) AS distinct_positions,
                SUM(CASE WHEN dp.OpenDateID  = {dateid} THEN 1 ELSE 0 END) AS opened_on_date,
                SUM(CASE WHEN dp.CloseDateID = {dateid} THEN 1 ELSE 0 END) AS closed_on_date,
                ISNULL(SUM(CAST(dp.InitialAmountCents AS DECIMAL(38,4))),0) AS sum_initial_amount_cents
            FROM DWH_dbo.Dim_Position dp
            JOIN BI_DB_dbo.BI_DB_PositionPnL bdppl
              ON bdppl.PositionID = dp.PositionID
            JOIN DWH_dbo.Dim_Instrument di
              ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID = 10
            WHERE bdppl.DateID = {dateid}
              AND dp.OpenDateID <= {dateid}
              AND (dp.CloseDateID > {dateid} OR dp.CloseDateID = 0)
        """,
    },
    {
        "id": "Dim_Instrument_crypto",
        "label": "DWH_dbo.Dim_Instrument (InstrumentTypeID = 10)",
        "scope": "All-time crypto instruments referenced by the SP",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                MAX(InstrumentID) AS max_instrument_id,
                COUNT(DISTINCT BuyCurrencyID)  AS distinct_buy_currencies,
                COUNT(DISTINCT SellCurrencyID) AS distinct_sell_currencies
            FROM DWH_dbo.Dim_Instrument
            WHERE InstrumentTypeID = 10
        """,
    },
    {
        "id": "Fact_CurrencyPriceWithSplit",
        "label": "DWH_dbo.Fact_CurrencyPriceWithSplit",
        "scope": "WHERE OccurredDateID = @dateid (drives EOD_Bid_Price)",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT InstrumentID) AS distinct_instruments,
                ISNULL(SUM(CAST(BidSpreaded AS DECIMAL(38,8))), 0) AS sum_bid,
                ISNULL(SUM(CAST(AskSpreaded AS DECIMAL(38,8))), 0) AS sum_ask,
                ISNULL(MAX(CAST(BidSpreaded AS DECIMAL(38,8))), 0) AS max_bid
            FROM DWH_dbo.Fact_CurrencyPriceWithSplit
            WHERE OccurredDateID = {dateid}
        """,
    },
    {
        "id": "Fact_CurrencyPriceWithSplit_crypto",
        "label": "DWH_dbo.Fact_CurrencyPriceWithSplit (joined to crypto Dim_Instrument)",
        "scope": "Subset actually used in #NOP_1/#NOP_2 inner join",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT fcp.InstrumentID) AS distinct_instruments,
                ISNULL(SUM(CAST(fcp.BidSpreaded AS DECIMAL(38,8))), 0) AS sum_bid
            FROM DWH_dbo.Fact_CurrencyPriceWithSplit fcp
            JOIN DWH_dbo.Dim_Instrument di
              ON fcp.InstrumentID = di.InstrumentID AND di.InstrumentTypeID = 10
            WHERE fcp.OccurredDateID = {dateid}
        """,
    },
    {
        "id": "Fact_SnapshotCustomer",
        "label": "DWH_dbo.Fact_SnapshotCustomer @ @dateid (via Dim_Range)",
        "scope": "Exactly what #fsc selects",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT fsc.RealCID) AS distinct_real_cids,
                SUM(CAST(fsc.IsCreditReportValidCB AS INT))            AS sum_iscb_valid,
                SUM(CASE WHEN ISNULL(fsc.DltStatusID,0)=4 THEN 1 ELSE 0 END) AS dlt_user_count
            FROM DWH_dbo.Fact_SnapshotCustomer fsc
            JOIN DWH_dbo.Dim_Range drr
              ON fsc.DateRangeID = drr.DateRangeID
             AND {dateid} BETWEEN drr.FromDateID AND drr.ToDateID
        """,
    },
    {
        "id": "Dim_Customer",
        "label": "DWH_dbo.Dim_Customer (TanganyStatusID, RegisteredReal)",
        "scope": "Full table size + Tangany distribution + registrations <= @date",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT TanganyStatusID) AS distinct_tangany_statuses,
                SUM(CASE WHEN RegisteredReal IS NOT NULL
                              AND RegisteredReal <= '{date_iso}' THEN 1 ELSE 0 END) AS registered_real_le_date,
                SUM(CASE WHEN RegisteredReal IS NOT NULL
                              AND CAST(RegisteredReal AS DATE) = '{date_iso}' THEN 1 ELSE 0 END) AS registered_real_eq_date
            FROM DWH_dbo.Dim_Customer
        """,
    },
    {
        "id": "V_GermanBaFin",
        "label": "BI_DB_dbo.V_GermanBaFin @ @dateid",
        "scope": "WHERE DateID = @dateid (drives IsGermanBaFin flag)",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT CID) AS distinct_cids
            FROM BI_DB_dbo.V_GermanBaFin
            WHERE DateID = {dateid}
        """,
    },
    {
        "id": "External_TanganyStatus_dict",
        "label": "BI_DB_dbo.External_UserApiDB_Dictionary_TanganyStatus",
        "scope": "Tangany status lookup (full table)",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                MAX(TanganyStatusID) AS max_id,
                COUNT(DISTINCT Name) AS distinct_names
            FROM BI_DB_dbo.External_UserApiDB_Dictionary_TanganyStatus
        """,
    },
    {
        "id": "Apex_Enrolment_optout_general",
        "label": "Apex UserProgramEnrolment + History — opt-out (UserProgramID=2, status=2)",
        "scope": "Exactly what #opt_out_general selects",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT a.GCID) AS distinct_gcids
            FROM (
                SELECT GCID, BeginTime, EndTime, UserProgramID, UserProgramEnrolmentStatusID
                  FROM BI_DB_dbo.External_USABroker_Apex_UserProgramEnrolment
                UNION
                SELECT GCID, BeginTime, EndTime, UserProgramID, UserProgramEnrolmentStatusID
                  FROM BI_DB_dbo.External_USABroker_History_UserProgramEnrolment
            ) a
            WHERE a.UserProgramID = 2
              AND a.UserProgramEnrolmentStatusID = 2
              AND CAST('{date_iso}' AS DATE) BETWEEN a.BeginTime AND a.EndTime
        """,
    },
    {
        "id": "Apex_Enrolment_optin_ETH",
        "label": "Apex UserProgramEnrolment + History — opt-in ETH (UserProgramID=3, status=1)",
        "scope": "Exactly what #opt_in_ETH selects",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT a.GCID) AS distinct_gcids
            FROM (
                SELECT GCID, BeginTime, EndTime, UserProgramID, UserProgramEnrolmentStatusID
                  FROM BI_DB_dbo.External_USABroker_Apex_UserProgramEnrolment
                UNION
                SELECT GCID, BeginTime, EndTime, UserProgramID, UserProgramEnrolmentStatusID
                  FROM BI_DB_dbo.External_USABroker_History_UserProgramEnrolment
            ) a
            WHERE a.UserProgramID = 3
              AND a.UserProgramEnrolmentStatusID = 1
              AND CAST('{date_iso}' AS DATE) BETWEEN a.BeginTime AND a.EndTime
        """,
    },
    {
        "id": "BI_DB_Client_Balance_CID_Level_New",
        "label": "BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New @ @dateid",
        "scope": "TanganyStatus patch source (UPDATE after #fsc)",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT CID) AS distinct_cids,
                COUNT(DISTINCT TanganyStatus) AS distinct_tangany_values,
                ISNULL(SUM(CAST(TotalRealCrypto AS DECIMAL(38,4))), 0) AS sum_total_real_crypto,
                ISNULL(SUM(CAST(PositionPNLCryptoReal AS DECIMAL(38,4))), 0) AS sum_position_pnl_crypto_real
            FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New
            WHERE DateID = {dateid}
        """,
    },
    # --- small dims used in #fsc (cheap "did this dim get touched today?" probes) ---
    {
        "id": "Dim_Range",
        "label": "DWH_dbo.Dim_Range",
        "scope": "Anchors @DateID -> DateRangeID join used in #fsc",
        "query": """
            SELECT COUNT_BIG(*) AS row_count, MAX(DateRangeID) AS max_id
            FROM DWH_dbo.Dim_Range
        """,
    },
    {
        "id": "Dim_Regulation",
        "label": "DWH_dbo.Dim_Regulation",
        "scope": "INNER joined in #fsc",
        "query": "SELECT COUNT_BIG(*) AS row_count, MAX(ID) AS max_id FROM DWH_dbo.Dim_Regulation",
    },
    {
        "id": "Dim_Label",
        "label": "DWH_dbo.Dim_Label",
        "scope": "INNER joined in #fsc",
        "query": "SELECT COUNT_BIG(*) AS row_count, MAX(LabelID) AS max_id FROM DWH_dbo.Dim_Label",
    },
    {
        "id": "Dim_MifidCategorization",
        "label": "DWH_dbo.Dim_MifidCategorization",
        "scope": "INNER joined in #fsc",
        "query": "SELECT COUNT_BIG(*) AS row_count, MAX(MifidCategorizationID) AS max_id FROM DWH_dbo.Dim_MifidCategorization",
    },
    {
        "id": "Dim_AccountType",
        "label": "DWH_dbo.Dim_AccountType",
        "scope": "INNER joined in #fsc",
        "query": "SELECT COUNT_BIG(*) AS row_count, MAX(AccountTypeID) AS max_id FROM DWH_dbo.Dim_AccountType",
    },
    {
        "id": "Dim_PlayerLevel",
        "label": "DWH_dbo.Dim_PlayerLevel",
        "scope": "INNER joined in #fsc",
        "query": "SELECT COUNT_BIG(*) AS row_count, MAX(PlayerLevelID) AS max_id FROM DWH_dbo.Dim_PlayerLevel",
    },
    {
        "id": "Dim_PlayerStatus",
        "label": "DWH_dbo.Dim_PlayerStatus",
        "scope": "INNER joined in #fsc",
        "query": "SELECT COUNT_BIG(*) AS row_count, MAX(PlayerStatusID) AS max_id FROM DWH_dbo.Dim_PlayerStatus",
    },
    {
        "id": "Dim_Country",
        "label": "DWH_dbo.Dim_Country",
        "scope": "INNER joined in #fsc",
        "query": "SELECT COUNT_BIG(*) AS row_count, MAX(CountryID) AS max_id FROM DWH_dbo.Dim_Country",
    },
    # --- target table itself (to confirm SP_Crypto_NOP write status) ---
    {
        "id": "TARGET_BI_DB_Crypto_NOP",
        "label": "BI_DB_dbo.BI_DB_Crypto_NOP @ @date  (the SP's INSERT target — instrument level)",
        "scope": "What ended up in the table for @date as of this poll",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT InstrumentName) AS distinct_instruments,
                ISNULL(SUM(CAST(Total_NOP AS DECIMAL(38,4))), 0) AS sum_total_nop,
                ISNULL(SUM(CAST(Real_NOP AS DECIMAL(38,4))), 0)  AS sum_real_nop,
                ISNULL(SUM(CAST(CFD_NOP AS DECIMAL(38,4))), 0)   AS sum_cfd_nop,
                ISNULL(SUM(CAST(Total_Units AS DECIMAL(38,8))),0) AS sum_total_units,
                MAX(UpdateDate) AS max_update_date
            FROM BI_DB_dbo.BI_DB_Crypto_NOP
            WHERE [Date] = '{date_iso}'
        """,
    },
    {
        "id": "TARGET_BI_DB_Crypto_NOP_CID",
        "label": "BI_DB_dbo.BI_DB_Crypto_NOP_CID @ @date  (the SP's INSERT target — CID level)",
        "scope": "What ended up in the table for @date as of this poll",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                COUNT(DISTINCT CID) AS distinct_cids,
                ISNULL(SUM(CAST(Total_NOP AS DECIMAL(38,4))), 0) AS sum_total_nop,
                ISNULL(SUM(CAST(EquityReal AS DECIMAL(38,4))), 0) AS sum_equity_real,
                COUNT(DISTINCT TanganyStatus) AS distinct_tangany_values,
                MAX(UpdateDate) AS max_update_date
            FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID
            WHERE [Date] = '{date_iso}'
        """,
    },
    # --- SP run history for the target date (so the report can show which
    #     SP run is currently the live version) ---
    {
        "id": "SP_Crypto_NOP_run_history",
        "label": "BI_DB_dbo.DataSolutionsProcessesStatus — SP_Crypto_NOP runs for @dateid",
        "scope": "Number of runs and most-recent timestamps for @dateid",
        "query": """
            SELECT
                COUNT_BIG(*) AS row_count,
                SUM(CASE WHEN ProcessStatus = 'Start' THEN 1 ELSE 0 END)     AS start_count,
                SUM(CASE WHEN ProcessStatus = 'Completed' THEN 1 ELSE 0 END) AS complete_count,
                MAX(ProcessStatusTimestamp) AS last_event_ts
            FROM BI_DB_dbo.DataSolutionsProcessesStatus
            WHERE ProcessName = 'SP_Crypto_NOP' AND ParamDateID = {dateid}
        """,
    },
]


# ---------------------------------------------------------------------------
# Polling logic
# ---------------------------------------------------------------------------
def render_query(template: str, target_date: datetime.date) -> str:
    return template.format(
        date_iso=target_date.strftime("%Y-%m-%d"),
        dateid=date_to_dateid(target_date),
    )


def poll(
    conn,
    target_date: datetime.date,
    poll_at_utc: datetime.datetime,
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for src in SOURCES:
        sid = src["id"]
        q = render_query(src["query"], target_date)
        t0 = time.time()
        try:
            cols, result = run_query(conn, q)
        except Exception as exc:  # noqa: BLE001
            rows.append({
                "source_id": sid,
                "source_label": src["label"],
                "scope": src["scope"],
                "target_date": target_date.isoformat(),
                "target_dateid": date_to_dateid(target_date),
                "poll_at_utc": poll_at_utc.isoformat(timespec="seconds"),
                "elapsed_ms": int((time.time() - t0) * 1000),
                "row_count": "",
                "fingerprint_json": json.dumps({"error": f"{type(exc).__name__}: {exc}"}),
            })
            print(f"  [ERR] {sid}: {type(exc).__name__}: {exc}", flush=True)
            continue
        elapsed_ms = int((time.time() - t0) * 1000)
        if not result:
            payload: Dict[str, Any] = {"empty_result": True}
            rc = 0
        else:
            first = result[0]
            payload = {}
            rc = ""
            for col, val in zip(cols, first):
                if isinstance(val, datetime.datetime):
                    val = val.isoformat(timespec="seconds")
                elif isinstance(val, datetime.date):
                    val = val.isoformat()
                else:
                    try:
                        if val is None:
                            val = None
                        else:
                            val = float(val) if isinstance(val, (int, float)) is False and hasattr(val, "__float__") else val
                    except Exception:
                        val = str(val)
                payload[col] = val
                if col.lower() == "row_count":
                    rc = val
        rows.append({
            "source_id": sid,
            "source_label": src["label"],
            "scope": src["scope"],
            "target_date": target_date.isoformat(),
            "target_dateid": date_to_dateid(target_date),
            "poll_at_utc": poll_at_utc.isoformat(timespec="seconds"),
            "elapsed_ms": elapsed_ms,
            "row_count": rc,
            "fingerprint_json": json.dumps(payload, default=str),
        })
        print(f"  [OK ] {sid:<45} rows={rc!s:<14} elapsed={elapsed_ms:>5}ms", flush=True)
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--target-date",
        type=str,
        default="",
        help="The @Date the SP would have been run with (YYYY-MM-DD). Defaults to yesterday (local).",
    )
    parser.add_argument(
        "--tag",
        type=str,
        default="",
        help="Optional label appended to the snapshot filename (e.g. 'manual'). "
             "Default uses the local HHMM at script start.",
    )
    args = parser.parse_args()

    if args.target_date:
        target_date = datetime.date.fromisoformat(args.target_date)
    else:
        target_date = datetime.date.today() - datetime.timedelta(days=1)

    poll_at_utc = datetime.datetime.utcnow().replace(microsecond=0)
    local_now = datetime.datetime.now()
    tag = args.tag.strip() or local_now.strftime("%H%M")

    print(f"=== SP_Crypto_NOP source audit poll ===", flush=True)
    print(f"target_date    = {target_date.isoformat()}  (DateID={date_to_dateid(target_date)})", flush=True)
    print(f"poll_at_utc    = {poll_at_utc.isoformat()}Z  (local: {local_now.isoformat(timespec='seconds')})", flush=True)
    print(f"tag            = {tag}", flush=True)
    print(f"sources        = {len(SOURCES)}", flush=True)
    print(f"output         = {OUT_ROOT / (target_date.isoformat() + '_' + tag + '.csv')}", flush=True)
    print("", flush=True)

    conn = connect_sql_only(verbose=True)
    try:
        rows = poll(conn, target_date, poll_at_utc)
    finally:
        try:
            conn.close()
        except Exception:
            pass

    out_path = OUT_ROOT / f"{target_date.isoformat()}_{tag}.csv"
    headers = ["source_id", "source_label", "scope", "target_date", "target_dateid",
               "poll_at_utc", "elapsed_ms", "row_count", "fingerprint_json"]
    with out_path.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=headers)
        w.writeheader()
        for r in rows:
            w.writerow(r)

    n_err = sum(1 for r in rows if "error" in r["fingerprint_json"])
    print(f"\nWrote {out_path}  ({len(rows)} rows, {n_err} errors)", flush=True)
    return 0 if n_err == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
