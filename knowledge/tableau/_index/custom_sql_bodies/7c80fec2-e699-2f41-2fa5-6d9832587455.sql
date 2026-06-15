SELECT 
		20240413 AS DateID
		, dc.RealCID
		, '20240413' AS [Date]
		, 'ThisWeek' AS TimeRange
		, ISNULL(fa.FirstActionType, 'NoAction') AS FirstActionType
        , dc.DesignatedRegulationID AS RegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName as MarketingRegion
		, count(dc.RealCID) AS Registered
		, count(CASE WHEN dc.FirstDepositDate > '2000-01-01' AND dc.FirstDepositDate <= '20240414' THEN dc.RealCID END) AS ConvertedRegistrationFTD
FROM DWH_dbo.Dim_Customer dc
	JOIN DWH_dbo.Dim_Country dc1
		ON dc.CountryID = dc1.CountryID
	LEFT JOIN 
		(
			SELECT a.RealCID, a.FirstActionType
			FROM 
			(
			SELECT bddcds.RealCID, bddcds.FirstActionType, ROW_NUMBER () OVER (PARTITION BY bddcds.RealCID ORDER BY bddcds.DateID desc) AS RN
			FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status bddcds
			WHERE bddcds.FirstActionDateID BETWEEN 20240407 AND 20240413
			) a
			WHERE RN = 1
		) fa
		ON dc.RealCID = fa.RealCID
WHERE dc.RegisteredReal BETWEEN '20240407' AND '20240414'
GROUP BY 
		dc.DesignatedRegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName
		, fa.FirstActionType
		, dc.RealCID


UNION ALL

SELECT 
		20240413 AS DateID
		, dc.RealCID
		, '20240413' AS [Date]
		, 'Yesterday' AS TimeRange
		, ISNULL(fa.FirstActionType, 'NoAction') AS FirstActionType
        , dc.DesignatedRegulationID AS RegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName as MarketingRegion
		, count(dc.RealCID) AS Registered
		, count(CASE WHEN dc.FirstDepositDate > '2000-01-01' AND dc.FirstDepositDate <= '20240414' THEN dc.RealCID END) AS ConvertedRegistrationFTD
FROM DWH_dbo.Dim_Customer dc
	JOIN DWH_dbo.Dim_Country dc1
		ON dc.CountryID = dc1.CountryID
	LEFT JOIN 
		(
			SELECT a.RealCID, a.FirstActionType
			FROM 
			(
			SELECT bddcds.RealCID, bddcds.FirstActionType, ROW_NUMBER () OVER (PARTITION BY bddcds.RealCID ORDER BY bddcds.DateID desc) AS RN
			FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status bddcds
			WHERE bddcds.FirstActionDateID BETWEEN 20240413 AND 20240413
			) a
			WHERE RN = 1
		) fa
		ON dc.RealCID = fa.RealCID
WHERE dc.RegisteredReal BETWEEN '20240413' AND '20240414'
GROUP BY 
		dc.DesignatedRegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName
		, fa.FirstActionType
		, dc.RealCID