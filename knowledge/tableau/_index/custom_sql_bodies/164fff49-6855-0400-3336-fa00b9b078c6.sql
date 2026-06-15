SELECT a.*
	, dc.Name AS Country
	, dmc.Name AS MifidCategory
	, dpl.Name AS PlayerLevel
	, dr.Name AS Regulation
FROM 
(
SELECT a.DateID
	 , a.Date
	 , a.TimeRange
	 , a.FirstActionType
	 , a.RegulationID
	 , a.IsCreditReportValidCB
	 , a.IsValidCustomer
	 , a.MifidCategorizationID
	 , a.PlayerLevelID
	 , a.CountryID
	 , a.MarketingRegion
	 , sum(a.Registered) AS Registered
	 , sum(a.ConvertedRegistrationFTD) AS ConvertedRegistrationFTD
FROM 
(
SELECT 
		CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT) AS DateID
		, dc.RealCID
		, cast(getdate()-1 as Date) AS [Date]
		, 'Yesterday' AS TimeRange
		, ISNULL(fa.FirstActionType, 'NoAction') AS FirstActionType
        , dc.DesignatedRegulationID AS RegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName as MarketingRegion
		, count(CASE WHEN RegisteredReal  BETWEEN cast(getdate()-1 as Date) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) AS Registered
		, count(CASE WHEN dc.FirstDepositDate BETWEEN cast(getdate()-1 as Date) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) AS ConvertedRegistrationFTD
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
			WHERE bddcds.FirstActionDateID BETWEEN CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT)
			) a
			WHERE RN = 1
		) fa
		ON dc.RealCID = fa.RealCID
-- WHERE dc.RegisteredReal BETWEEN '20240407' AND '20240414' 
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
HAVING 
		 count(CASE WHEN RegisteredReal  BETWEEN cast(getdate()-1 as Date) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) = 1 or
		 count(CASE WHEN dc.FirstDepositDate BETWEEN cast(getdate()-1 as Date) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) = 1


UNION ALL

SELECT 
		CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT) AS DateID
		, dc.RealCID
		, cast(getdate()-1 as Date) AS [Date]
		, 'ThisWeek' AS TimeRange
		, ISNULL(fa.FirstActionType, 'NoAction') AS FirstActionType
        , dc.DesignatedRegulationID AS RegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName as MarketingRegion
		, count(CASE WHEN RegisteredReal  BETWEEN DATEADD(week, DATEDIFF(ww, 0, cast(getdate()-1 as Date)), -1) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) AS Registered
		, count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(week, DATEDIFF(ww, 0, cast(getdate()-1 as Date)), -1) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) AS ConvertedRegistrationFTD
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
			WHERE bddcds.FirstActionDateID BETWEEN CAST(FORMAT(CAST(DATEADD(week, DATEDIFF(ww, 0, cast(getdate()-1 as Date)), -1) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT)
			) a
			WHERE RN = 1
		) fa
		ON dc.RealCID = fa.RealCID
-- WHERE dc.RegisteredReal BETWEEN '20240407' AND '20240414' 
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
HAVING 
		 count(CASE WHEN RegisteredReal  BETWEEN DATEADD(week, DATEDIFF(ww, 0, cast(getdate()-1 as Date)), -1) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) = 1 or
		 count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(week, DATEDIFF(ww, 0, cast(getdate()-1 as Date)), -1) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) = 1


UNION ALL 

