-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_customer_snapshot
-- Captured: 2026-05-19T14:48:37Z
-- ==========================================================================

SELECT
  STRING(fsc.RealCID) AS RealCID,
  fsc.GCID,
  -- coalesce(ddrc.date, dd.Date) AS Date,
  -- coalesce(ddrc.DateID, dd.DateID) AS DateID,
  dd.Date AS Date,
  dd.DateID AS DateID,
  fsc.PlayerLevelID,
  dpl.Name AS ClubTier,
  fsc.RegulationID,
  dr.Name AS Regulation,
  fsc.VerificationLevelID,
  dv.Name AS VerificationLevel,
  fsc.CountryID,
  dc.Name AS Country,
  dc.MarketingRegionManualName AS Region,
  fsc.AccountManagerID,
  concat(dm.FirstName, ' ', dm.LastName) AS AccountManager,
  fsc.LanguageID,
  dl.Name AS Language,
  fsc.CommunicationLanguageID,
  dcl.Name AS CommunicationLanguage,
  fsc.AccountTypeID,
  act.Name AS AccountType,
  fsc.GuruStatusID,
  gs.GuruStatusName,
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
  -- ActiveTraded,
  -- BalanceOnlyAccount,
  -- Portfolio_Only,
  -- AccountActive,
  -- AccountInActive,
  -- IsFunded,
  dd.WeekNumberYear,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  dd.IsLastDayWeek,
  dd.IsLastDayMonth,
  dd.IsLastDayQuarter,
  dd.IsLastDayYear,
  dcu.CitizenshipCountryID,
  dcz.Name AS CitizenshipCountry,
  dcu.AffiliateID,
  NULL AS ClusterDetail,
  NULL AS ClusterSF,
  NULL AS IsLastCluster,
  NULL AS IsFirstCluster,
  NULL AS IsSFCluster,
  NULL AS UpdateDateIDSF,
  NULL AS ClusterDynamic
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
  INNER JOIN main.bi_output.bi_output_vg_date dd
    ON dd.DateID BETWEEN fsc.FromDateID AND fsc.ToDateID
  -- LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ddrc
  --   ON fsc.RealCID = ddrc.RealCID
  --   AND date_format(ddrc.etr_ymd, 'yyyyMMdd') BETWEEN fsc.fromdateid AND fsc.todateid
  --   AND ddrc.DateID = dd.DateID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu
    ON fsc.RealCID = dcu.RealCID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
    ON fsc.PlayerLevelID = dpl.PlayerLevelID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
    ON fsc.AccountManagerID = dm.ManagerID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
    ON fsc.RegulationID = dr.ID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
    ON fsc.CountryID = dc.CountryID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
    ON fsc.LanguageID = dl.LanguageID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel dv
    ON fsc.VerificationLevelID = dv.ID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs
    ON fsc.GuruStatusID = gs.GuruStatusID
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
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
    ON fsc.CommunicationLanguageID = dcl.LanguageID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
    ON dcu.CitizenshipCountryID = dcz.CountryID
WHERE
  fsc.IsValidCustomer = 1
