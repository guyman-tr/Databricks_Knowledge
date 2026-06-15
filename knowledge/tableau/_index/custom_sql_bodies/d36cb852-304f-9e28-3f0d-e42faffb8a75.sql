SELECT td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
	  --,OpenedPositions
	  --,SUM(UsersOpen) UsersOpen
	  --,OpenPositions
	  ,SUM(UsersHold) UsersHold
	  ,CASE WHEN SUM(UsersHold) >=10000 THEN 'Populat Assets'
	  WHEN SUM(UsersHold) >=1000 THEN 'Tail'
	  ELSE 'Long Tail' END AssetPopularity
FROM BI_DB.dbo.BI_DB_Daily_TradeData td WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)
ON td.InstrumentID = di.InstrumentID
WHERE DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)
AND di.VisibleInternallyOnly = 0 AND di.Tradable = 1
AND di.InstrumentTypeID = 5
GROUP BY td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
union
SELECT td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
	  --,OpenedPositions
	  --,SUM(UsersOpen) UsersOpen
	  --,OpenPositions
	  ,SUM(UsersHold) UsersHold
	  ,CASE WHEN SUM(UsersHold) >=10000 THEN 'Populat Assets'
	  WHEN SUM(UsersHold) >=1000 THEN 'Tail'
	  ELSE 'Long Tail' END AssetPopularity
FROM BI_DB.dbo.BI_DB_Daily_TradeData td WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)
ON td.InstrumentID = di.InstrumentID
WHERE DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)
AND di.VisibleInternallyOnly = 0 AND di.Tradable = 1
AND di.InstrumentTypeID = 10
GROUP BY td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
UNION
SELECT td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
	  --,OpenedPositions
	  --,SUM(UsersOpen) UsersOpen
	  --,OpenPositions
	  ,SUM(UsersHold) UsersHold
	  ,CASE WHEN SUM(UsersHold) >=1000 THEN 'Populat Assets'
	  WHEN SUM(UsersHold) >=100 THEN 'Tail'
	  ELSE 'Long Tail' END AssetPopularity
FROM BI_DB.dbo.BI_DB_Daily_TradeData td WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)
ON td.InstrumentID = di.InstrumentID
WHERE DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)
AND di.VisibleInternallyOnly = 0 AND di.Tradable = 1
AND di.InstrumentTypeID = 6
GROUP BY td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
UNION
SELECT td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
	  --,OpenedPositions
	  --,SUM(UsersOpen) UsersOpen
	  --,OpenPositions
	  ,SUM(UsersHold) UsersHold
	  ,CASE WHEN SUM(UsersHold) >=1000 THEN 'Populat Assets'
	  WHEN SUM(UsersHold) >=100 THEN 'Tail'
	  ELSE 'Long Tail' END AssetPopularity
FROM BI_DB.dbo.BI_DB_Daily_TradeData td WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)
ON td.InstrumentID = di.InstrumentID
WHERE DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)
AND di.VisibleInternallyOnly = 0 AND di.Tradable = 1
AND di.InstrumentTypeID = 2
GROUP BY td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
UNION
SELECT td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName
	  --,OpenedPositions
	  --,SUM(UsersOpen) UsersOpen
	  --,OpenPositions
	  ,SUM(UsersHold) UsersHold
	  ,CASE WHEN SUM(UsersHold) >=1000 THEN 'Populat Assets'
	  WHEN SUM(UsersHold) >=100 THEN 'Tail'
	  ELSE 'Long Tail' END AssetPopularity
FROM BI_DB.dbo.BI_DB_Daily_TradeData td WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Instrument] di WITH (NOLOCK)
ON td.InstrumentID = di.InstrumentID
WHERE DateID = CAST(CONVERT(CHAR(8),GETDATE()-1,112) AS INT)
AND di.VisibleInternallyOnly = 0 AND di.Tradable = 1
AND di.InstrumentTypeID = 1
GROUP BY td.Date
	  ,td.DateID
	  ,di.InstrumentType
	  ,di.InstrumentID
	  ,di.InstrumentDisplayName