SELECT 
		CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT) AS DateID
		, dc.RealCID
		, cast(getdate()-1 as Date) AS [Date]
		, 'ThisMonth' AS TimeRange
		, ISNULL(fa.FirstActionType, 'NoAction') AS FirstActionType
        , dc.DesignatedRegulationID AS RegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName as MarketingRegion
		, count(CASE WHEN RegisteredReal  BETWEEN DATEADD(month, DATEDIFF(mm, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) AS Registered
		, count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(month, DATEDIFF(mm, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) AS ConvertedRegistrationFTD
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
			WHERE bddcds.FirstActionDateID BETWEEN CAST(FORMAT(CAST(DATEADD(month, DATEDIFF(mm, 0, cast(getdate()-1 as Date)), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT)
			) a
			WHERE RN = 1
		) fa
		ON dc.RealCID = fa.RealCID
-- WHERE dc.RegisteredReal BETWEEN '20240407' AND '20240414' 
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
HAVING 
		 count(CASE WHEN RegisteredReal  BETWEEN DATEADD(month, DATEDIFF(mm, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) = 1 or
		 count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(month, DATEDIFF(mm, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) = 1

UNION ALL 

SELECT 
		CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT) AS DateID
		, dc.RealCID
		, cast(getdate()-1 as Date) AS [Date]
		, 'ThisQuarter' AS TimeRange
		, ISNULL(fa.FirstActionType, 'NoAction') AS FirstActionType
        , dc.DesignatedRegulationID AS RegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName as MarketingRegion
		, count(CASE WHEN RegisteredReal  BETWEEN DATEADD(qq, DATEDIFF(qq, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) AS Registered
		, count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(qq, DATEDIFF(qq, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) AS ConvertedRegistrationFTD
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
			WHERE bddcds.FirstActionDateID BETWEEN CAST(FORMAT(CAST(DATEADD(qq, DATEDIFF(qq, 0, cast(getdate()-1 as Date)), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT)
			) a
			WHERE RN = 1
		) fa
		ON dc.RealCID = fa.RealCID
-- WHERE dc.RegisteredReal BETWEEN '20240407' AND '20240414' 
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
HAVING 
		 count(CASE WHEN RegisteredReal  BETWEEN DATEADD(qq, DATEDIFF(qq, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) = 1 or
		 count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(qq, DATEDIFF(qq, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) = 1

UNION ALL 

SELECT 
		CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT) AS DateID
		, dc.RealCID
		, cast(getdate()-1 as Date) AS [Date]
		, 'ThisYear' AS TimeRange
		, ISNULL(fa.FirstActionType, 'NoAction') AS FirstActionType
        , dc.DesignatedRegulationID AS RegulationID
        , IsCreditReportValidCB
        , IsValidCustomer
        , MifidCategorizationID
        , PlayerLevelID
        , dc.CountryID
        , dc1.MarketingRegionManualName as MarketingRegion
		, count(CASE WHEN RegisteredReal  BETWEEN DATEADD(yy, DATEDIFF(yy, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) AS Registered
		, count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(yy, DATEDIFF(yy, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) AS ConvertedRegistrationFTD
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
			WHERE bddcds.FirstActionDateID BETWEEN CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, cast(getdate()-1 as Date)), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(cast(getdate()-1 as Date) AS DATE),'yyyyMMdd') as INT)
			) a
			WHERE RN = 1
		) fa
		ON dc.RealCID = fa.RealCID
-- WHERE dc.RegisteredReal BETWEEN '20240407' AND '20240414' 
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
HAVING 
		 count(CASE WHEN RegisteredReal  BETWEEN DATEADD(yy, DATEDIFF(yy, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date))  then dc.RealCID end) = 1 or
		 count(CASE WHEN dc.FirstDepositDate BETWEEN DATEADD(yy, DATEDIFF(yy, 0, cast(getdate()-1 as Date)), 0) AND dateadd (DAY,1,cast(getdate()-1 as Date)) THEN dc.RealCID END) = 1
) a
GROUP BY a.DateID
	 , a.Date
	 , a.TimeRange
	 , a.FirstActionType
	 , a.RegulationID
	 , a.IsCreditReportValidCB
	 , a.IsValidCustomer
	 , a.MifidCategorizationID
	 , a.PlayerLevelID
	 , a.CountryID
	 , a.MarketingRegion
) a
JOIN DWH_dbo.Dim_Country dc
	ON a.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_MifidCategorization dmc
	ON a.MifidCategorizationID = dmc.MifidCategorizationID
JOIN DWH_dbo.Dim_PlayerLevel dpl
	ON a.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH_dbo.Dim_Regulation dr
	ON a.RegulationID = dr.DWHRegulationID