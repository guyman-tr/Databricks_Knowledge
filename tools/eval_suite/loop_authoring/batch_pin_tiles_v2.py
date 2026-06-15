"""V2 of batch_pin_tiles.py — incorporates all fixes from triage:
  #4  spot_adjust:  Synapse column is `SpotPriceAdjustment` (not `SpotAdjustFee`)
  #6  TP deposits:  UC MIMOPlatform = 'TradingPlatform' (not 'TP')
  #7  Global Dep:   exclude internal transfers (matches Synapse `GlobalDepositsAmount`)
  #8  Ext TP Dep:   same MIMOPlatform fix as #6
  #9  Int TP Dep:   same MIMOPlatform fix as #6
  #14 DailyPnL:     Synapse query was double-counting; use SUM(DailyTotalPnL)

Only re-runs the previously broken tiles to save time. Merges with existing rows.
"""
from __future__ import annotations

import csv
import os
import sys
import time

REPO_ROOT = os.path.dirname(os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "eval_suite"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import synapse  # noqa: E402
from dbx import make_client, run_sql  # noqa: E402

ASOF = "20260608"

UC_FACT_REVENUE = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
UC_FACT_AUM = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum"
UC_FACT_PNL = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl"
UC_FACT_MIMO = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms"
UC_DAILY_STATUS = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status"
UC_SCD2 = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked"


def uc_mimo_sum(extra: str) -> str:
    return f"""
SELECT SUM(d.AmountUSD) AS value
FROM {UC_FACT_MIMO} d
JOIN {UC_SCD2} snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
  AND {extra}
""".strip()


def uc_pnl_sum(col: str) -> str:
    return f"""
SELECT SUM(d.{col}) AS value
FROM {UC_FACT_PNL} d
JOIN {UC_SCD2} snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
""".strip()


# Re-run just the 5 broken tiles, with corrected SQL
BROKEN_TILES = [
    {
        "case_id": "ddr_revenue_spot_adjust_yesterday",
        "syn_select": "SUM(SpotPriceAdjustment)",
        "uc_sql": f"""
SELECT SUM(d.Amount) AS value
FROM {UC_FACT_REVENUE} d
JOIN {UC_SCD2} snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
  AND d.Metric = 'SpotPriceAdjustment'
  AND d.IncludedInTotalRevenue = 1
""".strip(),
    },
    {
        "case_id": "ddr_mimo_tp_deposits_amount_yesterday",
        "syn_select": "SUM(InternalDepositsTPAmount + ExternalDepositsTPAmount)",
        "uc_sql": uc_mimo_sum(
            "d.MIMOAction = 'Deposit' AND d.MIMOPlatform = 'TradingPlatform' "
            "AND d.IsRedeem = 0"
        ),
    },
    {
        "case_id": "ddr_mimo_global_deposits_amount_yesterday",
        "syn_select": "SUM(GlobalDepositsAmount)",
        # Excludes internal transfers — matches Synapse GlobalDepositsAmount
        "uc_sql": uc_mimo_sum(
            "d.MIMOAction = 'Deposit' AND d.IsRedeem = 0 AND d.IsInternalTransfer = 0"
        ),
    },
    {
        "case_id": "ddr_mimo_external_deposits_tp_yesterday",
        "syn_select": "SUM(ExternalDepositsTPAmount)",
        "uc_sql": uc_mimo_sum(
            "d.MIMOAction = 'Deposit' AND d.MIMOPlatform = 'TradingPlatform' "
            "AND d.IsInternalTransfer = 0 AND d.IsRedeem = 0"
        ),
    },
    {
        "case_id": "ddr_mimo_internal_deposits_tp_yesterday",
        "syn_select": "SUM(InternalDepositsTPAmount)",
        "uc_sql": uc_mimo_sum(
            "d.MIMOAction = 'Deposit' AND d.MIMOPlatform = 'TradingPlatform' "
            "AND d.IsInternalTransfer = 1 AND d.IsRedeem = 0"
        ),
    },
    {
        "case_id": "ddr_pnl_daily_realized_pnl_yesterday",
        # Synapse: just sum the headline column on the TVF
        "syn_select": "SUM(DailyTotalPnL)",
        # UC: sum NetProfit + UnrealizedPnLChange across the whole fact_pnl day
        "uc_sql": uc_pnl_sum("NetProfit + UnrealizedPnLChange"),
    },
]


def main() -> int:
    out_log = os.path.join(REPO_ROOT, "audits", "eval_suite", "batch_pin_v2.log")
    log_lines = []
    print(f"Re-pinning {len(BROKEN_TILES)} broken tiles for asof={ASOF}\n")

    for i, t in enumerate(BROKEN_TILES, 1):
        print(f"[{i}/{len(BROKEN_TILES)}] {t['case_id']}")
        log_lines.append(f"\n[{i}/{len(BROKEN_TILES)}] {t['case_id']}")

        # Synapse
        syn_sql = (
            f"SELECT {t['syn_select']} AS value\n"
            f"FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('{ASOF}', 0)\n"
            f"WHERE IsCreditReportValidCB = 1"
        )
        try:
            t0 = time.time()
            r = synapse.run(syn_sql)
            syn_value = float(r.rows[0][0]) if r.rows and r.rows[0][0] is not None else None
            syn_ms = int((time.time() - t0) * 1000)
            print(f"   syn = {syn_value:>20,.6f}  ({syn_ms} ms)" if syn_value is not None
                  else "   syn = NULL")
            log_lines.append(f"   syn = {syn_value} ({syn_ms} ms)")
        except Exception as e:
            print(f"   syn ERROR: {e}")
            log_lines.append(f"   syn ERROR: {e}")
            syn_value = None

        # UC
        try:
            w = make_client()
            t0 = time.time()
            r = run_sql(w, t["uc_sql"])
            uc_value = float(r.rows[0][0]) if r.rows and r.rows[0][0] is not None else None
            uc_ms = int((time.time() - t0) * 1000)
            print(f"   uc  = {uc_value:>20,.6f}  ({uc_ms} ms)" if uc_value is not None else "   uc = NULL")
            log_lines.append(f"   uc  = {uc_value} ({uc_ms} ms)")
        except Exception as e:
            print(f"   uc ERROR: {e}")
            log_lines.append(f"   uc ERROR: {e}")
            uc_value = None

        if syn_value is not None and uc_value is not None:
            diff = uc_value - syn_value
            pct = (diff / syn_value * 100.0) if syn_value != 0 else 0.0
            print(f"   diff= {diff:>20,.6f}  ({pct:+.4f}%)\n")
            log_lines.append(f"   diff= {diff} ({pct:+.4f}%)")

    with open(out_log, "w", encoding="utf-8") as f:
        f.write("\n".join(log_lines))
    print(f"Wrote {out_log}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
