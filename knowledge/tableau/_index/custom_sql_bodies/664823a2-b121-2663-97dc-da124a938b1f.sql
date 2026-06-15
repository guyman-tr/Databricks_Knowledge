SELECT dp.InstrumentID
		,dp2.PositionID as [OriginalPositionID]
		,dc2.UserName as [TreeOwnerUserName]
		,dc2.RealCID as [TreeOwnerCID]
		,dc3.Name as [TreeOwnerCountry]
		,dc.UserName as ChildUserName
		,di.InstrumentDisplayName
		,di.InstrumentTypeID
		,di.InstrumentType
       ,dc1.Name AS [ChildCountry]
	   ,dp.InitForexRate
	   ,dp.CID as ChildCID
       ,dp.AmountInUnitsDecimal
	   ,dp.IsBuy
	   ,dp.ClosePositionReasonID
	   ,dp.OpenOccurred
	   ,dp.CloseOccurred
	   ,dp.OpenDateID AS Date
	   ,dp.OpenDateID 
	   ,dp.CloseDateID
	   ,dp.PositionID
	   ,dp.Leverage
	   ,dp.Volume AS Volume
       ,dp.VolumeOnClose AS VolumeOnClose
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di
ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Customer dc
ON dp.CID=dc.RealCID
JOIN DWH_dbo.Dim_Country dc1
ON dc.CountryID = dc1.CountryID
left join DWH_dbo.Dim_Position dp2 on dp.TreeID = dp2.PositionID
join DWH_dbo.Dim_Customer dc2 on dp2.CID = dc2.RealCID
join DWH_dbo.Dim_Country dc3 on dc2.CountryID = dc3.CountryID
WHERE di.InstrumentTypeID IN (4,2)
AND dp.OpenOccurred <= GETDATE() AND dp.OpenOccurred > DATEADD(DAY,-7,GETDATE())
AND ISNULL(dp.IsPartialCloseChild, 0) = 0
AND dc.IsValidCustomer = 1
AND DATEDIFF(MINUTE, dp.OpenOccurred, dp.CloseOccurred) <= 10
AND dp.CloseDateID > 0
AND dp.ClosePositionReasonID =1