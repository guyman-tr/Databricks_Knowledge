-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_copy_mimo
-- Captured: 2026-06-19T14:30:13Z
-- ==========================================================================

select fca.DateID
	,dd.WeekNumberYear
	,dd.CalendarYearMonth
	,dd.CalendarQuarter
	,dd.CalendarYear
      ,mr.ParentCID
      ,mr.ParentUserName
      ,mr.MirrorTypeID
      ,mr.OpenOccurred
      ,mr.CloseOccurred
      ,dcu.RegisteredReal
      ,dcu.FirstDepositDate
      ,fca.RealCID
      ,fca.MirrorID
      ,fca.PositionID
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
      ,CASE WHEN fca.ActionTypeID = 19 THEN 1 ELSE 0 END as IsDetachMirror 
      ,SUM(Case WHEN fca.ActionTypeID = 15 THEN ABS(fca.Amount) ELSE 0 END) MoneyInMirror 
      ,SUM(Case WHEN fca.ActionTypeID = 16 THEN ABS(fca.Amount) ELSE 0 END) MoneyOutMirror 
      ,SUM(Case WHEN fca.ActionTypeID = 18 THEN ABS(fca.Amount) ELSE 0 END) CloseMirror 
      ,SUM(Case WHEN fca.ActionTypeID = 17 THEN ABS(fca.Amount) ELSE 0 END) NewMirror 
      ,Case when fsc.AccountTypeID = 9 then 'Portfolio'
            when fsc.GuruStatusID > 1 then 'PI'
            else 'Copy' end as MirrorType
from main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca 
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror mr 
on fca.MirrorID = mr.MirrorID
LEFT join main.bi_output.bi_output_vg_date dd 
on fca.DateID = dd.DateID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
on fsc.RealCID = fca.RealCID
and fsc.FromDateID <= fca.DateID
and fsc.ToDateID >= fca.DateID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu 
on fsc.RealCID = dcu.RealCID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl 
on fsc.PlayerLevelID = dpl.PlayerLevelID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm 
on fsc.AccountManagerID = dm.ManagerID 
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
on fsc.RegulationID = dr.ID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
on fsc.CountryID = dc.CountryID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
on fsc.LanguageID = dl.LanguageID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel dv
on fsc.VerificationLevelID = dv.ID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs 
on fsc.GuruStatusID = gs.GuruStatusID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
on fsc.AccountStatusID = ast.AccountStatusID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
on fsc.AccountTypeID = act.AccountTypeID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
on fsc.PlayerStatusID = pst.PlayerStatusID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
on fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
on fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
on fsc.CommunicationLanguageID = dcl.LanguageID
where ActionTypeID in (15,16,17,18,19)
group by all
