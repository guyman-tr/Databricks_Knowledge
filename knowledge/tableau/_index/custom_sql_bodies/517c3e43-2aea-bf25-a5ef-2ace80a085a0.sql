SELECT dc.[RealCID], dc.[UserName]
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -1, <[Parameters].[Parameter 1]>) THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS change_1Y
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -2, <[Parameters].[Parameter 1]>) THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS change_2Y
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -3, <[Parameters].[Parameter 1]>) THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS change_3Y
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -4, <[Parameters].[Parameter 1]>) THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS change_4Y
	, (CASE 
        WHEN MIN(StartPeriod) >= dateadd(year, -5, <[Parameters].[Parameter 1]>) THEN 
            EXP(SUM(LOG(1 + (gain.Gain / 100.00)))) 
        ELSE 
            NULL 
    END) - 1 AS change_5Y
FROM 
    [BI_DB_dbo].BI_DB_MonthlyGain gain with (Nolock)
	JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON gain.RealCID = dc.RealCID
	JOIN DWH_dbo.Fact_SnapshotCustomer sc WITH (NOLOCK) ON sc.RealCID = dc.[RealCID]
	JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK) ON dr.DateRangeID = sc.DateRangeID
WHERE ((sc.GuruStatusID >= 2 AND sc.IsValidCustomer = 1)
OR sc.AccountTypeID = 9)
AND dr.FromDateID <= CAST(CONVERT(VARCHAR(8), GETDATE() - 1, 112) AS INT)
AND dr.ToDateID >= CAST(CONVERT(VARCHAR(8), GETDATE() - 1, 112) AS INT)
AND StartPeriod >= dateadd(year, -5, <[Parameters].[Parameter 1]>) --AND gain.ID = '0EBA4EE2-9D77-E811-A2C4-0017A4770402'
GROUP BY dc.[RealCID], dc.[UserName]