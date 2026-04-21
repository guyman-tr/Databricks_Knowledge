-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Revenue_StakingFee
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_revenue_stakingfee
-- Col comments: 20 added, 2 preserved (existing), 0 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_revenue_stakingfee (
  StakingMonthID COMMENT 'left(StakingMonthID,6). Source: Dealing_Staking_Results. (T2 — Function_Revenue_StakingFee)',
  Date COMMENT 'dateadd(MONTH,-1,UpdateDate). Source: Dealing_Staking_Results. (T2 — Function_Revenue_StakingFee)',
  DateID COMMENT 'CAST(FORMAT(CAST(dateadd(MONTH,-1,UpdateDate) AS DATE),''yyyyMMdd'') as INT). Source: Dealing_Staking_Results. (T2 — Function_Revenue_StakingFee)',
  StakingMonth COMMENT 'Direct pass-through from Dealing_Staking_Results.StakingMonth. (T1 — Function_Revenue_StakingFee)',
  StakingYear COMMENT 'Direct pass-through from Dealing_Staking_Results.StakingYear. (T1 — Function_Revenue_StakingFee)',
  InstrumentID COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.',
  Instrument COMMENT 'Direct pass-through from Dim_Instrument.Name. (T1 — Function_Revenue_StakingFee)',
  CID COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.',
  GCID COMMENT 'Direct pass-through from Fact_SnapshotCustomer.GCID. (T1 — Function_Revenue_StakingFee)',
  IsEligible COMMENT 'Direct pass-through from Dealing_Staking_Results.IsEligible. (T1 — Function_Revenue_StakingFee)',
  NonEligible_PrimaryReason COMMENT 'Direct pass-through from Dealing_Staking_Results.NonEligible_PrimaryReason. (T1 — Function_Revenue_StakingFee)',
  IneligibleCustomerRewards COMMENT 'CASE WHEN IsEligible = 0 THEN Etoro_Amount ELSE 0 END WHERE attributed DateID (from dateadd(MONTH,-1,UpdateDate)) BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths (LEN>6 excluded). Source: Dealing_Staking_Results.Etoro_Amount. (T2 — Function_Revenue_StakingFee)',
  RevShareCommission COMMENT 'CASE WHEN IsEligible = 1 THEN Etoro_Amount ELSE 0 END WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths. Source: Dealing_Staking_Results.Etoro_Amount. (T2 — Function_Revenue_StakingFee)',
  ClientPercent COMMENT 'Client_Airdrop / nullif((Client_Airdrop + Etoro_Amount),0) ClientPercent. Source: Dealing_Staking_Results. (T2 — Function_Revenue_StakingFee)',
  EtoroPercent COMMENT 'Etoro_Amount / nullif((Client_Airdrop + Etoro_Amount),0) EtoroPercent. Source: Dealing_Staking_Results. (T2 — Function_Revenue_StakingFee)',
  ClientUSDDistributed COMMENT 'CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths. Source: Dealing_Staking_Results.USD_Compensation. (T2 — Function_Revenue_StakingFee)',
  EtoroUSDDistributed COMMENT 'Etoro_Amount_USD WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths. Source: Dealing_Staking_Results.Etoro_Amount_USD. (T2 — Function_Revenue_StakingFee)',
  TotalUSDDistributed COMMENT 'CASE WHEN IsEligible = 1 THEN USD_Compensation ELSE 0 END + Etoro_Amount_USD WHERE attributed DateID BETWEEN @sdateID AND @edateID AND StakingMonthID not in BadMonths. Source: Dealing_Staking_Results.USD_Compensation, Etoro_Amount_USD. (T2 — Function_Revenue_StakingFee)',
  AirDropDateID COMMENT 'CAST(FORMAT(CAST(AirdropOccurred AS DATE),''yyyyMMdd'') as INT). Source: Dealing_Staking_Results. (T2 — Function_Revenue_StakingFee)',
  ActualCompensationType COMMENT 'Direct pass-through from Dealing_Staking_Results.ActualCompensationType. (T1 — Function_Revenue_StakingFee)',
  ClubCategory COMMENT 'Direct pass-through from Dealing_Staking_Results.ClubCategory. (T1 — Function_Revenue_StakingFee)',
  IsValidCustomer COMMENT 'Direct pass-through from Fact_SnapshotCustomer.IsValidCustomer. (T1 — Function_Revenue_StakingFee)'
)
COMMENT 'BI_DB_dbo.Function_Revenue_StakingFee > Staking reward distribution economics per instrument and customer: rows from Dealing_Staking_Results filtered to attributed DateID (from dateadd(MONTH,-1, UpdateDate)) between @sdateID and @edateID, excluding bad StakingMonthID values (see BadMonths CTE). Normalizes month IDs (left(StakingMonthID,6)), splits eToro vs client USD using eligibility (IsEligible), and joins Dim_Instrument and Fact_SnapshotCustomer with EOM-aligned Dim_Range for customer attributes at month-end.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Revenue_StakingFee > Staking reward distribution economics per instrument and customer: rows from Dealing_Staking_Results filtered to attributed DateID (from dateadd(MONTH,-1, UpdateDate)) between @sdateID and @edateID, excluding bad StakingMonthID values (see BadMonths CTE). Normalizes month IDs (left(StakingMonthID,6)), splits eToro vs client USD using eligibility (IsEligible), and joins Dim_Instrument and Fact_SnapshotCustomer with EOM-aligned Dim_Range for customer attributes at month-end.')
WITH SCHEMA COMPENSATION
AS WITH BadMonths AS (
    SELECT DISTINCT StakingMonthID
    FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
    WHERE LENGTH(CAST(StakingMonthID AS STRING)) > 6
)
SELECT
    LEFT(CAST(dss.StakingMonthID AS STRING), 6) AS StakingMonthID,
    ADD_MONTHS(dss.UpdateDate, -1) AS Date,
    CAST(DATE_FORMAT(CAST(ADD_MONTHS(dss.UpdateDate, -1) AS DATE), 'yyyyMMdd') AS INT) AS DateID,
    dss.StakingMonth,
    dss.StakingYear,
    dss.InstrumentID,
    di.Name AS Instrument,
    dss.CID,
    fsc.GCID,
    dss.IsEligible,
    dss.NonEligible_PrimaryReason,
    CASE WHEN dss.IsEligible = 0 THEN dss.Etoro_Amount ELSE 0 END AS IneligibleCustomerRewards,
    CASE WHEN dss.IsEligible = 1 THEN dss.Etoro_Amount ELSE 0 END AS RevShareCommission,
    dss.Client_Airdrop / NULLIF(dss.Client_Airdrop + dss.Etoro_Amount, 0) AS ClientPercent,
    dss.Etoro_Amount / NULLIF(dss.Client_Airdrop + dss.Etoro_Amount, 0) AS EtoroPercent,
    CASE WHEN dss.IsEligible = 1 THEN dss.USD_Compensation ELSE 0 END AS ClientUSDDistributed,
    dss.Etoro_Amount_USD AS EtoroUSDDistributed,
    CASE WHEN dss.IsEligible = 1 THEN dss.USD_Compensation ELSE 0 END + dss.Etoro_Amount_USD AS TotalUSDDistributed,
    CAST(DATE_FORMAT(CAST(dss.AirdropOccurred AS DATE), 'yyyyMMdd') AS INT) AS AirDropDateID,
    dss.ActualCompensationType,
    dss.ClubCategory,
    fsc.IsValidCustomer
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results dss
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON dss.InstrumentID = di.InstrumentID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON dss.CID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND CAST(DATE_FORMAT(CAST(LAST_DAY(ADD_MONTHS(dss.UpdateDate, -1)) AS DATE), 'yyyyMMdd') AS INT)
        BETWEEN dr.FromDateID AND dr.ToDateID
WHERE CAST(DATE_FORMAT(CAST(ADD_MONTHS(dss.UpdateDate, -1) AS DATE), 'yyyyMMdd') AS INT) > 0
    AND CAST(LEFT(CAST(dss.StakingMonthID AS STRING), 6) AS INT) NOT IN (SELECT CAST(LEFT(CAST(StakingMonthID AS STRING), 6) AS INT) FROM BadMonths)

;
