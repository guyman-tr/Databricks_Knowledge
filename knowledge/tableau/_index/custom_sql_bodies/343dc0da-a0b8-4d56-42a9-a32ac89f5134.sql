SELECT TOP 100
    DateID
    , convert(varchar(6), CONVERT(date, convert(varchar(10), ta.DateID)), 112) AS TimeRange
    , Regulation
    , IsBlocked
FROM BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ta
JOIN DWH_dbo.Dim_Date dd
    ON ta.DateID = dd.DateKey AND dd.IsLastDayOfMonth = 'Y'
    AND ta.TimeRange = 'ThisMonth'
JOIN DWH_dbo.Dim_Country dc
    ON ta.Country = dc.Name
WHERE ta.DateID BETWEEN
    CAST(CONVERT(varchar(8), DATEADD(MONTH, -6, GETDATE()), 112) AS INT)
AND
    CAST(CONVERT(varchar(8), GETDATE(), 112) AS INT)