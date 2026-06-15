SELECT	bddpc.Date
	   ,bddpc.DateID
	   ,bddpc.CID
	   ,bddpc.UserName
	   ,bddpc.Gender
	   ,bddpc.Manager
	   ,bddpc.Country
	   ,bddpc.Region
	   ,bddpc.Language
	   ,bddpc.Club
	   --,bddpc.Regulation
	   ,bddpc.Seniority
	   ,bddpc.DaysAsPI
	   ,bddpc.CopyType
	   ,bddpc.PortfolioType
	   ,bddpc.GuruStatusID
	   ,bddpc.GuruStatus
	   ,bddpc.PreviousGuruStatus
	   ,bddpc.TotalDaysInCurrentStatus
	   ,bddpc.BIO_Len
	   ,bddpc.IsPrivate
	   ,bddpc.AllowDisplayFullName
	   ,bddpc.HasAvatar
	   ,bddpc.RiskScore
	   ,bddpc.PlayerStatus
	   ,bddpc.LastBlockedDate
	   ,bddpc.BlockReason
	   ,bddpc.TotalEquity
	   ,bddpc.RealizedEquity
	   ,bddpc.TotalPositionsAmount
	   ,bddpc.PositionPnL
	   ,bddpc.Credit
	   ,bddpc.NumOfCopiers
	   ,bddpc.CopyAUC
	   ,bddpc.CopyPnL
	   ,bddpc.MI
	   ,bddpc.MO
	   ,bddpc.NetMI
	   ,bddpc.Trades
	   ,bddpc.Top_3_Traded_Instruments
	   ,bddpc.Top3TradedIndustries
	   ,bddpc.Lev_weighted_average
	   ,bddpc.BuyPercent
	   ,bddpc.SellPercent
	   ,bddpc.HoldsHighLevPosition
	   ,bddpc.Classification
	   ,bddpc.Largest_Asset_Class
	   ,bddpc.AvgerageHoldingTime
	   ,bddpc.TraderType
	   ,bddpc.HighLevHoldingDetail
	   ,bddpc.Value_percenet
	   ,bddpc.UpdateDate
	   ,bddpc.Last_Day_Performance
	   ,bddpc.Gain_YTD
	   ,bddpc.Gain_QTD
	   ,bddpc.Gain_MTD
	   ,dr1.Name AS Regulation
                ,dc.FirstName
		,dc.LastName
		,dc.Email
                ,dc.GCID
	       ,dc.ID
		   ,dc.AccountTypeID 
		   ,dft.FundTypeName
FROM BI_DB_dbo.BI_DB_DailyPanel_Copy bddpc 
--[dbo].[BI_DB_CopyDailyData] as cd with(nolock)
join DWH_dbo.Dim_Customer dc with(nolock)
on dc.RealCID = bddpc.CID
JOIN DWH_dbo.Dim_Regulation dr1 with(nolock)
ON dr1.DWHRegulationID = dc.RegulationID
left join DWH_dbo.Dim_Fund tf
on tf.FundAccountID = dc.RealCID
left join DWH_dbo.Dim_FundType dft
on dft.FundTypeID = tf.FundType
where bddpc.CopyType IN ('PI','Portfolio')
AND bddpc.DateID>=CONVERT(CHAR(8),'20220101',112)