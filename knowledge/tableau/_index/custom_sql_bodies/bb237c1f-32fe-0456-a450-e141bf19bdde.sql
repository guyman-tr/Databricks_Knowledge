SELECT dc.[RealCID], dc.[UserName], '1Y Change' AS ChangePeriod
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -1, GETDATE())  THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS PriceChange
FROM 
    [BI_DB_dbo].BI_DB_MonthlyGain gain with (Nolock)
	JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON gain.RealCID = dc.RealCID
	JOIN DWH_dbo.Fact_SnapshotCustomer sc WITH (NOLOCK) ON sc.RealCID = dc.[RealCID]
	JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK) ON dr.DateRangeID = sc.DateRangeID
WHERE ((sc.GuruStatusID >= 2 AND sc.IsValidCustomer = 1)
OR sc.AccountTypeID = 9)
AND dr.FromDateID <= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND dr.ToDateID >= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND StartPeriod >= dateadd(year, -1, GETDATE()) --AND gain.ID = '0EBA4EE2-9D77-E811-A2C4-0017A4770402'
AND gain.Gain <> -100
GROUP BY dc.[RealCID], dc.[UserName]

UNION ALL

SELECT dc.[RealCID], dc.[UserName], '2Y Change' AS ChangePeriod
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -2, GETDATE())  THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS PriceChange
FROM 
    [BI_DB_dbo].BI_DB_MonthlyGain gain with (Nolock)
	JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON gain.RealCID = dc.RealCID
	JOIN DWH_dbo.Fact_SnapshotCustomer sc WITH (NOLOCK) ON sc.RealCID = dc.[RealCID]
	JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK) ON dr.DateRangeID = sc.DateRangeID
WHERE ((sc.GuruStatusID >= 2 AND sc.IsValidCustomer = 1)
OR sc.AccountTypeID = 9)
AND dr.FromDateID <= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND dr.ToDateID >= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND StartPeriod >= dateadd(year, -2, GETDATE()) --AND gain.ID = '0EBA4EE2-9D77-E811-A2C4-0017A4770402'
AND gain.Gain <> -100
GROUP BY dc.[RealCID], dc.[UserName]

UNION ALL

SELECT dc.[RealCID], dc.[UserName], '3Y Change' AS ChangePeriod
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -3, GETDATE())  THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS PriceChange
FROM 
    [BI_DB_dbo].BI_DB_MonthlyGain gain with (Nolock)
	JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON gain.RealCID = dc.RealCID
	JOIN DWH_dbo.Fact_SnapshotCustomer sc WITH (NOLOCK) ON sc.RealCID = dc.[RealCID]
	JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK) ON dr.DateRangeID = sc.DateRangeID
WHERE ((sc.GuruStatusID >= 2 AND sc.IsValidCustomer = 1)
OR sc.AccountTypeID = 9)
AND dr.FromDateID <= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND dr.ToDateID >= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND StartPeriod >= dateadd(year, -3, GETDATE()) --AND gain.ID = '0EBA4EE2-9D77-E811-A2C4-0017A4770402
AND gain.Gain <> -100
GROUP BY dc.[RealCID], dc.[UserName]

UNION ALL

SELECT dc.[RealCID], dc.[UserName], '4Y Change' AS ChangePeriod
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -4, GETDATE())  THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS PriceChange
FROM 
    [BI_DB_dbo].BI_DB_MonthlyGain gain with (Nolock)
	JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON gain.RealCID = dc.RealCID
	JOIN DWH_dbo.Fact_SnapshotCustomer sc WITH (NOLOCK) ON sc.RealCID = dc.[RealCID]
	JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK) ON dr.DateRangeID = sc.DateRangeID
WHERE ((sc.GuruStatusID >= 2 AND sc.IsValidCustomer = 1)
OR sc.AccountTypeID = 9)
AND dr.FromDateID <= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND dr.ToDateID >= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND StartPeriod >= dateadd(year, -4, GETDATE()) --AND gain.ID = '0EBA4EE2-9D77-E811-A2C4-0017A4770402'
AND gain.Gain <> -100
GROUP BY dc.[RealCID], dc.[UserName]

UNION ALL

SELECT dc.[RealCID], dc.[UserName], '5Y Change' AS ChangePeriod
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -5, GETDATE())  THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS PriceChange
FROM 
    [BI_DB_dbo].BI_DB_MonthlyGain gain with (Nolock)
	JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON gain.RealCID = dc.RealCID
	JOIN DWH_dbo.Fact_SnapshotCustomer sc WITH (NOLOCK) ON sc.RealCID = dc.[RealCID]
	JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK) ON dr.DateRangeID = sc.DateRangeID
WHERE ((sc.GuruStatusID >= 2 AND sc.IsValidCustomer = 1)
OR sc.AccountTypeID = 9)
AND dr.FromDateID <= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND dr.ToDateID >= CAST(CONVERT(VARCHAR(8), GETDATE(), 112) AS INT)
AND StartPeriod >= dateadd(year, -5, GETDATE()) --AND gain.ID = '0EBA4EE2-9D77-E811-A2C4-0017A4770402'
AND gain.Gain <> -100
GROUP BY dc.[RealCID], dc.[UserName]