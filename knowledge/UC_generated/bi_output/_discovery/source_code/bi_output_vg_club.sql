-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_club
-- Captured: 2026-05-19T14:47:24Z
-- ==========================================================================

SELECT
  dd.Date,
  dd.DateID,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  STRING(dc1.RealCID) AS RealCID,
  clb.PLChangeType,
  clb.PLChangeTypeDate,
  clb.IsUpgrade,
  clb.IsDowngrade,
  clb.IsFTC,
  clb.CurrentTier,
  clb.LastTier,
  clb.MaxTier,
  clb.FTDDate,
  clb.FTCDate,
  clb.IsFTC_Status,
  clb.DaysTillFTC,
  clb.DaysFromFTD,
  clb.DaysInClub,
  clb.DaysInCurrentClub,
  clb.AmountForUpgrade,
  clb.IsOptInIOB,
  clb.IOB_Date,
  clb.UpdateDate,
  clb.GCID_Club,
  clb.TotalEquityClub,
  clb.WealthFrance,
  clb.MoneyBalance,
  clb.RealizedEquity,
  clb.MoneyFarmBalance,
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
  concat_ws(dm.FirstName, '', dm.LastName) AS AccountManager,
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
  CASE WHEN fsc.MifidCategorizationID in (2,3) THEN 1 else 0 END AS IsPro,
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
  dcu.CitizenshipCountryID,
  dcz.Name AS CitizenshipCountry,
  dcu.AffiliateID
FROM
  main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity clb
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1
      ON clb.CID = dc1.RealCID
    INNER JOIN main.bi_output.bi_output_vg_date dd
      ON CAST(date_format(clb.Date, 'yyyyMMdd') AS int) = dd.DateID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      ON fsc.RealCID = clb.CID
      AND fsc.FromDateID <= CAST(date_format(clb.Date, 'yyyyMMdd') AS int)
      AND fsc.ToDateID >= CAST(date_format(clb.Date, 'yyyyMMdd') AS int)
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
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs
      ON fsc.GuruStatusID = gs.GuruStatusID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
      ON fsc.AccountStatusID = ast.AccountStatusID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
      ON fsc.AccountTypeID = act.AccountTypeID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
      ON fsc.PlayerStatusID = pst.PlayerStatusID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
      ON fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
      ON fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
      ON fsc.CommunicationLanguageID = dcl.LanguageID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
      ON dcu.CitizenshipCountryID = dcz.CountryID
WHERE
  dc1.IsValidCustomer = 1
  AND dc1.IsCreditReportValidCB = 1
