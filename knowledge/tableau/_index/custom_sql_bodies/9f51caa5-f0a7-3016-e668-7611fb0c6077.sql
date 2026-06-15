SELECT 
    q.EndOfQuarter,
    q.FiscalYearQtr 'YearQtr',
    ISNULL(c.UsersEverTouchedCopy, 0) AS UsersEverTouchedCopy,
    ISNULL(m.ActiveMirrors, 0) AS ActiveCopy,
	CAST(GETDATE() AS DATE) AS LoadDate
FROM (
    SELECT 
        FiscalYear,
        FiscalYearQtr,
        MIN(FullDate) AS StartOfQuarter,
        MAX(FullDate) AS EndOfQuarter,
        MIN(DateKey) AS StartDateKey,
        MAX(DateKey) AS EndDateKey
    FROM DWH_dbo.Dim_Date WITH (NOLOCK)
    WHERE CalendarYear >= 2022
          AND DateKey <= CAST(FORMAT(GETDATE(), 'yyyyMMdd') AS INT)
    GROUP BY FiscalYear, FiscalYearQtr
) q
LEFT JOIN (
--how many users ever touched copy
    SELECT 
        dd1.FiscalYearQtr,
        COUNT(DISTINCT fca.RealCID) AS UsersEverTouchedCopy
    FROM DWH_dbo.Fact_CustomerAction fca
    JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
        ON fsc.RealCID = fca.RealCID
    JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
        ON fsc.DateRangeID = dr.DateRangeID
           AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
    JOIN (
        SELECT 
            FiscalYearQtr,
            MAX(DateKey) AS EndDateKey
        FROM DWH_dbo.Dim_Date WITH (NOLOCK)
        GROUP BY FiscalYearQtr
    ) dd1 ON fca.DateID <= dd1.EndDateKey
    WHERE 
        fca.ActionTypeID = 17
        AND fsc.IsValidCustomer = 1
    GROUP BY dd1.FiscalYearQtr
) c ON q.FiscalYearQtr = c.FiscalYearQtr
LEFT JOIN (
--how many touched copy in the period
    SELECT 
        dd1.FiscalYearQtr,
        COUNT(DISTINCT dm.CID) AS ActiveMirrors
    FROM DWH_dbo.Dim_Mirror dm
    JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
        ON fsc.RealCID = dm.CID
    JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
        ON fsc.DateRangeID = dr.DateRangeID
           AND dm.OpenDateID BETWEEN dr.FromDateID AND dr.ToDateID
    JOIN (
        SELECT 
            FiscalYearQtr,
            MIN(DateKey) AS StartDateKey,
            MAX(DateKey) AS EndDateKey
        FROM DWH_dbo.Dim_Date WITH (NOLOCK)
        GROUP BY FiscalYearQtr
    ) dd1 ON dm.OpenDateID <= dd1.EndDateKey
           AND (dm.CloseDateID >= dd1.StartDateKey OR dm.CloseDateID = 0)
    WHERE fsc.IsValidCustomer = 1
    GROUP BY dd1.FiscalYearQtr
) m ON q.FiscalYearQtr = m.FiscalYearQtr