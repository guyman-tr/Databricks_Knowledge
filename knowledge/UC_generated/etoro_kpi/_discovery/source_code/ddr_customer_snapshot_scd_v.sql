-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ddr_customer_snapshot_scd_v
-- Captured: 2026-05-19T15:10:24Z
-- ==========================================================================

SELECT
  STRING(fsc.RealCID) AS RealCID,
  fsc.GCID,
  dcu.DemoCID,
  CAST(dcu.ExternalID AS STRING) AS ExternalID,
  dcu.SalesForceAccountID AS SalesforceID,
  fsc.FromDateID,
  fsc.ToDateID,
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
  fsc.PlayerStatusReasonID,
  psr.Name AS PlayerStatusReasonName,
  fsc.PlayerStatusSubReasonID,
  pssr.PlayerStatusSubReasonName,
  mc.MifidCategorizationID,
  mc.Name AS MifidCategorizationName,
  dcu.CitizenshipCountryID,
  dcz.Name AS CitizenshipCountry,
  dcu.AffiliateID,
  fsc.IsValidCustomer,
  fsc.IsDepositor,
  dcu.FirstDepositDate,
  dcu.RegisteredReal
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
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
    LEFT JOIN main.general.bronze_etoro_dictionary_mifidcategorization mc
      ON mc.MifidCategorizationID = fsc.MifidCategorizationID
WHERE
  fsc.IsValidCustomer = 1
