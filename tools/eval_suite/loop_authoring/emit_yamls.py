"""Emit one YAML case file per tile, following the tile #1 schema."""
from __future__ import annotations
import os, sys, json, datetime as dt, textwrap

REPO_ROOT = os.path.dirname(os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))

ASOF = "2026-06-08"
ASOF_INT = "20260608"
PINNED_AT = dt.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

UC_FACT_REVENUE = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
UC_FACT_AUM     = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum"
UC_FACT_PNL     = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl"
UC_FACT_MIMO    = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms"
UC_DAILY_STATUS = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status"
UC_SCD2         = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked"

WORKBOOK_LUID = "b5d58e4d-3644-402e-aaa2-274c0a51221a"
WORKBOOK_NAME = "eToro's Daily Data Report (New DDR 2025) - LIVE QUERY"
DATASOURCE_ID = "58f7e2fa-396a-dcc8-464f-ba7003850d07"


def yaml_str(s: str) -> str:
    """Render a string as YAML | block scalar with proper indent."""
    lines = s.strip("\n").split("\n")
    return "    " + "\n    ".join(lines)


def emit(case: dict) -> str:
    """Render one case to a YAML string."""
    cb_filter = case.get("cb_filter", "IsCreditReportValidCB = 1")
    syn_query = (
        f"    SELECT {case['syn_select']} AS value\n"
        f"    FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('{ASOF_INT}', 0)\n"
        f"    WHERE {cb_filter}"
    )

    fqns = ["bi_db_dbo.function_ddr_aggregation_yesterday"]
    fqns.extend(case.get("uc_fqns", []))
    fqns_yaml = "\n".join(f"    - {f}" for f in fqns)

    parity = case.get("parity", {})
    diff_abs = parity.get("diff_abs", 0.0)
    diff_pct = parity.get("diff_pct", 0.0)
    threshold = parity.get("threshold_pct", 0.5)
    passed = abs(diff_pct) <= threshold

    sn = case["syn_value"]
    uc = case["uc_value"]

    finding = case.get("finding") or (
        f"UC and Synapse agree to within {diff_pct:+.4f}% on asof={ASOF}.\n"
        f"Treated as parity for the eval harness (threshold {threshold}%)."
        if passed
        else f"UC and Synapse differ by {diff_pct:+.4f}% on asof={ASOF}; outside the {threshold}% threshold."
    )

    expected = case.get("expected_coverage", textwrap.dedent("""
        A correctly-skilled agent SHOULD answer this question by joining the
        relevant DDR fact mirror to the SCD-2 snapshot view with IsCreditReportValidCB=1
        (per dwh-domain/cross-cutting/valid-users-filter-contract Pattern 2 — CB regulatory variant).
        Failures to apply the SCD-2 walk OR to use IsCreditReportValidCB
        (vs IsValidCustomer or no filter at all) are skill-coverage gaps.""").strip())

    notes = case.get("notes") or ""
    notes_block = ""
    if notes:
        notes_block = (
            "\n  notes: |\n"
            + "\n".join(f"    {ln}" for ln in notes.strip().split("\n"))
        )

    return f"""id: {case['case_id']}
status: live
source_kind: tableau
provenance:
  workbook_luid: {WORKBOOK_LUID}
  workbook_name: "{WORKBOOK_NAME}"
  dashboard: "{case['dashboard']}"
  sheet: "{case['sheet']}"
  field_on_canvas: "{case['headline_field']}"
  datasource_id: "{DATASOURCE_ID}"
  datasource_name: "Main DDR Query"

asof: '{ASOF}'

natural_language_question: |
{yaml_str(case['nl_question'])}

# ----- Ground truth (Synapse PROD, faithful TVF) -----
ground_truth:
  source_db: synapse_prod
  routine: BI_DB_dbo.Function_DDR_Aggregation_Yesterday
  sql: |
{syn_query}
  value: {sn}
  pinned_at: '{PINNED_AT}'{notes_block}

# ----- UC equivalent (canonical valid-users-filter Pattern 2) -----
uc_equivalent:
  status: live
  sql: |
{yaml_str(case['uc_sql'])}
  value: {uc}
  pinned_at: '{PINNED_AT}'

# ----- Synapse-vs-UC parity -----
parity:
  diff_abs: {diff_abs}
  diff_pct: {diff_pct}
  threshold_pct: {threshold}
  passed: {str(passed).lower()}
  finding: |
{yaml_str(finding)}

# ----- Skill coverage cross-reference -----
skill_coverage:
  matched_skills:
    - dwh-domain/cross-cutting/valid-users-filter-contract
{(chr(10)).join('    - ' + s for s in case.get('extra_skills', []))}
  contract_used: "valid-users-filter-contract Rule 2 (CB regulatory variant)"
  fqns_referenced:
{fqns_yaml}
  expected_coverage_assertion: |
{yaml_str(expected)}

# ----- Scoring config for the eval harness -----
scoring:
  numeric_tolerance_pct: {case.get('tolerance', 0.5)}
  parity_diff_pct_threshold: 0.05
  judge_signal_secondary: llm

tags: {json.dumps(case['tags'])}
"""


