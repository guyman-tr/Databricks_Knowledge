SELECT 
	DD.FullDate,
	DCO.Region,
	DCO.Name as Country,
	DI.Name Instrument,
	DI.InstrumentType,
	DI.InstrumentDisplayName,
	DI.Industry,
	dr.Name AS Regulation,
    DI.Exchange,
	Case When IsBuy = 1 then 1 else 0 End As [Buy/Sell Direction (Long = 1, Short = 0)],
        DP.CID,
	DC.Gender,
	DC.RegisteredReal,
	DateDiff(Year,DC.BirthDate,GetDate()) As Age,
	Case When DC.GuruStatusID = 2 then 'Cadet'
	     When DC.GuruStatusID = 3 then 'Rising Start'
		 When DC.GuruStatusID = 4 then 'Champion'
		 When DC.GuruStatusID = 5 then 'Elite' else 'Not PI' End As [PI Status],
	Case When MirrorID > 0 then 'Copy' else 'Manual' End As [Manual/Copy],
	Amount Amount,
	Volume As Volume,
	NetProfit,
        Case When DP.CloseDateID = 0 then 1 else 0 End As OpenTrade
FROM DWH_dbo.[Dim_Position] DP 
JOIN DWH_dbo.[Dim_Customer] DC 
ON DP.CID = DC.RealCID 
JOIN DWH_dbo.[Dim_Instrument] DI 
ON DP.InstrumentID = DI.InstrumentID
JOIN DWH_dbo.[Dim_Date] DD 
ON DP.OpenDateID = DD.DateKey
JOIN DWH_dbo.[Dim_Country] DCO 
ON DC.CountryID = DCO.CountryID
JOIN DWH_dbo.Dim_Regulation dr ON DC.RegulationID=dr.ID
WHERE [OpenDateID] >= cast(CONVERT (VARCHAR(8) , DATEADD(YY, -2 , cast(GETDATE()as date)), 112 ) AS INT) 
and DC.PlayerLevelID <> 4 and Region <> 'eToro'