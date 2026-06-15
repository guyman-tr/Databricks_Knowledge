SELECT 
    dd.FullDate AS 'Date',
    dd.DateKey,
	YEAR(FullDate) * 100 + MONTH(FullDate) AS Year_Month,
    COUNT(DISTINCT fsc.RealCID) AS RegisteredUsers
FROM DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)

INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
    ON fsc.DateRangeID = dr.DateRangeID
INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
    ON dd.DateKey BETWEEN dr.FromDateID AND dr.ToDateID

WHERE 
    fsc.IsValidCustomer = 1
 AND  (
        dd.IsLastDayOfMonth = 'Y' 
        AND dd.CalendarYear >= 2022
        AND dd.DateKey <= CAST(FORMAT(EOMONTH(DATEADD(MONTH, -1, GETDATE())), 'yyyyMMdd') AS INT)
    )
    OR dd.DateKey = CAST(FORMAT(GETDATE() - 1, 'yyyyMMdd') AS INT)

GROUP BY dd.FullDate, dd.DateKey,YEAR(FullDate) * 100 + MONTH(FullDate)