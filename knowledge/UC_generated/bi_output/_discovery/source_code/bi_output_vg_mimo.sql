-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_mimo
-- Captured: 2026-05-19T14:51:07Z
-- ==========================================================================

SELECT dd.DateID
  ,dd.Date
	,dd.WeekNumberYear
	,dd.CalendarYearMonth
	,dd.CalendarQuarter
	,dd.CalendarYear
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
	 , STRING(map.RealCID) AS RealCID
   , MAX(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' THEN map.RealCID END) DepositRealCID
   , MAX(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' THEN map.RealCID END) WithdrawRealCID
   , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' THEN 1 ELSE 0 END) AS GlobalDepositsCount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' THEN 1 ELSE 0 END) AS GlobalWithdrawsCount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' THEN map.AmountUSD ELSE 0 END) AS GlobalDepositsAmount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' THEN map.AmountUSD ELSE 0 END) AS GlobalWithdrawsAmount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' AND map.IsGlobalFTD = 1 THEN map.AmountUSD ELSE 0 END) AS TotalFTDGlobalAmount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' AND map.IsGlobalFTD = 1 THEN 1 ELSE 0 END) AS TotalFTDGlobalCount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' THEN map.AmountUSD ELSE 0 END)
			- sum(CASE WHEN map.MIMOAction = 'Withdraw' AND map.IsRedeem = 1 THEN map.AmountUSD ELSE 0 END) AS GlobalWithdraw_ExclRedeem
	 ,sum(CASE WHEN map.MIMOAction = 'Withdraw' and map.IsRedeem = 1 THEN map.AmountUSD ELSE 0 END) AS TransferCoins
	 , sum(CASE WHEN map.MIMOAction = 'Withdraw' and map.IsRedeem = 1 THEN 1 ELSE 0 END) AS CountRedeems
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'TradingPlatform' THEN map.AmountUSD ELSE 0 END) AS ExternalDepositsTPAmount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' AND map.MIMOPlatform = 'TradingPlatform' THEN map.AmountUSD ELSE 0 END) AS ExternalWithdrawTPAmount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END) AS ExternalDepositsTPCount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' AND map.MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END) AS ExternalWithdrawTPCount	
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'eMoney' THEN map.AmountUSD ELSE 0 END) AS ExternalDepositToIBANAmount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' AND map.MIMOPlatform = 'eMoney' THEN map.AmountUSD ELSE 0 END) AS ExternalWithdrawFromIBANAmount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'eMoney' THEN 1 ELSE 0 END) AS ExternalDepositToIBANCount
	 , sum(CASE WHEN map.IsInternalTransfer = 0 AND map.MIMOAction = 'Withdraw' AND map.MIMOPlatform = 'eMoney' THEN 1 ELSE 0 END) AS ExternalWithdrawFromIBANCount	
    ,dcu.AffiliateID
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms map
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu
on map.RealCID = dcu.RealCID
inner join main.bi_output.bi_output_vg_date dd
on map.DateID = dd.DateID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
on fsc.RealCID = map.RealCID
and fsc.FromDateID <= map.DateID
and fsc.ToDateID >= map.DateID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl 
on fsc.PlayerLevelID = dpl.PlayerLevelID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm 
on fsc.AccountManagerID = dm.ManagerID 
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
on fsc.RegulationID = dr.ID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
on fsc.CountryID = dc.CountryID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
on fsc.LanguageID = dl.LanguageID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel dv
on fsc.VerificationLevelID = dv.ID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs 
on fsc.GuruStatusID = gs.GuruStatusID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
on fsc.AccountStatusID = ast.AccountStatusID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
on fsc.AccountTypeID = act.AccountTypeID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
on fsc.PlayerStatusID = pst.PlayerStatusID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
on fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
on fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
on fsc.CommunicationLanguageID = dcl.LanguageID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
on dcu.CitizenshipCountryID = dcz.CountryID
where dcu.IsValidCustomer = 1
and dcu.IsCreditReportValidCB = 1
AND (map.IsInternalTransfer = 0 OR (map.MIMOAction = 'Withdraw' AND map.IsRedeem = 1))
GROUP BY dd.DateID
  ,dd.Date
	,dd.WeekNumberYear
	,dd.CalendarYearMonth
	,dd.CalendarQuarter
	,dd.CalendarYear
	 ,  STRING(map.RealCID) 
     ,fsc.PlayerLevelID
      ,dpl.Name 
      ,fsc.RegulationID
      ,dr.Name 
      ,fsc.VerificationLevelID
      ,dv.Name 
      ,fsc.CountryID
      ,dc.Name 
      ,dc.MarketingRegionManualName 
      ,fsc.AccountManagerID
      ,concat_ws(dm.FirstName,'',dm.LastName) 
      ,fsc.LanguageID
      ,dl.Name
      ,fsc.CommunicationLanguageID
      ,dcl.Name
      ,fsc.AccountTypeID
      ,act.Name 
      ,fsc.GuruStatusID
      ,gs.GuruStatusName 
      ,CASE WHEN fsc.GuruStatusID > 1 THEN 1 else 0 END  
      ,fsc.AccountStatusID
      ,ast.AccountStatusName
      ,fsc.PlayerStatusID
      ,pst.Name 
      ,pst.CanOpenPosition
      ,pst.CanClosePosition
      ,pst.CanEditPosition
      ,pst.CanBeCopied
      ,pst.CanDeposit
      ,pst.CanRequestWithdraw
      ,fsc.PlayerStatusReasonID
      ,psr.Name 
      ,fsc.PlayerStatusSubReasonID
      ,pssr.PlayerStatusSubReasonName
      ,dcu.CitizenshipCountryID
      ,dcz.Name 
      ,dcu.AffiliateID
