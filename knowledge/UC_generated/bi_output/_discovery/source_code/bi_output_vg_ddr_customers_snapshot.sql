-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_ddr_customers_snapshot
-- Captured: 2026-06-19T14:31:02Z
-- ==========================================================================

select  
  STRING(ddrc.RealCID) AS RealCID,
  fsc.GCID,
  ddrc.date as Date,
  ddrc.DateID as DateID,
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
  cdl.ClusterDetail,
  cdl.ClusterSF,
  cdl.IsLastCluster,
  cdl.IsFirstCluster,
  cdl.IsSFCluster,
  cdl.UpdateDateIDSF,
  cdl.ClusterDynamic,
  ddrc.ActiveTraded,
  ddrc.BalanceOnlyAccount,
  ddrc.Portfolio_Only,
  ddrc.AccountActive,
  ddrc.AccountInActive,
  ddrc.IsFunded,
  ddps.ActiveTraded_ThisWeek,
  ddps.ActiveTraded_ThisMonth,
  ddps.ActiveTraded_ThisQuarter,
  ddps.ActiveTraded_ThisYear,
  ddps.BalanceOnlyAccount_ThisWeek,
  ddps.BalanceOnlyAccount_ThisMonth,
  ddps.BalanceOnlyAccount_ThisQuarter,
  ddps.BalanceOnlyAccount_ThisYear,
  ddps.Portfolio_Only_ThisWeek,
  ddps.Portfolio_Only_ThisMonth,
  ddps.Portfolio_Only_ThisQuarter,
  ddps.Portfolio_Only_ThisYear,
	ddps.IsFunded_ThisWeek,
	ddps.IsFunded_ThisMonth,
	ddps.IsFunded_ThisQuarter,
	ddps.IsFunded_ThisYear,
   ddps.RegulationID_ThisWeek,
   ddps.RegulationID_ThisMonth,
   ddps.RegulationID_ThisQuarter,
   ddps.RegulationID_ThisYear,
   ddps.CountryID_ThisWeek,
   ddps.CountryID_ThisMonth,
   ddps.CountryID_ThisQuarter,
   ddps.CountryID_ThisYear,
   ddps.IsCreditReportValidCB_ThisWeek,
   ddps.IsCreditReportValidCB_ThisMonth,
   ddps.IsCreditReportValidCB_ThisQuarter,
   ddps.IsCreditReportValidCB_ThisYear,
   ddps.IsValidCustomer_ThisWeek,
   ddps.IsValidCustomer_ThisMonth,
   ddps.IsValidCustomer_ThisQuarter,
   ddps.IsValidCustomer_ThisYear,
   ddps.MarketingRegion_ThisWeek,
   ddps.MarketingRegion_ThisMonth,
   ddps.MarketingRegion_ThisQuarter,
   ddps.MarketingRegion_ThisYear,
   ddps.PlayerLevelID_ThisWeek AS ClubTier_ThisWeek,
   ddps.PlayerLevelID_ThisMonth AS ClubTier_ThisMonth,
   ddps.PlayerLevelID_ThisQuarter AS ClubTier_ThisQuarter,
   ddps.PlayerLevelID_ThisYear AS ClubTier_ThisYear
from  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ddrc
     join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ddps
      on ddrc.RealCID = ddps.RealCID and ddrc.DateID = ddps.DateID and ddrc.etr_ymd = ddps.etr_ymd 
    inner join main.bi_output.bi_output_vg_date dd
      on dd.DateID = ddrc.DateID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
      on ddrc.DateID between fsc.FromDateID and fsc.ToDateID and ddrc.RealCID = fsc.RealCID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu
      on ddrc.RealCID = dcu.RealCID
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
 --   inner join main.bi_output.bi_output_vg_date dd -- select min(DateID) from main.bi_output.bi_output_vg_date
  --    on dd.DateID = ddrc.DateID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
      on dcu.CitizenshipCountryID = dcz.CountryID
    left join
      (
          select dd.DateKey as DateID,
              dcl.CID AS RealCID
            , dcl.ClusterDetail
            , dcl.ClusterSF
            , dcl.IsLastCluster
            , dcl.IsFirstCluster
            , dcl.IsSFCluster
            , dcl.UpdateDateIDSF
            , dcl.ClusterDynamic  
          from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster dcl
          join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd
            on dd.DateKey between dcl.FromDateID and dcl.ToDateID
              and dd.FullDate <= to_date(getdate())
          -- where CID = 12658182
      ) cdl
      on ddrc.RealCID = cdl.RealCID and cdl.DateID = ddrc.DateID
