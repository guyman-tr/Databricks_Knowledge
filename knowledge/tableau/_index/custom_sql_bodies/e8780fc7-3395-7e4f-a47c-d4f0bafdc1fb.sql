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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument
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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument
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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument
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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument
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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument
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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument
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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Open'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument
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
FROM BI_DB_dbo.BI_DB_DLT_Tangany_Trades_Netting
WHERE DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT) 
AND ActionType = 'Close'
GROUP BY DateID, Date, RealCID, CountryID, IsDLTUser, TanganyStatusID, ActionType, TanganyID, DltID, IsCoinsTransferedOut, Instrument