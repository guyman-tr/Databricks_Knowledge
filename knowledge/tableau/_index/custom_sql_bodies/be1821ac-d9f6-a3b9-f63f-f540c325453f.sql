SELECT a.*, fsc.IsCreditReportValidCB, fsc.IsValidCustomer
FROM 
(
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'AmountUSD' AS Metric
	 , sum(InvestedAmount	) AS MetricAmount
	 , sum(TicketFeeByPercent) AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument, CommissionVersion
UNION ALL 
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'AmountUSD' AS Metric
	 , sum(InvestedAmount	) AS MetricAmount
	 , sum(TicketFeeByPercent) AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument, CommissionVersion
UNION ALL 
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'Units' AS Metric
	 , sum(Units	) AS MetricAmount
	 , NULL AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument	 , CommissionVersion
UNION ALL 
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'Units' AS Metric
	 , sum(Units	) AS MetricAmount
	 , NULL AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument, CommissionVersion
UNION ALL 
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'AmountBugFix' AS Metric
	 , sum(AmountBugFix	) AS MetricAmount
	 , sum(TicketFeeByPercent) AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument	 , CommissionVersion
UNION ALL 
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'AmountBugFix' AS Metric
	 , sum(AmountBugFix	) AS MetricAmount
	 , sum(TicketFeeByPercent) AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument , CommissionVersion
UNION ALL 
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'AmountDiffFromBugs' AS Metric
	 , sum(AmountBugFix) - sum(InvestedAmount) AS MetricAmount
	 , NULL AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument	 , CommissionVersion
UNION ALL 
SELECT DateID
	 , Date
	 , RealCID
	 , CountryID
	 , IsDLTUser
	 , TanganyStatusID
	 , ActionType
	 , TanganyID
	 , DltID
	 , IsCoinsTransferedOut
	 , Instrument
	 , 'AmountDiffFromBugs' AS Metric
	 , sum(AmountBugFix) - sum(InvestedAmount) AS MetricAmount
	 , NULL AS TicketFeeByPercent
	 , CommissionVersion
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument , CommissionVersion
) a
JOIN 
DWH_dbo.Fact_SnapshotCustomer fsc
	ON a.RealCID = fsc.RealCID 
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND a.DateID BETWEEN FromDateID AND ToDateID