-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_parentcid
-- Captured: 2026-05-19T14:51:15Z
-- ==========================================================================

select dd.DateID
,dd.Date
,dd.WeekNumberYear
,dd.CalendarYearMonth
,dd.CalendarQuarter
,dd.CalendarYear
,dd.IsLastDayWeek
,dd.IsLastDayMonth
,dd.IsLastDayQuarter
,dd.IsLastDayYear 
,cp.CID AS RealCID
,cp.UserName
,cp.Gender
,cp.Manager
,cp.Country
,cp.Region
,cp.Language
,cp.Club
,cp.Regulation
,dcu.RegisteredReal
,dcu.FirstDepositDate
,cp.Seniority
,cp.DaysAsPI
,cp.CopyType
,cp.PortfolioType
,cp.GuruStatusID
,cp.GuruStatus
,cp.PreviousGuruStatus
,cp.TotalDaysInCurrentStatus
,cp.BIO_Len
,cp.IsPrivate
,cp.AllowDisplayFullName
,cp.HasAvatar
,cp.RiskScore
,cp.PlayerStatus
,cp.LastBlockedDate
,cp.BlockReason
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
,cp.TotalEquity
,cp.RealizedEquity
,cp.TotalPositionsAmount
,cp.PositionPnL
,cp.Credit
,cp.NumOfCopiers
,cp.CopyAUC
,cp.CopyPnL
,cp.MI
,cp.MO
,cp.NetMI
,cp.Trades
,cp.Top_3_Traded_Instruments
,cp.Top3TradedIndustries
,cp.Lev_weighted_average
,cp.BuyPercent
,cp.SellPercent
,cp.HoldsHighLevPosition
,cp.Classification
,cp.Largest_Asset_Class
,cp.AvgerageHoldingTime
,cp.TraderType
,cp.HighLevHoldingDetail
,cp.Value_percenet
,cp.Last_Day_Performance
,cp.Gain_YTD
,cp.Gain_QTD
,cp.Gain_MTD
,cp.MonthsSinceFirstOpen
from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy cp
LEFT join bi_output.bi_output_vg_date dd 
on cp.DateID = dd.DateID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu 
on cp.CID = dcu.RealCID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
on fsc.RealCID = cp.CID
and fsc.FromDateID <= cp.DateID
and fsc.ToDateID >= cp.DateID
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
