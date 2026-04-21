-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_Funded
-- Generated: 2026-04-12 | apply_tvf_comments.py
-- Target: UC view comment + column comments
-- UC Target: main.etoro_kpi_prep.v_population_funded
-- Source: Synapse TVF BI_DB_dbo.Function_Population_Funded
-- UC cols: 3 total, 3 matched from wiki §4
-- =============================================================================


-- ---- Table Comment ----
ALTER VIEW main.etoro_kpi_prep.v_population_funded SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.Function_Population_Funded > On a single @dateInt, returns customers who are past their first-funded date per Function_Population_First_Time_Funded and have positive combined equity that day from trading-platform balances, eMoney settled balance, or options AUM (valid customers only on options leg). Prevents “funded” without an actual deposit/funded milestone.'
);

-- ---- Table Tags ----
ALTER VIEW main.etoro_kpi_prep.v_population_funded SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'source_object_type' = 'TVF',
    'source_tvf' = 'Function_Population_Funded',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'tvf-comments-2026-04-12'
);

-- ---- Column Descriptions (documented only; ALTER COLUMN not supported on views) ----
-- ALTER VIEW main.etoro_kpi_prep.v_population_funded (col comment not supported on views without DDL recreation)
-- Column `DateID`: All legs = @dateInt; outer GROUP BY DateID, RealCID. Source: BI_DB_Client_Balance_CID_Level_New.DateID, eMoneyClientBalance.BalanceDateID, Function_AUM_OptionsPlatform.DateID. (T2 — Function_Population_Funded)
-- ALTER VIEW main.etoro_kpi_prep.v_population_funded (col comment not supported on views without DDL recreation)
-- Column `RealCID`: CID AS RealCID / direct from options TVF; inner join to Function_Population_First_Time_Funded on RealCID with FirstFundedDateID <= DateID. Source: BI_DB_Client_Balance_CID_Level_New.CID, eMoneyClientBalance.CID, Function_AUM_OptionsPlatform.RealCID. (T2 — Function_Population_Funded)
-- ALTER VIEW main.etoro_kpi_prep.v_population_funded (col comment not supported on views without DDL recreation)
-- Column `Equity`: SUM(Equity) over union: (1) SUM(ISNULL(TotalLiability,0)+ISNULL(actualNWA,0)) per CID WHERE DateID = @dateInt; (2) ClosingBalanceBO * USDApproxRate WHERE BalanceDateID = @dateInt AND ClosingBalanceCalc > 0; (3) OptionsTotalEquity from Function_AUM_OptionsPlatform(@dateInt, 1) WHERE DateID = @dateInt AND OptionsTotalEquity > 0. Kept only if joined first-funded row exists and aggregated Equity > 0. Source: BI_DB_Client_Balance_CID_Level_New, eMoneyClientBalance, Function_AUM_OptionsPlatform. (T...
