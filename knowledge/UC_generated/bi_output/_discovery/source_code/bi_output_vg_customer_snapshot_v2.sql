-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_customer_snapshot_v2
-- Captured: 2026-06-19T14:30:40Z
-- ==========================================================================

select  
  STRING(fsc.RealCID) AS RealCID,
  fsc.GCID,
  coalesce(ddrc.date, dd.Date) as Date,
  coalesce(ddrc.DateID, dd.DateID) as DateID ,
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
  ActiveTraded,
  BalanceOnlyAccount,
  Portfolio_Only,
  AccountActive,
  AccountInActive,
  IsFunded,
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
  cdl.ClusterDynamic
from
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
  inner join main.bi_output.bi_output_vg_date dd
      on dd.DateID between fsc.FromDateID and fsc.ToDateID
    left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status ddrc
      on fsc.RealCID = ddrc.RealCID
        and ddrc.etr_ymd between to_date(CAST(fsc.fromdateid AS STRING), 'yyyyMMdd') and to_date(CAST(fsc.todateid AS STRING), 'yyyyMMdd')
    left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status ddps
     on fsc.RealCID = ddps.RealCID
        and ddps.etr_ymd between to_date(CAST(fsc.fromdateid AS STRING), 'yyyyMMdd') and to_date(CAST(fsc.todateid AS STRING), 'yyyyMMdd')
 --       and ddf.FullDate <= ddrc.etr_ymd
 --       and ddt.FullDate >= ddrc.etr_ymd
        and ddrc.DateID = dd.DateID
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
      on fsc.RealCID = cdl.RealCID and cdl.DateID = ddrc.DateID
      where fsc.IsValidCustomer = 1
