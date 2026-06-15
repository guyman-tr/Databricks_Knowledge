SELECT 
	'Buy' AS [B/S code]
	, CAST(OpenOccurred AS DATE) AS TradeDate
	, di.[InstrumentType]
	, di.[Name] AS Instrument
	, di.[InstrumentDisplayName]
	, COUNT(DISTINCT [dp].[PositionID]) PositionsCount
	, SUM(dp.Amount) VolumeInDollar
  FROM DWH_dbo.[Dim_Position] dp WITH (NOLOCK)
  JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
  JOIN DWH_dbo.Dim_Customer dc ON dp.CID = dc.RealCID AND dc.[IsValidCustomer] = 1 
	AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) AND dc.CountryID=219
  WHERE dp.RegulationIDOnOpen IN (7,8)
  --AND [dp].[OpenDateID] >= 20230101
  AND OpenOccurred >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE) )
  AND dp.IsAirDrop IS NULL 
  GROUP BY CAST(OpenOccurred AS DATE), di.[InstrumentType], di.[Name], di.[InstrumentDisplayName]
  --ORDER BY CAST(OpenOccurred AS DATE) 

UNION ALL 

SELECT 
	'Sell' AS [B/S code]
	, CAST(CloseOccurred AS DATE) AS TradeDate
	, di.[InstrumentType]
	, di.[Name] AS Instrument
	, di.[InstrumentDisplayName]
	, COUNT(DISTINCT [dp].[PositionID]) PositionsCount
	, SUM(dp.Amount) VolumeInDollar
  FROM DWH_dbo.[Dim_Position] dp WITH (NOLOCK)
  JOIN DWH_dbo.[Dim_Instrument] di ON dp.InstrumentID = di.InstrumentID
  JOIN DWH_dbo.Dim_Customer dc ON dp.CID = dc.RealCID AND dc.[IsValidCustomer] = 1 
	AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8) AND dc.CountryID=219
  WHERE dp.RegulationIDOnOpen IN (7,8)
  --AND [dp].[OpenDateID] >= 20230101
  AND dp.CloseOccurred >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE) )
    AND dp.IsAirDrop IS NULL 
  GROUP BY CAST(CloseOccurred AS DATE) , di.[InstrumentType], di.[Name], di.[InstrumentDisplayName]
  --ORDER BY CAST(OpenOccurred AS DATE)