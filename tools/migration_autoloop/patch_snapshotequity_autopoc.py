#!/usr/bin/env python3
"""Patch snapshotequity procedures into AutoPOC variants."""
from __future__ import annotations

import re
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

PROC_PLAN = [
    ("sp_fact_snapshotequity", "sp_fact_snapshotequity_autopoc", "V_date TIMESTAMP"),
    ("sp_fact_snapshotequity_dl_to_synapse", "sp_fact_snapshotequity_dl_to_synapse_autopoc", "V_dt TIMESTAMP"),
    ("sp_fact_snapshotequity_dl_to_synapse", "sp_fact_snapshotequity_extract_autopoc", "V_dt TIMESTAMP"),
    ("sp_fact_snapshotequity_inprocesscashouts", "sp_fact_snapshotequity_inprocesscashouts_autopoc", "V_TargetDate TIMESTAMP"),
    ("sp_fact_snapshotequity_totalpositionamount", "sp_fact_snapshotequity_totalpositionamount_autopoc", "V_TargetDate TIMESTAMP"),
]


def _fetch_body(w, wid: str, proc: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{proc}'"
        ),
        warehouse_id=wid,
    )
    if not rows:
        raise RuntimeError(f"Missing source procedure: {proc}")
    return str(rows[0][0] or "")


