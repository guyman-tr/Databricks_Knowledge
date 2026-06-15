"""Manual Cursor-via-MCP eval run.

What this represents: the Cursor agent (me) acted as the LLM client of the
custom Databricks MCP. For each case I:
  1. Called skills_find_skills(question)         (via Cursor's CallMcpTool)
  2. Called skills_get_skill(top match)          (via Cursor's CallMcpTool)
  3. Authored SQL grounded in the activated body (this file)
  4. Executed the SQL via the same SDK path the MCP would use
  5. Recorded the observed scalar

The skill IDs activated, per case family, are noted in CASE_AUTHORING_NOTES below.
The SQL here is the SQL I (the Cursor agent) wrote — NOT the pinned UC SQL.

Then we hand the (case_id, observed_value) list to the harness runner via a
custom SUT that just dictionary-looks-up the answer; the harness scores it
exactly the way it would any other SUT, with sut_name='cursor_via_mcp'.

This file is the durable record of today's manual run. Future daily runs would
be done by a fresh Cursor session repeating the same protocol on the same 15
cases — the answers will diverge if the skill corpus drifts or the data drifts.
"""
from __future__ import annotations

import datetime as dt
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
sys.path.insert(0, ROOT)

from tools.eval_suite.harness import load_cases, run_cases, write_telemetry
from tools.eval_suite.harness.suts.base import SUT, SUTResponse
from tools.eval_suite.harness.suts.direct_sql import DirectSQLSUT


# ----------------------------------------------------------------------------
# Skill activations (from skills_find_skills + skills_get_skill, run via MCP)
# ----------------------------------------------------------------------------
#
# - Revenue family (10-15):  domain-revenue-and-fees      (score 1.0)
# - MIMO family (3,4,5,6,7): domain-payments              (will activate per call)
# - AUM family (1, 2):       domain-payments + cross-cutting (rollforward)
# - PnL family  (8, 9):      domain-trading
#
# All cases ground the IsValidCustomer=1 SCD-2 join via cross-cutting/
# valid-users-filter-contract.md (DEFAULT-ON omni-filter).


# ----------------------------------------------------------------------------
# Per-case SQLs authored from the activated skill bodies.
# ----------------------------------------------------------------------------

# Canonical SCD-2 valid-customer join (per cross-cutting contract):
SCD2_JOIN = """JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked snap
  ON snap.RealCID = d.RealCID
 AND snap.IsValidCustomer = 1
 AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID"""

CASE_SQLS: dict[str, str] = {
    # === Revenue family — domain-revenue-and-fees ===

    "ddr_revenue_totals_yesterday": f"""
SELECT SUM(d.Amount) AS TotalRevenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND d.IncludedInTotalRevenue = 1
""",
    "ddr_revenue_admin_yesterday": f"""
SELECT SUM(d.Amount) AS AdminFee
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics m
  ON m.RevenueMetricID = d.RevenueMetricID
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND m.RevenueMetricName = 'AdminFee'
""",
    "ddr_revenue_conversion_fee_yesterday": f"""
SELECT SUM(d.Amount) AS ConversionFee
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics m
  ON m.RevenueMetricID = d.RevenueMetricID
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND m.RevenueMetricName = 'ConversionFee'
""",
    "ddr_revenue_full_commission_yesterday": f"""
SELECT SUM(d.Amount) AS FullCommission
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics m
  ON m.RevenueMetricID = d.RevenueMetricID
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND m.RevenueMetricName = 'FullCommission'
""",
    "ddr_revenue_rollover_yesterday": f"""
SELECT SUM(d.Amount) AS RolloverFee
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics m
  ON m.RevenueMetricID = d.RevenueMetricID
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND m.RevenueMetricName = 'RollOverFee'
""",
    "ddr_revenue_spot_adjust_yesterday": f"""
SELECT SUM(d.Amount) AS SpotAdjust
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions d
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics m
  ON m.RevenueMetricID = d.RevenueMetricID
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND m.RevenueMetricName = 'SpotPriceAdjustment'
""",

    # === MIMO family — domain-payments ===

    "ddr_mimo_global_deposits_amount_yesterday": f"""
SELECT SUM(d.Amount) AS GlobalDepositsAmount
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms d
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND d.MIMOTypeID = 1            -- Deposit
  AND d.IsInternalTransfer = 0
""",
    "ddr_mimo_global_deposits_count_yesterday": f"""
SELECT COUNT(*) AS GlobalDepositsCount
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms d
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND d.MIMOTypeID = 1
  AND d.IsInternalTransfer = 0
""",
    "ddr_mimo_external_deposits_tp_yesterday": f"""
SELECT SUM(d.Amount) AS ExternalDepositsTP
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms d
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND d.MIMOTypeID = 1
  AND d.IsInternalTransfer = 0
  AND d.MIMOPlatform = 'TradingPlatform'
""",
    "ddr_mimo_global_cashout_users_yesterday": f"""
SELECT COUNT(DISTINCT d.RealCID) AS GlobalCashedOutUsers
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status d
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND d.GlobalCashedOut = 1
""",
    "ddr_mimo_tp_first_funded_yesterday": f"""
SELECT COUNT(DISTINCT d.RealCID) AS TPFirstFunded
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status d
{SCD2_JOIN}
WHERE d.DateID = 20260608
  AND d.TPFirstDeposited = 1
""",

    # === AUM family — domain-payments / cross-cutting ===

    "ddr_aum_equity_global_yesterday": f"""
SELECT SUM(d.EquityGlobal) AS EquityGlobal
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum d
{SCD2_JOIN}
WHERE d.DateID = 20260608
""",
    "ddr_aum_realized_equity_global_yesterday": f"""
SELECT SUM(d.RealizedEquityGlobal) AS RealizedEquityGlobal
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum d
{SCD2_JOIN}
WHERE d.DateID = 20260608
""",

    # === PnL family — domain-trading ===

    "ddr_pnl_daily_total_pnl_yesterday": f"""
SELECT SUM(d.NetProfit + d.UnrealizedPnLChange) AS DailyTotalPnL
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl d
{SCD2_JOIN}
WHERE d.DateID = 20260608
""",
    "ddr_pnl_total_position_pnl_yesterday": f"""
SELECT SUM(d.PositionPnL) AS TotalPositionPnL
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl d
{SCD2_JOIN}
WHERE d.DateID = 20260608
""",
}


