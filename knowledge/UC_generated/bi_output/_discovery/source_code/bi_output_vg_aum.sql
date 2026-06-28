-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_aum
-- Captured: 2026-06-19T14:29:43Z
-- ==========================================================================

SELECT CAST(aum.RealCID AS STRING) AS RealCID
	  ,dd.DateID
    ,dd.Date
	  ,dd.WeekNumberYear
	  ,dd.CalendarYearMonth
	  ,dd.CalendarQuarter
	  ,dd.CalendarYear
	  ,RealizedEquityTP AS RealizedEquityTradingPlatform
	  ,TotalPositionPNL 
	  ,TotalInvestedAmount
	  ,TotalEquityTP AS EquityTradingPlatform
	  ,CashInCopy
	  ,InvestedAmountCopy
        ,EquityCopy
	  ,EquityStocksManual
	  ,InvestedAmountStocksManual
	  ,InvestedAmountCryptoManual
	  ,CreditTP BalanceTradingPlatfrom
	  ,IBANBalance BalanceIBAN
	  ,RealizedEquityGlobal
	  ,EquityGlobal
	  ,CreditGlobal
	  ,OptionsTotalEquity
	  ,dd.IsLastDayWeek
    ,dd.IsLastDayMonth
	  ,dd.IsLastDayQuarter
	  ,dd.IsLastDayYear 
     ,fsc.PlayerLevelID
      ,dpl.Name AS ClubTier
      ,fsc.RegulationID
      ,dr.Name AS Regulation
      ,fsc.VerificationLevelID
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
      ,dcu.CitizenshipCountryID
      ,dcz.Name CitizenshipCountry
      ,dcu.AffiliateID
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum aum 
inner join main.bi_output.bi_output_vg_date dd 
on aum.DateID = dd.DateID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
on fsc.RealCID = aum.RealCID
and fsc.FromDateID <= aum.DateID
and fsc.ToDateID >= aum.DateID
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
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs 
on fsc.GuruStatusID = gs.GuruStatusID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
on fsc.AccountStatusID = ast.AccountStatusID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
on fsc.AccountTypeID = act.AccountTypeID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
on fsc.PlayerStatusID = pst.PlayerStatusID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
on fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
on fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
on fsc.CommunicationLanguageID = dcl.LanguageID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
on dcu.CitizenshipCountryID = dcz.CountryID
where dcu.IsValidCustomer =1
