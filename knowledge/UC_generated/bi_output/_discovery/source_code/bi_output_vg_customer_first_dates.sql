-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_customer_first_dates
-- Captured: 2026-06-19T14:30:26Z
-- ==========================================================================

with daily_status_first
as
(
  SELECT cds.RealCID
      ,Global_FTD_Date 
      ,Global_FTDA
      ,IBAN_FTD_Date
      ,IBAN_FTDA
      ,TP_FTD_Date
      ,TP_FTDA
      ,Options_FTD_Date
      ,Options_FTDA
      ,FirstActionType
	,dd1.FullDate AS FirstActionDate
      ,cds.FirstIOBTime
      ,cds.FirstTimeFunded 
	,dd.FullDate AS FirstFundedDate
      ,ActiveTraded
      ,BalanceOnlyAccount
      ,Portfolio_Only
      ,AccountActive
      ,AccountInActive
      ,IsFunded
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status cds
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd 
ON cds.FirstFundedDateID = dd.DateKey
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date dd1
on cds.FirstActionDateID = dd1.DateKey
where DateID = (SELECT MAX(DateID) DateID FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status)
),
first_club 
as
(SELECT ccl.CID
        ,ccl.Date
	  ,ccl.CurrentClub
FROM main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct ccl
WHERE ccl.IsFTC = 1
)
select fsc.RealCID
      ,fsc.GCID
      ,to_date(fsc.RegisteredReal) RegistrationDate
      ,cdf.VerificationLevel1Date
      ,cdf.VerificationLevel2Date
      ,cdf.VerificationLevel3Date
      ,cdf.EmailVerifiedDate
      ,fsc.VerificationLevelID
      ,cdf.Channel
      ,cdf.SubChannel
      ,dsf.Global_FTD_Date
      ,dsf.Global_FTDA
      ,dsf.IBAN_FTD_Date
      ,dsf.IBAN_FTDA
      ,dsf.TP_FTD_Date
      ,dsf.TP_FTDA
      ,dsf.Options_FTD_Date
      ,dsf.Options_FTDA
      ,dsf.FirstActionType
      ,dsf.FirstActionDate
      ,dsf.FirstIOBTime
      ,dsf.FirstTimeFunded
      ,dsf.FirstFundedDate
      ,dsf.IsFunded
      ,fc.currentclub FirstClub
      ,fc.date FirstTimeClubDate
      ,fsc.PlayerLevelID
      ,dpl.Name AS ClubTier
      ,fsc.RegulationID
      ,dr.Name AS Regulation
      ,dv.Name AS VerificationLevel
      ,fsc.CountryID
      ,dc.Name AS Country
      ,dc.MarketingRegionManualName AS Region
      ,fsc.AccountManagerID
      ,concat_ws(dm.FirstName,'',dm.LastName) AS AccountManager
      ,fsc.LanguageID
      ,dl.Name AS Language
      ,fsc.CommunicationLanguageID
      ,dcl.Name AS CommunicationLanguage
      ,fsc.AccountTypeID
      ,act.Name AS AccountType
      ,fsc.GuruStatusID
      ,gs.GuruStatusName 
      ,CASE WHEN fsc.GuruStatusID > 1 THEN 1 else 0 END AS IsPI 
      ,fsc.AccountStatusID
      ,ast.AccountStatusName
      ,fsc.PlayerStatusID
      ,pst.Name as PlayerStatusName
      ,pst.CanOpenPosition
      ,pst.CanClosePosition
      ,pst.CanEditPosition
      ,pst.CanBeCopied
      ,pst.CanDeposit
      ,pst.CanRequestWithdraw
      ,fsc.PlayerStatusReasonID
      ,psr.Name AS PlayerStatusReasonName
      ,fsc.PlayerStatusSubReasonID
      ,pssr.PlayerStatusSubReasonName
      ,dsf.ActiveTraded
      ,dsf.BalanceOnlyAccount
      ,dsf.Portfolio_Only
      ,dsf.AccountActive
      ,dsf.AccountInActive
      ,fsc.CitizenshipCountryID
      ,dcz.Name CitizenshipCountry
      ,fsc.AffiliateID
from  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked fsc
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl 
on fsc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm 
on fsc.AccountManagerID = dm.ManagerID 
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
on fsc.RegulationID = dr.ID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
on fsc.CountryID = dc.CountryID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
on fsc.LanguageID = dl.LanguageID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel dv
on fsc.VerificationLevelID = dv.ID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs 
on fsc.GuruStatusID = gs.GuruStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
on fsc.AccountStatusID = ast.AccountStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
on fsc.AccountTypeID = act.AccountTypeID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
on fsc.PlayerStatusID = pst.PlayerStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
on fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
on fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
on fsc.CommunicationLanguageID = dcl.LanguageID 
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cdf 
on fsc.RealCID = cdf.CID
left join daily_status_first dsf
on fsc.RealCID = dsf.RealCID
left join first_club fc 
on fsc.RealCID = fc.CID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
on fsc.CitizenshipCountryID = dcz.CountryID
where fsc.IsValidCustomer = 1
and fsc.IsCreditReportValidCB = 1
