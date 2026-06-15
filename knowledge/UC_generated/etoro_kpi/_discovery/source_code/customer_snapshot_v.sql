-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.customer_snapshot_v
-- Captured: 2026-05-19T15:06:48Z
-- ==========================================================================

select
  STRING(fsc.RealCID) AS RealCID,
  fsc.GCID,
  dcu.DemoCID,
  CAST(dcu.ExternalID AS STRING) AS ExternalID,
  dcu.SalesForceAccountID AS SalesforceID,
  dd.Date as Date,
  dd.DateID as DateID,
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
    else 0
  END AS IsPI,
  fsc.AccountStatusID,
  ast.AccountStatusName,
  fsc.PlayerStatusID,
  pst.Name as PlayerStatusName,
  fsc.PlayerStatusReasonID,
  psr.Name AS PlayerStatusReasonName,
  fsc.PlayerStatusSubReasonID,
  pssr.PlayerStatusSubReasonName,
  mc.MifidCategorizationID,
  mc.Name AS MifidCategorizationName,
  dd.WeekNumberYear,
  dd.CalendarYearMonth,
  dd.CalendarQuarter,
  dd.CalendarYear,
  dd.IsLastDayWeek,
  dd.IsLastDayMonth,
  dd.IsLastDayQuarter,
  dd.IsLastDayYear,
  dcu.CitizenshipCountryID,
  dcz.Name CitizenshipCountry,
  dcu.AffiliateID,
  fsc.IsValidCustomer,
  fsc.IsDepositor,
  dcu.FirstDepositDate,
  dcu.RegisteredReal
from
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    inner join main.bi_output.bi_output_vg_date dd
      on dd.DateID between fsc.FromDateID and fsc.ToDateID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu
      on fsc.RealCID = dcu.RealCID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
      on fsc.PlayerLevelID = dpl.PlayerLevelID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
      on fsc.AccountManagerID = dm.ManagerID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
      on fsc.RegulationID = dr.ID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
      on fsc.CountryID = dc.CountryID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
      on fsc.LanguageID = dl.LanguageID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel dv
      on fsc.VerificationLevelID = dv.ID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs
      on fsc.GuruStatusID = gs.GuruStatusID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
      on fsc.AccountStatusID = ast.AccountStatusID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
      on fsc.AccountTypeID = act.AccountTypeID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
      on fsc.PlayerStatusID = pst.PlayerStatusID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
      on fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
      on fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
      on fsc.CommunicationLanguageID = dcl.LanguageID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
      on dcu.CitizenshipCountryID = dcz.CountryID
    left join main.general.bronze_etoro_dictionary_mifidcategorization mc
      on mc.MifidCategorizationID = fsc.MifidCategorizationID
where
  fsc.IsValidCustomer = 1
