-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_revenue_stakingfee
-- Captured: 2026-05-19T12:23:44Z
-- ==========================================================================

WITH BadMonths AS (
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
