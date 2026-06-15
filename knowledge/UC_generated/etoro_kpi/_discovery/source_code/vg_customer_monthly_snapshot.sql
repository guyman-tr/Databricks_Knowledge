-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.vg_customer_monthly_snapshot
-- Captured: 2026-05-19T15:19:21Z
-- ==========================================================================

SELECT
    dd.DateKey AS DateID,
    trunc(dd.FullDate, 'MM') AS MonthStartDate,
    dd.FullDate AS MonthEndDate,
    dd.MonthNumberOfYear,
    dd.ISOYearAndWeekNumber,
    dd.DayNumberOfWeek_Sun_Start,
    dd.MonthName,
    dd.MonthNameAbbreviation,
    dd.DayName,
    dd.DayNameAbbreviation,
    dd.CalendarYear,
    dd.CalendarYearMonth,
    dd.CalendarYearQtr,
    dd.IsLastDayOfMonth,
    dd.IsWeekday,
    dd.IsWeekend,
    dps.RealCID,
    dps.IsFunded_ThisMonth,
    dps.ActiveTraded_ThisMonth,
    dps.Portfolio_Only_ThisMonth,
    dps.BalanceOnlyAccount_ThisMonth,
    dps.GlobalDeposited_ThisMonth,
    dps.GlobalRedeposited_ThisMonth,
    dps.GlobalCashedOut_ThisMonth,
    dps.Redeemed_ThisMonth,
    fsc.RegulationID,
    fsc.PlayerLevelID,
    fsc.CountryID,
    fsc.MifidCategorizationID,
    fsc.IsValidCustomer,
    fsc.IsCreditReportValidCB,
    dc.MarketingRegionManualName AS Region,
    dr1.Name AS Regulation,
    dc.Name AS Country,
    dpl.Name AS ClubTier,
    dmc.Name AS MifidCategory,
    CASE 
        WHEN dmc.MifidCategorizationID IN (2,3) THEN 'Professional' 
        ELSE 'Retail' 
    END AS MifidType,
    /*
    cdl.ClusterDetail,
    cdl.ClusterSF,
    cdl.IsLastCluster,
    cdl.IsFirstCluster,
    cdl.IsSFCluster,
    cdl.UpdateDateIDSF,
    cdl.ClusterDynamic,
    */
    dc2.Name AS CitizenshipCountry,
    fsc.GuruStatusID,
    dgs.GuruStatusName,
    CASE
        WHEN fsc.GuruStatusID > 1 THEN 1
        ELSE 0
    END AS IsPI,
    fsc.AccountStatusID,
    ast.AccountStatusName,
    fsc.PlayerStatusID,
    pst.Name AS PlayerStatusName,
    pst.CanOpenPosition,
    pst.CanClosePosition,
    pst.CanEditPosition,
    pst.CanBeCopied,
    pst.CanDeposit,
    pst.CanRequestWithdraw,
    fsc.PlayerStatusReasonID,
    psr.Name AS PlayerStatusReasonName,
    fsc.PlayerStatusSubReasonID,
    pssr.PlayerStatusSubReasonName,
    fsc.AccountManagerID,
    concat(dm.FirstName, ' ', dm.LastName) AS AccountManager,
    fsc.LanguageID,
    dl.Name AS Language,
    fsc.CommunicationLanguageID,
    dcl.Name AS CommunicationLanguage,
    fsc.AccountTypeID,
    act.Name AS AccountType
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd
JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status dps
    ON dd.DateKey = dps.DateID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON dps.RealCID = fsc.RealCID 
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID 
    AND dd.DateKey BETWEEN dr.FromDateID AND dr.ToDateID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
    ON fsc.CountryID = dc.CountryID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
    ON fsc.PlayerLevelID = dpl.PlayerLevelID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization dmc
    ON fsc.MifidCategorizationID = dmc.MifidCategorizationID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1
    ON fsc.RegulationID = dr1.DWHRegulationID
/*
LEFT JOIN (
    SELECT
      dd1.DateKey AS DateID,
      dcl.CID AS RealCID,
      dcl.ClusterDetail,
      dcl.ClusterSF,
      dcl.IsLastCluster,
      dcl.IsFirstCluster,
      dcl.IsSFCluster,
      dcl.UpdateDateIDSF,
      dcl.ClusterDynamic
    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster dcl
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd1
      ON dd1.DateKey BETWEEN dcl.FromDateID AND dcl.ToDateID
) cdl
    ON fsc.RealCID = cdl.RealCID
    AND cdl.DateID = dps.DateID
*/
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1
    ON fsc.RealCID = dc1.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc2
    ON dc1.CitizenshipCountryID = dc2.CountryID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus dgs
    ON fsc.GuruStatusID = dgs.GuruStatusID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
    ON fsc.AccountStatusID = ast.AccountStatusID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
    ON fsc.AccountTypeID = act.AccountTypeID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
    ON fsc.PlayerStatusID = pst.PlayerStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
    ON fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
    ON fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
    ON fsc.LanguageID = dl.LanguageID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
    ON fsc.CommunicationLanguageID = dcl.LanguageID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
    ON fsc.AccountManagerID = dm.ManagerID
WHERE dd.IsLastDayOfMonth = 'Y'
AND fsc.IsValidCustomer = 1
