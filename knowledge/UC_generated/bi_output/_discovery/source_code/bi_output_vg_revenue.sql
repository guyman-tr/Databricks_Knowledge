-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_revenue
-- Captured: 2026-06-19T14:31:25Z
-- ==========================================================================

SELECT dd.Date
     , dd.DateID
	   , dd.CalendarYearMonth 
	   , dd.CalendarQuarter
	   , dd.CalendarYear
     , STRING(rga.RealCID) AS RealCID
     , rga.InstrumentTypeID
     , ins.InstrumentType
     , rga.IsSettled
     , rga.IsCopy
     , rga.Metric
     , rga.CountAsActiveTrade
		 , rmtr.IncludedInTotalRevenue
		 , rmtr.RevenueMetricCategory
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
		 , SUM(rga.Amount) Amount
      ,dcu.AffiliateID
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions rga
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked  dc1
on rga.RealCID = dc1.RealCID
inner join main.bi_output.bi_output_vg_date dd
on rga.DateID = dd.DateID
LEFT JOIN main.bi_output.bi_ouput_v_dim_Instrumenttype ins
  ON rga.InstrumentTypeID = ins.InstrumentTypeID
left join main.bi_output.bi_output_customer_ddr_revenue_metrics rmtr
on rga.Metric = rmtr.Metric
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
on fsc.RealCID = rga.RealCID
and fsc.FromDateID <= rga.DateID
and fsc.ToDateID >= rga.DateID
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
where dc1.IsValidCustomer = 1
and dc1.IsCreditReportValidCB = 1
GROUP BY dd.Date
     , dd.DateID
	   , dd.CalendarYearMonth 
	   , dd.CalendarQuarter
	   , dd.CalendarYear
     , STRING(rga.RealCID)
     , rga.InstrumentTypeID
     , ins.InstrumentType
     , rga.IsSettled
     , rga.IsCopy
     , rga.Metric
     , rga.CountAsActiveTrade
		 , rmtr.IncludedInTotalRevenue
		 , rmtr.RevenueMetricCategory
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
