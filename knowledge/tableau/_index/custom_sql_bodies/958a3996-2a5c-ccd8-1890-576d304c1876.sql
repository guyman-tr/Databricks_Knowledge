--DROP TABLE IF EXISTS #OpenPositions
SELECT [ppl].[CID]
	, dpl.Name AS Club
	, [dc1].[Region]
	, CONCAT(dm.FirstName,' ',dm.LastName) AS Manager
	, [di].[InstrumentID]
	, di.[InstrumentDisplayName]
	, [di].[InstrumentType]
	, (CASE WHEN di.Name LIKE '%[.]EXT%' THEN 'Extended Hours' ELSE 'Market Hours' END) AS IsEXT
   ,ISNULL(SUM([Amount]), 0) AS InvestedAmount
   ,ISNULL(SUM([PositionPnL]), 0) AS UnrealisedPnL
   ,ISNULL(SUM([PositionPnL] + [Amount]), 0) AS UnrealisedEquity
   --INTO #OpenPositions
FROM [BI_DB_dbo].[BI_DB_PositionPnL] ppl WITH (NOLOCK)
JOIN [DWH_dbo].[Dim_Instrument] di
	ON ppl.InstrumentID = di.InstrumentID
JOIN [DWH_dbo].Dim_Customer dc
	ON ppl.CID = dc.RealCID
JOIN [DWH_dbo].Dim_Country dc1
	ON dc1.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_PlayerLevel dpl
	ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Manager dm
	ON dm.ManagerID = dc.AccountManagerID
WHERE ppl.DateID = CONVERT(CHAR(8),DATEADD(DAY, -1, GETDATE()),112)
--AND [di].[InstrumentTypeID] = 5
AND [dc1].MarketingRegionID = 17
AND CONCAT(dm.FirstName,' ',dm.LastName) IN ('Adam Vettese', 'Simon Peters', 'Pearse Carson', 'Stefan Mihailescu', 'Harry Blagden', 'Mark Crouch', 'Valentina Reingold', 'Calum McCoy'
,'Charlie Kaur', 'Varun Sehgal', 'Thomas Williams', 'Luke Sefain', 'Samuel Crain', 'Virgilio Guidi', 'Sarah Glanville', 'Alfie Newsome', 'Callum Frame', 'Sebastian Conway','Marc Kimsey','Farzana Begum','Emily Caton','Lorenzo Greco','Matthew Burroughs','Tate Dupen-Fitzgerald')
--AND di.Name LIKE '%[.]EXT%'
GROUP BY [ppl].[CID]
	, dpl.Name
	, [dc1].[Region]
	, CONCAT(dm.FirstName,' ',dm.LastName)
	, [di].[InstrumentID]
	, di.[InstrumentDisplayName]
	, [di].[InstrumentType]
	, (CASE WHEN di.Name LIKE '%[.]EXT%' THEN 'Extended Hours' ELSE 'Market Hours' END)