class CursorViaMcpSUT(SUT):
    """SUT that returns my pre-authored answer for each case_id.

    The 'asking' was already done via skills_find_skills + skills_get_skill +
    me-authoring-SQL. Execution happens here, lazily, via the same SDK path
    the harness uses for direct_sql. Kept in a separate SUT so telemetry has
    sut_name='cursor_via_mcp'.
    """
    name = "cursor_via_mcp"

    def __init__(self):
        self._sql_sut = DirectSQLSUT()
        self._cache: dict[str, tuple[float | None, str | None]] = {}

    def _execute(self, case_id: str) -> tuple[float | None, str | None]:
        if case_id in self._cache:
            return self._cache[case_id]
        sql = CASE_SQLS.get(case_id)
        if not sql:
            self._cache[case_id] = (None, None)
            return None, None
        try:
            cols, rows = self._sql_sut._run_sql(sql)
            v = rows[0][0] if rows and rows[0] else None
            scalar = float(v) if v is not None else None
            self._cache[case_id] = (scalar, sql)
            return scalar, sql
        except Exception as e:
            self._cache[case_id] = (None, f"ERROR: {e!s}")
            return None, f"ERROR: {e!s}"

    def ask(self, question: str, case) -> SUTResponse:
        scalar, sql = self._execute(case.case_id)
        if isinstance(sql, str) and sql.startswith("ERROR:"):
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name},
                error=sql,
            )
        text = f"Answer: {scalar:,.4f}" if scalar is not None else "(no result)"
        return SUTResponse(
            numeric_answer=scalar,
            text_answer=text,
            sql_used=sql,
            raw={
                "backend": self.name,
                "skills_activated": _skills_for(case.case_id),
            },
        )


def _skills_for(case_id: str) -> list[str]:
    if case_id.startswith("ddr_revenue_"):
        return ["domain-revenue-and-fees", "cross-cutting"]
    if case_id.startswith("ddr_mimo_") or case_id.startswith("ddr_aum_"):
        return ["domain-payments", "cross-cutting"]
    if case_id.startswith("ddr_pnl_"):
        return ["domain-trading", "cross-cutting"]
    return ["cross-cutting"]


def main() -> int:
    cases_root = os.path.join(ROOT, "tools", "eval_suite", "cases")
    cases = load_cases(cases_root)
    print(f"Loaded {len(cases)} cases.")

    sut = CursorViaMcpSUT()
    baseline = DirectSQLSUT()
    results = run_cases(cases, sut, baseline_sut=baseline, run_id=
                       f"cursor-via-mcp-{dt.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}")

    n_pass = sum(1 for r in results if r.passed)
    print()
    print(f"Summary: {n_pass}/{len(results)} passed")
    from collections import Counter
    print(f"Drift: {dict(Counter(r.drift_verdict for r in results))}")

    out = os.path.join(ROOT, "audits", "eval_suite", "runs",
                       f"cursor-via-mcp-{dt.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}.csv")
    write_telemetry(results, target="csv", out_path=out)
    print(f"Telemetry: {out}")
    return 0 if n_pass == len(results) else 2


if __name__ == "__main__":
    sys.exit(main())