def _patch_wrapper(body: str) -> str:
    out = body
    out = out.replace(
        "SET V_CurrentDate = cast(DATEADD(day, DATEDIFF(-1, V_dt), 0) as date);",
        "SET V_CurrentDate = CAST(DATEADD(DAY, 1, CAST(V_dt AS DATE)) AS DATE);",
    )
    out = out.replace(
        "SET V_St_Year = convert(TIMESTAMP,DATEADD(YEAR, CAST(DATEDIFF(0, V_dt) / 365 AS INT), 0),8);",
        "SET V_St_Year = CAST(DATE_TRUNC('YEAR', CAST(V_dt AS DATE)) AS STRING);",
    )
    out = out.replace(
        "where Occurred > DATEADD(day, DATEDIFF(-1, V_dt), 0)",
        "where Occurred >= DATEADD(DAY, 1, CAST(V_dt AS DATE))",
    )
    # Normalize Synapse DATEADD/DATEDIFF idiom to Databricks-compatible expression.
    out = re.sub(
        r"DATEADD\(\s*day\s*,\s*DATEDIFF\(\s*-1\s*,\s*V_dt\s*\)\s*,\s*0\s*\)",
        "DATEADD(DAY, 1, CAST(V_dt AS DATE))",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.sp_fact_snapshotequity\s*\(",
        "call dwh_daily_process.migration_tables.sp_fact_snapshotequity_autopoc(",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.sp_fact_snapshotequity_inprocesscashouts\s*\(",
        "call dwh_daily_process.migration_tables.sp_fact_snapshotequity_inprocesscashouts_autopoc(",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.sp_fact_snapshotequity_totalpositionamount\s*\(",
        "call dwh_daily_process.migration_tables.sp_fact_snapshotequity_totalpositionamount_autopoc(",
        out,
        flags=re.IGNORECASE,
    )
    return out


def _patch_extract_only(body: str) -> str:
    out = _patch_wrapper(body)
    out = re.sub(
        r"\n\s*call\s+dwh_daily_process\.migration_tables\.(?:SP_|sp_)Fact_SnapshotEquity_InProcessCashouts[^\n]*",
        "",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"\n\s*call\s+dwh_daily_process\.migration_tables\.(?:SP_|sp_)Fact_SnapshotEquity_TotalPositionAmount[^\n]*",
        "",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"\n\s*call\s+dwh_daily_process\.migration_tables\.(?:SP_|sp_)Fact_SnapshotEquity[^\n]*",
        "",
        out,
        flags=re.IGNORECASE,
    )
    return out


def _patch_core(body: str) -> str:
    out = body
    out = out.replace(
        "set V_dateid=CAST(date_format(DATEADD(day, DATEDIFF(0, V_date), 0), 'yyyyMMdd') AS int);",
        "",
    )
    out = out.replace(
        "SET V_largedate = (select cast(cast(year(V_date) as STRING)||'12'||'31' as TIMESTAMP));",
        "SET V_largedate = (SELECT TO_TIMESTAMP(CAST(year(V_date) AS STRING) || '1231', 'yyyyMMdd'));",
    )
    out = out.replace("DECLARE V_dateid  INT;", "")
    out = out.replace(
        "DATEADD(YEAR, CAST(DATEDIFF(0, V_date) / 365 AS INT), 0) = V_date -- if first day of year",
        "DATE_TRUNC('YEAR', CAST(V_date AS DATE)) = CAST(V_date AS DATE) -- if first day of year",
    )
    out = out.replace(
        "V_dateID",
        "CAST(date_format(CAST(V_date AS DATE), 'yyyyMMdd') AS int)",
    )
    out = re.sub(
        r"\bV_dateid\b",
        "CAST(date_format(CAST(V_date AS DATE), 'yyyyMMdd') AS int)",
        out,
        flags=re.IGNORECASE,
    )
    out = out.replace(
        "DROP VIEW IF EXISTS TEMP_TABLE_Ext_FSE_PositionChangeLog_CID;\n\nCREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Ext_FSE_PositionChangeLog_CID AS\nselect distinct CID \n\nfrom dwh_daily_process.migration_tables.Ext_FSE_PositionChangeLog;\n--------------------\n-- Update in CFD to Real \n\ninsert into  TEMP_TABLE_Ext_FSE_PositionChangeLog_CID\nselect distinct CID \nfrom dwh_daily_process.migration_tables.Ext_FSE_TotalPositionAmount where CID not in ( select CID from TEMP_TABLE_Ext_FSE_PositionChangeLog_CID);\n----------------------",
        "DROP VIEW IF EXISTS TEMP_TABLE_Ext_FSE_PositionChangeLog_CID;\n\nCREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Ext_FSE_PositionChangeLog_CID AS\nSELECT DISTINCT CID\nFROM (\n  SELECT CID FROM dwh_daily_process.migration_tables.Ext_FSE_PositionChangeLog\n  UNION ALL\n  SELECT CID FROM dwh_daily_process.migration_tables.Ext_FSE_TotalPositionAmount\n);\n----------------------",
    )
    out = re.sub(
        r"DROP VIEW IF EXISTS TEMP_TABLE_TotalCashPreviousDate;[\s\S]*?--create CLUSTERED index #TotalCashPreviousDate on #TotalCashPreviousDate\(CID\);",
        (
            "DROP TABLE IF EXISTS TEMP_TABLE_TotalCashPreviousDate;\n"
            "CREATE OR REPLACE TABLE TEMP_TABLE_TotalCashPreviousDate (\n"
            "  DateRangeID BIGINT NOT NULL,\n"
            "  CID INT NOT NULL,\n"
            "  TotalCashPreviousDate DECIMAL(38,10)\n"
            ") USING DELTA;\n"
            "INSERT INTO TEMP_TABLE_TotalCashPreviousDate\n"
            "SELECT\n"
            "  CAST(a.DateRangeID AS BIGINT) AS DateRangeID,\n"
            "  CAST(a.CID AS INT) AS CID,\n"
            "  CAST(a.TotalCash AS DECIMAL(38,10)) AS TotalCashPreviousDate\n"
            "FROM dwh_daily_process.migration_tables.Fact_SnapshotEquity a\n"
            "WHERE left(CAST(a.DateRangeID AS STRING), 4) = CAST((\n"
            "  CASE\n"
            "    WHEN DATE_TRUNC('YEAR', CAST(V_date AS DATE)) = CAST(V_date AS DATE) THEN year(V_date)-1\n"
            "    ELSE year(V_date)\n"
            "  END\n"
            ") AS STRING)\n"
            "AND right(CAST(a.DateRangeID AS STRING), 4) = '1231';\n"
            "--create CLUSTERED index #TotalCashPreviousDate on #TotalCashPreviousDate(CID);"
        ),
        out,
        flags=re.IGNORECASE,
    )
    out = out.replace(
        "CAST(left(CAST(DateRangeID AS STRING),4)+right(CAST(DateRangeID AS STRING),4) AS TIMESTAMP)>=V_maxentrydate",
        "TO_DATE(left(CAST(a.DateRangeID AS STRING),4)||right(CAST(a.DateRangeID AS STRING),4), 'yyyyMMdd') >= CAST(V_maxentrydate AS DATE)",
    )
    out = out.replace(
        "DateRangeID=CAST(left(CAST(DateRangeID AS STRING),8)+right(date_format(V_daybefore, 'yyyyMMdd'),4) AS bigint)",
        "DateRangeID=COALESCE(CAST(left(CAST(a.DateRangeID AS STRING),8)||right(date_format(V_daybefore, 'yyyyMMdd'),4) AS bigint), a.DateRangeID)",
    )
    # T-SQL string `+` is concatenation; Databricks treats `+` on strings as numeric
    # addition. Every DateRangeID the SP builds via `+` was being mangled
    # (e.g. '20260621' + '1231' -> 20261852 instead of '202606211231'). Convert the
    # string-concatenation `+` to `||`. (Genuine numeric `+` like amount sums is untouched.)
    out = out.replace(
        "date_format(V_date, 'yyyyMMdd')+right(date_format(V_largedate, 'yyyyMMdd'),4)",
        "date_format(V_date, 'yyyyMMdd')||right(date_format(V_largedate, 'yyyyMMdd'),4)",
    )
    out = out.replace(
        "left(CAST(DateRangeID AS STRING),4)+right(CAST(DateRangeID AS STRING),4)",
        "left(CAST(DateRangeID AS STRING),4)||right(CAST(DateRangeID AS STRING),4)",
    )
    # Synapse used `MERGE ... OUTPUT $action, inserted.CID, inserted.DateRangeID INTO
    # #outputdata` to capture EXACTLY the rows the merge changed (the carried-forward
    # CIDs). Databricks MERGE has no OUTPUT clause, and the original migration replaced
    # it with a blanket `SELECT ... WHERE DateRangeID <> today`, which captures the whole
    # history -> the re-insert then emits a today-row for nearly every CID. Reproduce the
    # OUTPUT semantics: capture the changed+open CIDs BEFORE the merge (same predicate the
    # merge's WHEN MATCHED uses), then drop the blanket capture.
    change_cols = [
        "TotalPositionsAmount", "TotalCash", "InProcessCashouts", "TotalMirrorPositionsAmount",
        "TotalStockPositionAmount", "TotalMirrorStockPositionAmount", "TotalCryptoPositionAmount",
        "TotalMirrorCryptoPositionAmount", "TotalRealStocks", "TotalRealCrypto", "TotalRealCryptoLoan",
        "TotalMirrorCash", "TotalStockOrders", "TotalMirrorStockOrders", "BonusCredit",
        "TotalCryptoPositionAmount_TRS", "TotalMirrorCryptoPositionAmount_TRS", "Total_TRSCrypto",
        "TotalMirrorRealFuturesPositionAmount", "TotalRealFutures", "TotalFuturesProviderMargin",
        "TotalFuturesLockedCash", "TotalStocksMargin", "TotalStockMarginLoanValue",
    ]
    change_pred = " OR ".join(f"a.{c}<>b.{c}" for c in change_cols)
    capture_before_merge = (
        "INSERT INTO TEMP_TABLE_outputdata\n"
        "SELECT 'UPDATE' AS Action, a.CID, a.DateRangeID\n"
        "FROM dwh_daily_process.migration_tables.Fact_SnapshotEquity a\n"
        "JOIN dwh_daily_process.migration_tables.Ext_FSE_Fact_SnapshotEquity b ON a.CID=b.CID\n"
        f"WHERE ({change_pred})\n"
        "AND TO_DATE(left(CAST(a.DateRangeID AS STRING),4)||right(CAST(a.DateRangeID AS STRING),4), 'yyyyMMdd') "
        ">= CAST(V_maxentrydate AS DATE);\n"
    )
    # Remove the blanket post-merge capture FIRST (so the regex can't span the injected
    # pre-merge capture block below).
    out = re.sub(
        r"INSERT INTO TEMP_TABLE_outputdata\s+SELECT 'UPDATE' AS action,.*?WHERE DateRangeID <>.*?;",
        "-- [outputdata captured before MERGE -- OUTPUT-clause equivalent]",
        out,
        count=1,
        flags=re.DOTALL,
    )
    out = out.replace(
        "MERGE INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity AS a",
        capture_before_merge + "MERGE INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity AS a",
        1,
    )
    out = re.sub(
        r"SET V_rowcount = \(\s*SELECT\s*SUM\(row_count\) FROM sys\.dm_pdw_request_steps[\s\S]*?LIMIT 1\);",
        "SET V_rowcount = 0;",
        out,
        flags=re.IGNORECASE,
    )
    # Restore core DML that was accidentally left inside stub comments.
    out = re.sub(
        r"-- \[stub\] auxiliary SP call elided \(helper not deployed / not needed in Databricks\)\s*INSERT INTO dwh_daily_process\.migration_tables\.Fact_SnapshotEquity",
        "INSERT INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"-- \[stub\] auxiliary SP call elided \(helper not deployed / not needed in Databricks\)\s*INSERT INTO dwh_daily_process\.migration_tables\.Dim_Range",
        "INSERT INTO dwh_daily_process.migration_tables.Dim_Range",
        out,
        flags=re.IGNORECASE,
    )
    out = re.sub(
        r"-- \[stub\] auxiliary SP call elided \(helper not deployed / not needed in Databricks\)\s*INSERT INTO dwh_daily_process\.migration_tables\.Fact_SnapshotEquity",
        "INSERT INTO dwh_daily_process.migration_tables.Fact_SnapshotEquity",
        out,
        flags=re.IGNORECASE,
    )
    out = out.replace(
        "AND CID NOT IN (SELECT CID FROM TEMP_TABLE_outputdata WHERE DateRangeID <> CAST(CAST(YEAR(V_date) AS STRING)||'01011231' AS BIGINT))\nSET V_rowcount",
        "AND CID NOT IN (SELECT CID FROM TEMP_TABLE_outputdata WHERE DateRangeID <> CAST(CAST(YEAR(V_date) AS STRING)||'01011231' AS BIGINT));\nSET V_rowcount",
    )
    out = out.replace(
        "AND UpdateDate > V_maxupdatedate;",
        ";",
    )
    out = out.replace(
        "DROP VIEW IF EXISTS TEMP_TABLE_TotalCashPreviousDate;",
        "DROP TABLE IF EXISTS TEMP_TABLE_TotalCashPreviousDate;",
    )
    return out


def _patch_inprocesscashouts(body: str) -> str:
    return """BEGIN
DECLARE V_auxdate TIMESTAMP;
SET V_auxdate = DATEADD(DAY, 1, CAST(V_TargetDate AS DATE));

INSERT INTO dwh_daily_process.migration_tables.Ext_FSE_InProcessCashouts
(
  CID,
  InProcessCashouts,
  DateModified
)
WITH
ProcessingDates AS (
  SELECT WithdrawID
  FROM dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawAction
  WHERE CashoutStatusID IN (3,4,5,6)
    AND ModificationDate < V_auxdate
  GROUP BY WithdrawID
),
a AS (
  SELECT
    w.CID,
    SUM(w.Amount) AS InProcessCashouts,
    SUM(w.Fee) AS Fee
  FROM dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw w
  LEFT JOIN ProcessingDates p ON p.WithdrawID = w.WithdrawID
  WHERE w.RequestDate < V_auxdate
    AND p.WithdrawID IS NULL
    AND NOT (w.CashoutStatusID IN (3,4,5,6) AND w.ModificationDate < V_auxdate)
  GROUP BY w.CID
),
b AS (
  SELECT
    CID,
    SUM(PartiallyProcessedAmount) AS PartiallyProcessedAmount,
    SUM(PartiallyInProcessAmount) AS PartiallyInProcessAmount,
    SUM(Fee) AS Fee
  FROM (
    SELECT
      CID,
      SUM(PaymentAmount) AS PartiallyProcessedAmount,
      WithdrawID,
      RequestAmount - SUM(PaymentAmount) AS PartiallyInProcessAmount,
      AVG(Fee) AS Fee
    FROM (
      SELECT
        BWDR.CID,
        PaymentsStatusFromHistory.StatusFromHistory,
        BWDR.Amount AS RequestAmount,
        BWDR.WithdrawID,
        BWTF.Amount AS PaymentAmount,
        BWDR.Fee
      FROM (
        SELECT
          HWTFA.BW2F_ID,
          HWTFA.CashoutStatusID AS StatusFromHistory,
          ROW_NUMBER() OVER (PARTITION BY HWTFA.BW2F_ID ORDER BY HWTFA.ModificationDate DESC, HWTFA.WithdrawToFundingActionID DESC) AS Rank,
          HWTFA.WithdrawID
        FROM (
          SELECT
            BWDR.WithdrawID,
            HWDA.CashoutStatusID AS StatusFromHistory,
            ROW_NUMBER() OVER (PARTITION BY HWDA.WithdrawID ORDER BY HWDA.WithdrawActionID DESC) AS Rank
          FROM dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw BWDR
          JOIN dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawAction HWDA
            ON BWDR.WithdrawID = HWDA.WithdrawID
          WHERE HWDA.ModificationDate < V_auxdate
        ) RequestsStatusFromHistory
        JOIN dwh_daily_process.migration_tables.Ext_FSE_History_WithdrawToFundingAction HWTFA
          ON RequestsStatusFromHistory.WithdrawID = HWTFA.WithdrawID
         AND RequestsStatusFromHistory.StatusFromHistory IN (5,2)
         AND RequestsStatusFromHistory.Rank = 1
        WHERE HWTFA.ModificationDate < V_auxdate
      ) PaymentsStatusFromHistory
      JOIN dwh_daily_process.migration_tables.Ext_FSE_Billing_Withdraw BWDR
        ON BWDR.WithdrawID = PaymentsStatusFromHistory.WithdrawID
       AND PaymentsStatusFromHistory.Rank = 1
       AND PaymentsStatusFromHistory.StatusFromHistory = 3
      JOIN dwh_daily_process.migration_tables.Ext_FSE_Billing_WithdrawToFunding BWTF
        ON BWTF.ID = PaymentsStatusFromHistory.BW2F_ID
    ) PartiallyProcessedWithdrawIDs
    GROUP BY CID, RequestAmount, WithdrawID
  ) s
  GROUP BY CID
)
SELECT
  COALESCE(a.CID, b.CID) AS CID,
  COALESCE(a.InProcessCashouts, 0) + COALESCE(b.PartiallyInProcessAmount, 0) + COALESCE(a.Fee, 0) + COALESCE(b.Fee, 0) AS InProcessCashouts,
  V_TargetDate AS DateModified
FROM a
FULL JOIN b ON a.CID = b.CID
WHERE COALESCE(a.InProcessCashouts, 0) + COALESCE(b.PartiallyInProcessAmount, 0) + COALESCE(a.Fee, 0) + COALESCE(b.Fee, 0) <> 0.00;
END"""


def _patch_totalpositionamount(body: str) -> str:
    out = body
    # Keep helper logic intact; normalize DATEID derivation.
    out = out.replace(
        "SET V_dateID = CAST(date_format(V_TargetDate, 'yyyyMMdd') AS int)",
        "SET V_dateID = CAST(date_format(CAST(V_TargetDate AS DATE), 'yyyyMMdd') AS int)",
    )
    out = out.replace(
        """--------------------------#futures--------------------------
DROP VIEW IF EXISTS TEMP_TABLE_futures;
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_futures  
 AS
SELECT InstrumentID,IsFuture,ProviderMarginPerLot
from dwh_daily_process.migration_tables.Dim_Instrument_Snapshot
where IsFuture = 1
AND DateID = V_dateID
;
call `dbo`.`LastRowCount`( 'futures' , V_row_count

);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)""",
        """--------------------------#futures--------------------------""",
    )
    out = out.replace(
        "left join TEMP_TABLE_futures f\n\tON a.InstrumentID = f.InstrumentID",
        "left join (\nSELECT InstrumentID, IsFuture, ProviderMarginPerLot\nfrom dwh_daily_process.migration_tables.Dim_Instrument_Snapshot\nwhere IsFuture = 1\n  AND DateID = CAST(date_format(CAST(V_TargetDate AS DATE), 'yyyyMMdd') AS int)\n) f\n\tON a.InstrumentID = f.InstrumentID",
    )
    return out


def _create_proc(w, wid: str, proc: str, param_sig: str, body: str) -> None:
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        f"dwh_daily_process.migration_tables.{proc}({param_sig}) "
        "LANGUAGE SQL "
        "SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    for src, dst, sig in PROC_PLAN:
        body = _fetch_body(w, wid, src)
        if dst == "sp_fact_snapshotequity_dl_to_synapse_autopoc":
            body = _patch_wrapper(body)
        elif dst == "sp_fact_snapshotequity_extract_autopoc":
            body = _patch_extract_only(body)
        elif src == "sp_fact_snapshotequity":
            body = _patch_core(body)
        elif src == "sp_fact_snapshotequity_inprocesscashouts":
            body = _patch_inprocesscashouts(body)
        elif src == "sp_fact_snapshotequity_totalpositionamount":
            body = _patch_totalpositionamount(body)
        _create_proc(w, wid, dst, sig, body)
        print(f"created_or_updated={dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
