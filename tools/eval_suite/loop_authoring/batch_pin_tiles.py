"""Batch-pin ground truth (Synapse) + UC parity for 14 DDR tiles.

For each tile, we pin ONE scalar headline metric:
  Synapse: SELECT SUM(<col>) FROM Function_DDR_Aggregation_Yesterday('20260608', 0) WHERE IsCreditReportValidCB = 1
  UC:      Hand-built equivalent against the right ddr_fact_* mirror joined to the SCD-2 view.

Outputs:
  - audits/eval_suite/tile_pinned_values.csv   (machine-readable)
  - audits/eval_suite/tile_pinned_values.txt   (human-readable)

The actual case YAMLs are emitted by `emit_tile_yamls.py` reading from the CSV.
"""
from __future__ import annotations

import csv
import os
import sys
import time
from dataclasses import dataclass

REPO_ROOT = os.path.dirname(os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
sys.path.insert(0, os.path.join(REPO_ROOT, "tools"))
sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "eval_suite"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import synapse  # tools/eval_suite/loop_authoring/synapse.py
from dbx import make_client, run_sql  # tools/eval_suite/dbx.py

ASOF = "20260608"
ASOF_DASHED = "2026-06-08"

UC_FACT_REVENUE = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
UC_FACT_AUM = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum"
UC_FACT_PNL = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl"
UC_FACT_MIMO = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms"
UC_DAILY_STATUS = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status"
UC_SCD2 = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked"


@dataclass
class TileSpec:
    case_id: str
    tab: str               # "revenue" / "mimo" / "aum_pnl"
    sheet: str             # Tableau sheet name
    dashboard: str         # Tableau dashboard name
    headline_field: str    # e.g. "FullCommission", "GlobalDepositsAmount"
    nl_question: str
    syn_select: str        # SQL SELECT expression on the TVF row, e.g. "SUM(FullCommission)"
    uc_sql: str            # the canonical UC equivalent for the SAME scalar
    notes: str = ""


# -------------------------------------------------------------
# Helpers to build canonical UC SQL for the 3 grain-types we need
# -------------------------------------------------------------

def uc_revenue_sum(metric_in: list[str]) -> str:
    """Sum revenue Amount for a given subset of `Metric` values, valid-CB cohort."""
    metric_list = ", ".join(f"'{m}'" for m in metric_in)
    return f"""
SELECT SUM(d.Amount) AS value
FROM {UC_FACT_REVENUE} d
JOIN {UC_SCD2} snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
  AND d.Metric IN ({metric_list})
  AND d.IncludedInTotalRevenue = 1
""".strip()


def uc_daily_status_sum(col: str) -> str:
    """Sum a wide column off `customer_daily_status` (e.g. GlobalCashedOut, Redeemed),
    valid-CB cohort. The status table already has IsCreditReportValidCB on it,
    so we filter directly without SCD-2 (faster and equivalent for status grain).
    """
    return f"""
SELECT SUM(d.{col}) AS value
FROM {UC_DAILY_STATUS} d
WHERE d.DateID = {ASOF}
  AND d.IsCreditReportValidCB = 1
""".strip()


def uc_aum_sum(col: str) -> str:
    """Sum a wide column off `fact_aum` for valid-CB cohort, via SCD-2 join."""
    return f"""
SELECT SUM(d.{col}) AS value
FROM {UC_FACT_AUM} d
JOIN {UC_SCD2} snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
""".strip()


def uc_pnl_sum(col: str, where_extra: str = "") -> str:
    """Sum a column off `fact_pnl` for valid-CB cohort, via SCD-2 join.
    fact_pnl is long-form keyed by (DateID, RealCID, InstrumentTypeID, IsSettled, IsCopy);
    aggregations across all those keys yield daily totals.
    """
    extra = f"AND {where_extra}" if where_extra else ""
    return f"""
SELECT SUM(d.{col}) AS value
FROM {UC_FACT_PNL} d
JOIN {UC_SCD2} snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
  {extra}
""".strip()


def uc_mimo_sum_amount(where_extra: str) -> str:
    """Sum AmountUSD off `fact_mimo_allplatforms` with the given extra predicate."""
    return f"""
SELECT SUM(d.AmountUSD) AS value
FROM {UC_FACT_MIMO} d
JOIN {UC_SCD2} snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
  AND {where_extra}
""".strip()


# -------------------------------------------------------------
# Tile specs (14 total; tile #1 already pinned in revenue_totals_yesterday.yaml)
# -------------------------------------------------------------

TILES: list[TileSpec] = [
    # ----- Revenue tab (5 tiles in addition to tile #1) -----
    TileSpec(
        case_id="ddr_revenue_full_commission_yesterday",
        tab="revenue",
        sheet="Revenue: Commission & Other Fees",
        dashboard="Revenue: Overview & Breakdowns",
        headline_field="FullCommission",
        nl_question="What was the total Full Commission revenue for valid customers yesterday (2026-06-08)?",
        syn_select="SUM(FullCommission)",
        uc_sql=uc_revenue_sum(["FullCommission"]),
        notes="FullCommission = Commission + TicketFee + TicketFeeByPercent (computed in Synapse SP).",
    ),
    TileSpec(
        case_id="ddr_revenue_rollover_yesterday",
        tab="revenue",
        sheet="Revenue: Rollover Fees Breakdown",
        dashboard="Revenue: Overview & Breakdowns",
        headline_field="RollOverFee",
        nl_question="What was the total Rollover Fee revenue for valid customers yesterday (2026-06-08)?",
        syn_select="SUM(RollOverFee)",
        uc_sql=uc_revenue_sum(["RollOverFee"]),
    ),
    TileSpec(
        case_id="ddr_revenue_admin_yesterday",
        tab="revenue",
        sheet="Revenue: Admin Fees Breakdown",
        dashboard="Revenue: Overview & Breakdowns",
        headline_field="AdminFee",
        nl_question="What was the total Admin Fee (dormancy) revenue for valid customers yesterday (2026-06-08)?",
        syn_select="SUM(AdminFee)",
        uc_sql=uc_revenue_sum(["AdminFee"]),
    ),
    TileSpec(
        case_id="ddr_revenue_spot_adjust_yesterday",
        tab="revenue",
        sheet="Revenue: Spot Adjustment Fees Breakdown",
        dashboard="Revenue: Overview & Breakdowns",
        headline_field="SpotAdjustFee",
        nl_question="What was the total Spot Adjustment Fee revenue for valid customers yesterday (2026-06-08)?",
        syn_select="SUM(SpotAdjustFee)",
        # NOTE: UC fact uses Metric='SpotPriceAdjustment' (NOT SpotAdjustFee)
        uc_sql=uc_revenue_sum(["SpotPriceAdjustment"]),
        notes="UC Metric label is 'SpotPriceAdjustment'; Synapse TVF column is 'SpotAdjustFee'. Same dollars.",
    ),
    TileSpec(
        case_id="ddr_revenue_conversion_fee_yesterday",
        tab="revenue",
        sheet="Revenue: Commission & Other Fees",   # ConversionFee is a column on this tile
        dashboard="Revenue: Overview & Breakdowns",
        headline_field="ConversionFee",
        nl_question="What was the total Conversion Fee revenue for valid customers yesterday (2026-06-08)?",
        syn_select="SUM(ConversionFee)",
        uc_sql=uc_revenue_sum(["ConversionFee"]),
    ),

    # ----- MIMO tab (5 tiles) -----
    TileSpec(
        case_id="ddr_mimo_tp_deposits_amount_yesterday",
        tab="mimo",
        sheet="MIMO: Trading Platform's Deposits & Withdraws",
        dashboard="Money Movement",
        headline_field="Deposits to TP ($ Amount)",
        nl_question=(
            "What was the total deposit amount (USD) to the Trading Platform "
            "for valid customers yesterday (2026-06-08)? Include both internal and external deposits."
        ),
        syn_select="SUM(InternalDepositsTPAmount + ExternalDepositsTPAmount)",
        # MIMO long-form: deposits to TP with platform marker
        uc_sql=uc_mimo_sum_amount(
            "d.MIMOAction = 'Deposit' AND d.MIMOPlatform = 'TP' "
            "AND d.IsRedeem = 0"
        ),
        notes=(
            "Tile shows 'Deposits to TP ($ Amount)' = InternalDepositsTPAmount + ExternalDepositsTPAmount "
            "in the wide TVF row. UC equivalent: SUM(AmountUSD) on the long-form MIMO fact filtered to "
            "MIMOAction='Deposit' AND MIMOPlatform='TP' AND IsRedeem=0 (excludes crypto-redeem-as-deposit reclass)."
        ),
    ),
    TileSpec(
        case_id="ddr_mimo_global_deposits_amount_yesterday",
        tab="mimo",
        sheet="MIMO: Global Deposits & Withdraws",
        dashboard="Money Movement",
        headline_field="GlobalDepositsAmount",
        nl_question=(
            "What were the total global deposits (USD, all platforms — TP + IBAN + Options + MoneyFarm) "
            "for valid customers yesterday (2026-06-08)?"
        ),
        syn_select="SUM(GlobalDepositsAmount)",
        # Global = all platforms; the MIMO fact already has all platforms
        uc_sql=uc_mimo_sum_amount("d.MIMOAction = 'Deposit' AND d.IsRedeem = 0"),
    ),
    TileSpec(
        case_id="ddr_mimo_external_deposits_tp_yesterday",
        tab="mimo",
        sheet="MIMO: External Deposits to TP",
        dashboard="Money Movement",
        headline_field="ExternalDepositsTPAmount",
        nl_question=(
            "What was the total external (i.e. not internal-transfer) deposit amount (USD) to the "
            "Trading Platform for valid customers yesterday (2026-06-08)?"
        ),
        syn_select="SUM(ExternalDepositsTPAmount)",
        uc_sql=uc_mimo_sum_amount(
            "d.MIMOAction = 'Deposit' AND d.MIMOPlatform = 'TP' "
            "AND d.IsInternalTransfer = 0 AND d.IsRedeem = 0"
        ),
    ),
    TileSpec(
        case_id="ddr_mimo_internal_deposits_tp_yesterday",
        tab="mimo",
        sheet="MIMO: Internal Deposits to TP",
        dashboard="Money Movement",
        headline_field="InternalDepositsTPAmount",
        nl_question=(
            "What was the total internal-transfer deposit amount (USD) to the Trading Platform "
            "for valid customers yesterday (2026-06-08)?"
        ),
        syn_select="SUM(InternalDepositsTPAmount)",
        uc_sql=uc_mimo_sum_amount(
            "d.MIMOAction = 'Deposit' AND d.MIMOPlatform = 'TP' "
            "AND d.IsInternalTransfer = 1 AND d.IsRedeem = 0"
        ),
    ),
    TileSpec(
        case_id="ddr_mimo_global_cashout_users_yesterday",
        tab="mimo",
        sheet="MIMO: Cashout & Redeem Users Count",
        dashboard="Money Movement",
        headline_field="GlobalCashedOut",
        nl_question=(
            "How many valid customers had a successful global cashout (any platform) yesterday (2026-06-08)?"
        ),
        syn_select="SUM(GlobalCashedOut)",
        uc_sql=uc_daily_status_sum("GlobalCashedOut"),
        notes=(
            "GlobalCashedOut is a 0/1 flag per (DateID, RealCID) on the daily-status table; SUM yields a count. "
            "Distinct from MIMO event-grain — this is per-customer attribution from customer_daily_status."
        ),
    ),

    # ----- AUM & PnL tab (4 tiles) -----
    TileSpec(
        case_id="ddr_aum_equity_global_yesterday",
        tab="aum_pnl",
        sheet="AUM & PnL: Yesterday's KPIs 1",
        dashboard="AUM & PnL",
        headline_field="EquityGlobal",
        nl_question=(
            "What was the total Global Equity (TP + IBAN + Options custodied assets) "
            "for valid customers as of 2026-06-08?"
        ),
        syn_select="SUM(EquityGlobal)",
        uc_sql=uc_aum_sum("EquityGlobal"),
    ),
    TileSpec(
        case_id="ddr_aum_realized_equity_global_yesterday",
        tab="aum_pnl",
        sheet="AUM & PnL: Yesterday's KPIs 1",
        dashboard="AUM & PnL",
        headline_field="RealizedEquityGlobal",
        nl_question=(
            "What was the total Global Realized Equity (excluding unrealized PnL) "
            "for valid customers as of 2026-06-08?"
        ),
        syn_select="SUM(RealizedEquityGlobal)",
        uc_sql=uc_aum_sum("RealizedEquityGlobal"),
    ),
    TileSpec(
        case_id="ddr_pnl_total_position_pnl_yesterday",
        tab="aum_pnl",
        sheet="AUM & PnL: PnL KPIs",
        dashboard="AUM & PnL",
        headline_field="TotalPositionPNL",
        nl_question=(
            "What was the total open-position PnL (mark-to-market unrealized) "
            "for valid customers' open positions as of 2026-06-08?"
        ),
        syn_select="SUM(TotalPositionPNL)",
        # TotalPositionPNL is on the AUM fact (snapshot of open-position MtM)
        uc_sql=uc_aum_sum("TotalPositionPNL"),
    ),
    TileSpec(
        case_id="ddr_pnl_daily_realized_pnl_yesterday",
        tab="aum_pnl",
        sheet="AUM & PnL: PnL Chart",
        dashboard="AUM & PnL",
        headline_field="DailyTotalPnL",
        nl_question=(
            "What was the total realized + unrealized daily PnL across all "
            "valid customers' positions on 2026-06-08?"
        ),
        syn_select="SUM(DailyPnLStocks + DailyPnLCrypto + DailyPnLCopy + DailyPnLManual)",
        # DailyTotalPnL on canvas = NetProfit + UnrealizedPnLChange across all instrument types,
        # summed over all rows in fact_pnl for that DateID.
        uc_sql=uc_pnl_sum("NetProfit + UnrealizedPnLChange"),
        notes=(
            "Synapse TVF surfaces DailyPnLStocks/Crypto/Copy/Manual as separate columns; "
            "DailyTotalPnL on the canvas is their sum. UC fact_pnl stores NetProfit (realized) "
            "+ UnrealizedPnLChange (mark-to-market delta) per (RealCID, InstrumentTypeID, IsSettled, IsCopy)."
        ),
    ),
]


def main() -> int:
    out_csv = os.path.join(REPO_ROOT, "audits", "eval_suite", "tile_pinned_values.csv")
    out_txt = os.path.join(REPO_ROOT, "audits", "eval_suite", "tile_pinned_values.txt")

    rows = []
    log_lines = []

    print(f"Pinning {len(TILES)} tiles for asof={ASOF_DASHED}")
    print()

    for i, t in enumerate(TILES, 1):
        print(f"[{i:02d}/{len(TILES):02d}] {t.case_id}")
        log_lines.append(f"\n===== [{i:02d}/{len(TILES):02d}] {t.case_id} =====")
        log_lines.append(f"  tab:      {t.tab}")
        log_lines.append(f"  sheet:    {t.sheet}")
        log_lines.append(f"  field:    {t.headline_field}")
        log_lines.append(f"  NL:       {t.nl_question}")

        # ----- Synapse pin -----
        syn_sql = (
            f"SELECT {t.syn_select} AS value\n"
            f"FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('{ASOF}', 0)\n"
            f"WHERE IsCreditReportValidCB = 1"
        )
        try:
            t0 = time.time()
            r = synapse.run(syn_sql)
            syn_value = r.rows[0][0] if r.rows and r.rows[0][0] is not None else 0
            syn_ms = int((time.time() - t0) * 1000)
            syn_value_f = float(syn_value)
            print(f"     syn   = {syn_value_f:>20,.6f}    ({syn_ms} ms)")
            log_lines.append(f"  SYN SQL:")
            for line in syn_sql.splitlines():
                log_lines.append(f"    {line}")
            log_lines.append(f"  SYN value: {syn_value_f:,.6f}  ({syn_ms} ms)")
        except Exception as e:
            print(f"     syn   = ERROR: {e}")
            log_lines.append(f"  SYN ERROR: {e}")
            syn_value_f = None

        # ----- UC pin -----
        try:
            w = make_client()
            t0 = time.time()
            r = run_sql(w, t.uc_sql)
            uc_value = r.rows[0][0] if r.rows and r.rows[0][0] is not None else 0
            uc_ms = int((time.time() - t0) * 1000)
            uc_value_f = float(uc_value)
            print(f"     uc    = {uc_value_f:>20,.6f}    ({uc_ms} ms)")
            log_lines.append(f"  UC SQL:")
            for line in t.uc_sql.splitlines():
                log_lines.append(f"    {line}")
            log_lines.append(f"  UC value:  {uc_value_f:,.6f}  ({uc_ms} ms)")
        except Exception as e:
            print(f"     uc    = ERROR: {e}")
            log_lines.append(f"  UC ERROR: {e}")
            uc_value_f = None

        # ----- diff -----
        if syn_value_f is not None and uc_value_f is not None:
            diff = uc_value_f - syn_value_f
            pct = (diff / syn_value_f * 100.0) if syn_value_f != 0 else 0.0
            print(f"     diff  = {diff:>20,.6f}  ({pct:+.4f}%)")
            log_lines.append(f"  DIFF: {diff:,.6f}  ({pct:+.4f}%)")
        else:
            diff = None
            pct = None

        rows.append({
            "case_id": t.case_id,
            "tab": t.tab,
            "sheet": t.sheet,
            "dashboard": t.dashboard,
            "headline_field": t.headline_field,
            "nl_question": t.nl_question,
            "syn_select": t.syn_select,
            "syn_value": f"{syn_value_f:.6f}" if syn_value_f is not None else "",
            "uc_sql": t.uc_sql,
            "uc_value": f"{uc_value_f:.6f}" if uc_value_f is not None else "",
            "diff_abs": f"{diff:.6f}" if diff is not None else "",
            "diff_pct": f"{pct:.6f}" if pct is not None else "",
            "notes": t.notes,
        })
        print()

    os.makedirs(os.path.dirname(out_csv), exist_ok=True)
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    with open(out_txt, "w", encoding="utf-8") as f:
        f.write("\n".join(log_lines))
    print(f"\nWrote {out_csv}")
    print(f"Wrote {out_txt}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