CASES = [
    # ----- Revenue -----
    {
        "case_id": "ddr_revenue_full_commission_yesterday",
        "tab": "revenue",
        "sheet": "Revenue: Commission & Other Fees",
        "dashboard": "Revenue: Overview & Breakdowns",
        "headline_field": "FullCommission",
        "nl_question": "What was the total Full Commission revenue for valid customers yesterday (2026-06-08)? Full Commission combines retail trading commission with both fixed and percentage-based ticket fees.",
        "syn_select": "SUM(FullCommission)",
        "uc_sql": (
            f"-- Per dwh-domain/cross-cutting/valid-users-filter-contract Pattern 2.\n"
            f"-- FullCommission = Commission + TicketFee + TicketFeeByPercent in Synapse SP.\n"
            f"SELECT SUM(d.Amount) AS FullCommission\n"
            f"FROM {UC_FACT_REVENUE} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.Metric IN ('FullCommission')\n"
            f"  AND d.IncludedInTotalRevenue = 1"
        ),
        "syn_value": 1229189.310500,
        "uc_value":  1229189.310500,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_REVENUE, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-revenue-and-fees"],
        "tags": ["ddr", "revenue", "yesterday", "valid-users-cb", "commission"],
    },
    {
        "case_id": "ddr_revenue_rollover_yesterday",
        "tab": "revenue",
        "sheet": "Revenue: Rollover Fees Breakdown",
        "dashboard": "Revenue: Overview & Breakdowns",
        "headline_field": "RollOverFee",
        "nl_question": "What was the total Rollover Fee revenue for valid customers yesterday (2026-06-08)? Rollover fees are the financing charge for keeping leveraged CFD positions open overnight.",
        "syn_select": "SUM(RollOverFee)",
        "uc_sql": (
            f"SELECT SUM(d.Amount) AS RollOverFee\n"
            f"FROM {UC_FACT_REVENUE} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.Metric = 'RollOverFee'\n"
            f"  AND d.IncludedInTotalRevenue = 1"
        ),
        "syn_value": 290343.400000,
        "uc_value":  290343.400000,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_REVENUE, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-revenue-and-fees"],
        "tags": ["ddr", "revenue", "yesterday", "valid-users-cb", "rollover"],
    },
    {
        "case_id": "ddr_revenue_admin_yesterday",
        "tab": "revenue",
        "sheet": "Revenue: Admin Fees Breakdown",
        "dashboard": "Revenue: Overview & Breakdowns",
        "headline_field": "AdminFee",
        "nl_question": "What was the total Admin Fee (dormancy/inactivity fee) revenue for valid customers yesterday (2026-06-08)?",
        "syn_select": "SUM(AdminFee)",
        "uc_sql": (
            f"SELECT SUM(d.Amount) AS AdminFee\n"
            f"FROM {UC_FACT_REVENUE} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.Metric = 'AdminFee'\n"
            f"  AND d.IncludedInTotalRevenue = 1"
        ),
        "syn_value": 10619.050000,
        "uc_value":  10619.050000,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_REVENUE, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-revenue-and-fees"],
        "tags": ["ddr", "revenue", "yesterday", "valid-users-cb", "admin-fee"],
    },
    {
        "case_id": "ddr_revenue_spot_adjust_yesterday",
        "tab": "revenue",
        "sheet": "Revenue: Spot Adjustment Fees Breakdown",
        "dashboard": "Revenue: Overview & Breakdowns",
        "headline_field": "SpotPriceAdjustment",
        "nl_question": "What was the total Spot Price Adjustment fee revenue for valid customers yesterday (2026-06-08)? Spot price adjustments reflect the spread mark-up applied to bid/ask quotes.",
        "syn_select": "SUM(SpotPriceAdjustment)",
        "uc_sql": (
            f"-- Synapse TVF column name is 'SpotPriceAdjustment'; on the canvas this tile\n"
            f"-- is labelled 'Spot Adjustment' but the underlying metric is SpotPriceAdjustment.\n"
            f"SELECT SUM(d.Amount) AS SpotPriceAdjustment\n"
            f"FROM {UC_FACT_REVENUE} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.Metric = 'SpotPriceAdjustment'\n"
            f"  AND d.IncludedInTotalRevenue = 1"
        ),
        "syn_value": 1888.160000,
        "uc_value":  1888.160000,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_REVENUE, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-revenue-and-fees"],
        "tags": ["ddr", "revenue", "yesterday", "valid-users-cb", "spot-adjust"],
    },
    {
        "case_id": "ddr_revenue_conversion_fee_yesterday",
        "tab": "revenue",
        "sheet": "Revenue: Commission & Other Fees",
        "dashboard": "Revenue: Overview & Breakdowns",
        "headline_field": "ConversionFee",
        "nl_question": "What was the total Conversion Fee revenue for valid customers yesterday (2026-06-08)? Conversion fees are charged when customer trade currency differs from their wallet currency.",
        "syn_select": "SUM(ConversionFee)",
        "uc_sql": (
            f"SELECT SUM(d.Amount) AS ConversionFee\n"
            f"FROM {UC_FACT_REVENUE} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.Metric = 'ConversionFee'\n"
            f"  AND d.IncludedInTotalRevenue = 1"
        ),
        "syn_value": 414246.319200,
        "uc_value":  414246.319200,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_REVENUE, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-revenue-and-fees"],
        "tags": ["ddr", "revenue", "yesterday", "valid-users-cb", "conversion-fee"],
    },

    # ----- MIMO -----
    {
        "case_id": "ddr_mimo_global_deposits_amount_yesterday",
        "tab": "mimo",
        "sheet": "MIMO: Global Deposits & Withdraws",
        "dashboard": "Money Movement",
        "headline_field": "GlobalDepositsAmount",
        "nl_question": "What were the total external (non-internal-transfer) global deposits in USD for valid customers yesterday (2026-06-08)? Global means across all eToro platforms (TP, eMoney IBAN, Options, MoneyFarm).",
        "syn_select": "SUM(GlobalDepositsAmount)",
        "uc_sql": (
            f"-- Synapse GlobalDepositsAmount excludes internal transfers (eMoney->TP, etc).\n"
            f"-- IsRedeem=0 also excludes crypto-redeem-as-deposit reclass.\n"
            f"SELECT SUM(d.AmountUSD) AS GlobalDepositsAmount\n"
            f"FROM {UC_FACT_MIMO} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.MIMOAction = 'Deposit'\n"
            f"  AND d.IsInternalTransfer = 0\n"
            f"  AND d.IsRedeem = 0"
        ),
        "syn_value": 29898543.140000,
        "uc_value":  29910573.300000,
        "parity": {"diff_abs": 12030.16, "diff_pct": 0.0402, "threshold_pct": 0.5},
        "uc_fqns": [UC_FACT_MIMO, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-payments"],
        "tags": ["ddr", "mimo", "yesterday", "valid-users-cb", "deposits"],
    },
    {
        "case_id": "ddr_mimo_external_deposits_tp_yesterday",
        "tab": "mimo",
        "sheet": "MIMO: External Deposits to TP",
        "dashboard": "Money Movement",
        "headline_field": "ExternalDepositsTPAmount",
        "nl_question": "What was the total amount in USD of external (non-internal-transfer) deposits to the Trading Platform for valid customers yesterday (2026-06-08)? External deposits are payments made from outside the eToro ecosystem (e.g. card or wire from a customer's bank).",
        "syn_select": "SUM(ExternalDepositsTPAmount)",
        "uc_sql": (
            f"-- UC stores MIMOPlatform = 'TradingPlatform' (NOT 'TP').\n"
            f"SELECT SUM(d.AmountUSD) AS ExternalDepositsTPAmount\n"
            f"FROM {UC_FACT_MIMO} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.MIMOAction = 'Deposit'\n"
            f"  AND d.MIMOPlatform = 'TradingPlatform'\n"
            f"  AND d.IsInternalTransfer = 0\n"
            f"  AND d.IsRedeem = 0"
        ),
        "syn_value": 15471498.400000,
        "uc_value":  15471498.400000,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_MIMO, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-payments"],
        "tags": ["ddr", "mimo", "yesterday", "valid-users-cb", "tp-deposits", "external"],
    },
    {
        "case_id": "ddr_mimo_global_deposits_count_yesterday",
        "tab": "mimo",
        "sheet": "MIMO: Global Deposits & Withdraws",
        "dashboard": "Money Movement",
        "headline_field": "GlobalDepositsCount",
        "nl_question": "How many global deposit transactions did valid customers make yesterday (2026-06-08)? Excludes internal transfers and crypto-redeem reclassifications.",
        "syn_select": "SUM(GlobalDepositsCount)",
        "uc_sql": (
            f"SELECT COUNT(*) AS GlobalDepositsCount\n"
            f"FROM {UC_FACT_MIMO} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.MIMOAction = 'Deposit'\n"
            f"  AND d.IsInternalTransfer = 0\n"
            f"  AND d.IsRedeem = 0"
        ),
        "syn_value": 19754,
        "uc_value":  19769,
        "parity": {"diff_abs": 15.0, "diff_pct": 0.0759, "threshold_pct": 0.5},
        "uc_fqns": [UC_FACT_MIMO, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-payments"],
        "tags": ["ddr", "mimo", "yesterday", "valid-users-cb", "deposit-count"],
    },
    {
        "case_id": "ddr_mimo_global_cashout_users_yesterday",
        "tab": "mimo",
        "sheet": "MIMO: Cashout & Redeem Users Count",
        "dashboard": "Money Movement",
        "headline_field": "GlobalCashedOut",
        "nl_question": "How many distinct valid customers had a successful global cashout (any platform: TP, IBAN, Options, MoneyFarm) yesterday (2026-06-08)? GlobalCashedOut is a 0/1 per-customer flag on the daily-status table.",
        "syn_select": "SUM(GlobalCashedOut)",
        "uc_sql": (
            f"-- customer_daily_status already carries IsCreditReportValidCB so no SCD-2 join needed.\n"
            f"SELECT SUM(d.GlobalCashedOut) AS GlobalCashedOut_users\n"
            f"FROM {UC_DAILY_STATUS} d\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.IsCreditReportValidCB = 1"
        ),
        "syn_value": 7738,
        "uc_value":  7748,
        "parity": {"diff_abs": 10.0, "diff_pct": 0.1292, "threshold_pct": 0.5},
        "uc_fqns": [UC_DAILY_STATUS],
        "extra_skills": ["dwh-domain/domain-payments", "dwh-domain/domain-customer-and-identity"],
        "tags": ["ddr", "mimo", "yesterday", "valid-users-cb", "cashout-users"],
    },
    {
        "case_id": "ddr_mimo_tp_first_funded_yesterday",
        "tab": "mimo",
        "sheet": "MIMO: Trading Platform's Deposits & Withdraws",
        "dashboard": "Money Movement",
        "headline_field": "TPFirstDeposited",
        "nl_question": "How many valid customers made their first-ever Trading-Platform deposit yesterday (2026-06-08)? This is the TP-platform-specific FTD count (not Global FTD).",
        "syn_select": "SUM(TPFirstDeposited)",
        "uc_sql": (
            f"SELECT SUM(d.TPFirstDeposited) AS TPFirstDeposited\n"
            f"FROM {UC_DAILY_STATUS} d\n"
            f"WHERE d.DateID = {ASOF_INT}\n"
            f"  AND d.IsCreditReportValidCB = 1"
        ),
        "syn_value": 867,
        "uc_value":  867,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_DAILY_STATUS],
        "extra_skills": ["dwh-domain/domain-payments", "dwh-domain/domain-customer-and-identity"],
        "tags": ["ddr", "mimo", "yesterday", "valid-users-cb", "ftd"],
    },

    # ----- AUM & PnL -----
    {
        "case_id": "ddr_aum_equity_global_yesterday",
        "tab": "aum_pnl",
        "sheet": "AUM & PnL: Yesterday's KPIs 1",
        "dashboard": "AUM & PnL",
        "headline_field": "EquityGlobal",
        "nl_question": "What was the total Global Equity (sum of customer equity across TP + IBAN + Options + custodied assets) for valid customers as of 2026-06-08?",
        "syn_select": "SUM(EquityGlobal)",
        "uc_sql": (
            f"SELECT SUM(d.EquityGlobal) AS EquityGlobal\n"
            f"FROM {UC_FACT_AUM} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}"
        ),
        "syn_value": 16683323307.896469,
        "uc_value":  16683397467.773949,
        "parity": {"diff_abs": 74159.877480, "diff_pct": 0.0004, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_AUM, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-aum-and-aua"],
        "tags": ["ddr", "aum", "yesterday", "valid-users-cb", "equity-global"],
    },
    {
        "case_id": "ddr_aum_realized_equity_global_yesterday",
        "tab": "aum_pnl",
        "sheet": "AUM & PnL: Yesterday's KPIs 1",
        "dashboard": "AUM & PnL",
        "headline_field": "RealizedEquityGlobal",
        "nl_question": "What was the total Global Realized Equity (excluding mark-to-market unrealized PnL on open positions) for valid customers as of 2026-06-08?",
        "syn_select": "SUM(RealizedEquityGlobal)",
        "uc_sql": (
            f"SELECT SUM(d.RealizedEquityGlobal) AS RealizedEquityGlobal\n"
            f"FROM {UC_FACT_AUM} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}"
        ),
        "syn_value": 17243412845.966469,
        "uc_value":  17243415676.843948,
        "parity": {"diff_abs": 2830.877480, "diff_pct": 0.00002, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_AUM, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-aum-and-aua"],
        "tags": ["ddr", "aum", "yesterday", "valid-users-cb", "realized-equity"],
    },
    {
        "case_id": "ddr_pnl_total_position_pnl_yesterday",
        "tab": "aum_pnl",
        "sheet": "AUM & PnL: PnL KPIs",
        "dashboard": "AUM & PnL",
        "headline_field": "TotalPositionPNL",
        "nl_question": "What was the total mark-to-market unrealized PnL across all valid customers' open positions as of 2026-06-08? Negative means open positions are aggregately under water.",
        "syn_select": "SUM(TotalPositionPNL)",
        "uc_sql": (
            f"-- TotalPositionPNL is on fact_aum (snapshot of MtM at end-of-day).\n"
            f"SELECT SUM(d.TotalPositionPNL) AS TotalPositionPNL\n"
            f"FROM {UC_FACT_AUM} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}"
        ),
        "syn_value": -564406548.550000,
        "uc_value":  -564406548.550000,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_AUM, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-trading"],
        "tags": ["ddr", "pnl", "yesterday", "valid-users-cb", "open-position-pnl"],
    },
    {
        "case_id": "ddr_pnl_daily_total_pnl_yesterday",
        "tab": "aum_pnl",
        "sheet": "AUM & PnL: PnL Chart",
        "dashboard": "AUM & PnL",
        "headline_field": "DailyTotalPnL",
        "nl_question": "What was the total Daily PnL (realized NetProfit + unrealized mark-to-market change) across all valid customers' positions on 2026-06-08?",
        "syn_select": "SUM(DailyTotalPnL)",
        "uc_sql": (
            f"-- fact_pnl is long-form: (DateID, RealCID, InstrumentTypeID, IsSettled, IsCopy).\n"
            f"-- DailyTotalPnL on the canvas = NetProfit + UnrealizedPnLChange across all rows.\n"
            f"SELECT SUM(d.NetProfit + d.UnrealizedPnLChange) AS DailyTotalPnL\n"
            f"FROM {UC_FACT_PNL} d\n"
            f"JOIN {UC_SCD2} snap\n"
            f"    ON snap.RealCID = d.RealCID\n"
            f"   AND snap.IsCreditReportValidCB = 1\n"
            f"   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID\n"
            f"WHERE d.DateID = {ASOF_INT}"
        ),
        "syn_value": 104757898.380000,
        "uc_value":  104757898.380000,
        "parity": {"diff_abs": 0.0, "diff_pct": 0.0, "threshold_pct": 0.05},
        "uc_fqns": [UC_FACT_PNL, UC_SCD2],
        "extra_skills": ["dwh-domain/domain-trading"],
        "tags": ["ddr", "pnl", "yesterday", "valid-users-cb", "daily-total-pnl"],
    },
]


def main() -> int:
    out_dir = os.path.join(REPO_ROOT, "tools", "eval_suite", "cases", "ddr")
    os.makedirs(out_dir, exist_ok=True)

    written = 0
    for case in CASES:
        text = emit(case)
        path = os.path.join(out_dir, f"{case['case_id']}.yaml")
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"  wrote {path}  ({len(text)} bytes)")
        written += 1
    print(f"\nWrote {written} case files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
