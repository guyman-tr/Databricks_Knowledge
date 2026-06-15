SELECT dp.CID
, dc.Name AS CountryOfResidence
, cb.Country AS CountryAtTheTimeOfPositionOpen
, dp.PositionID, dp.MirrorID, di.InstrumentID
,di.Name AS Instrument, CONVERT(varchar(50), dp.OpenOccurred, 120) OpenOccurred, dp.OpenDateID
,(CASE WHEN dp.IsBuy = 1 THEN 'TRUE' ELSE 'FALSE' END) IsBuy
,dp.Amount * dp.Leverage AS FullNotionalTradeSize
,dp.Leverage
,ISNULL(round(pnl2.PositionPnL, 2), 0) AS UnrealisedPositionPnL_ReportDate
FROM DWH_dbo.[Dim_Position] dp WITH (NOLOCK)
JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.[Dim_Customer] c WITH (NOLOCK) ON c.RealCID = dp.CID
JOIN DWH_dbo.[Dim_Country] dc ON dc.CountryID = c.CountryID
JOIN DWH_dbo.[Dim_Regulation] dr ON c.DesignatedRegulationID = dr.ID
JOIN [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] pan ON pan.CID = c.RealCID 
AND pan.ActiveDate = (SELECT MAX(ActiveDate) MaxDate FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] WHERE ActiveDate >= '20230801')
AND ISNULL(IsPro, 0) <> 1
LEFT JOIN [BI_DB_dbo].[BI_DB_PositionPnL] pnl2 WITH (NOLOCK) 
ON pnl2.PositionID = dp.PositionID AND pnl2.DateID = cast(convert(varchar(8),dateadd(day,-1, getdate()),112) as int)
LEFT JOIN BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New cb
ON cb.CID = dp.CID
AND cb.DateID = dp.OpenDateID 
WHERE dp.CloseDateID = 0 AND
c.DesignatedRegulationID = 2
AND dp.OpenDateID >= 20240501
AND c.IsValidCustomer = 1 
AND dp.IsSettled = 1 
AND di.InstrumentTypeID = 6 
AND dc.Name IN ('United Kingdom', 'Gibraltar')
AND (LEFT(di.ISINCode, 2) = 'CA' OR LEFT(di.ISINCode, 2) = 'US')