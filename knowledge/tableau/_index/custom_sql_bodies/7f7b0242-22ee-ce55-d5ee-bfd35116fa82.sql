--- PART 1: Historical Data (Until March 2026)
SELECT 
    f.Date,
    f.YearMonth,
    -- Mapping regions based on Dim_Country to ensure consistency across UNION
    CASE 
        WHEN dc.MarketingRegionManualName IN ('UK', 'German', 'French', 'Italian', 'Spain', 'Nordics', 'CEE') THEN 'UK&EU'
        WHEN dc.MarketingRegionManualName IN ('Australia', 'SEA') THEN 'APAC'
        WHEN dc.MarketingRegionManualName IN ('USA', 'Latam') THEN 'Americas'
        WHEN dc.MarketingRegionManualName IN ('Arabic', 'Africa') THEN 'Middle East & Africa'
        WHEN dc.MarketingRegionManualName = 'ROW' THEN 'ROW/Unknown'
        ELSE 'ROW/Unknown' 
    END AS Region,
    f.CountryID,
    f.Funded_EOM,
    ISNULL(c.NewFunded, 0) AS New_Funded,
    CAST(GETDATE() AS DATE) AS LoadDate
FROM (
    -- Historical Snapshot
    SELECT 
        EOMONTH(ActiveDate) AS Date,
        Active_Month AS YearMonth,
        CountryID,
        SUM(IsEOM_Funded_NEW) AS Funded_EOM
    FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData
    WHERE ActiveDate >= '20220101'
      AND ActiveDate <= '20260331'
    GROUP BY EOMONTH(ActiveDate), Active_Month, CountryID
) f
JOIN DWH_dbo.Dim_Country dc ON dc.CountryID = f.CountryID -- Joining Dim_Country for Part 1
LEFT JOIN (
    -- Historical New Funded
    SELECT 
        EOMONTH(FirstNewFundedDate) AS Date,
        CountryID,
        COUNT(DISTINCT CID) AS NewFunded
    FROM BI_DB_dbo.BI_DB_CIDFirstDates
    WHERE FirstNewFundedDate >= '20220101'
      AND FirstNewFundedDate <= '20260331'
    GROUP BY EOMONTH(FirstNewFundedDate), CountryID
) c ON f.Date = c.Date AND f.CountryID = c.CountryID

UNION ALL

--- PART 2: New Data (From April 2026 onwards)
SELECT 
    COALESCE(EOM.Date, NEW.Date) AS Date,
    COALESCE(EOM.YearMonth, NEW.YearMonth) AS YearMonth,
    -- Mapping regions based on Dim_Country
    CASE 
        WHEN dc.MarketingRegionManualName IN ('UK', 'German', 'French', 'Italian', 'Spain', 'Nordics', 'CEE') THEN 'UK&EU'
        WHEN dc.MarketingRegionManualName IN ('Australia', 'SEA') THEN 'APAC'
        WHEN dc.MarketingRegionManualName IN ('USA', 'Latam') THEN 'Americas'
        WHEN dc.MarketingRegionManualName IN ('Arabic', 'Africa') THEN 'Middle East & Africa'
        WHEN dc.MarketingRegionManualName = 'ROW' THEN 'ROW/Unknown'
        ELSE 'ROW/Unknown' 
    END AS Region,
    COALESCE(EOM.CountryID, NEW.CountryID) AS CountryID,
    ISNULL(EOM.Funded_EOM, 0) AS Funded_EOM,
    ISNULL(NEW.New_Funded_Count, 0) AS New_Fund_Status,
    CAST(GETDATE() AS DATE) AS LoadDate
FROM (
    -- New Snapshot Logic
    SELECT 
        EOMONTH(bddcds.Date) AS Date,
        YEAR(bddcds.Date) * 100 + MONTH(bddcds.Date) AS YearMonth,
        bddcds.CountryID,
        COUNT(DISTINCT RealCID) AS Funded_EOM
    FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status bddcds
    INNER JOIN (
        SELECT YEAR(Date) AS Yr, MONTH(Date) AS Mn, MAX(DateID) AS MaxDateID
        FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
        WHERE DateID >= 20260401 
        GROUP BY YEAR(Date), MONTH(Date)
    ) AS MaxDates ON bddcds.DateID = MaxDates.MaxDateID
    WHERE bddcds.IsFunded = 1 AND bddcds.IsValidCustomer = 1
    GROUP BY EOMONTH(bddcds.Date), YEAR(bddcds.Date) * 100 + MONTH(bddcds.Date), bddcds.CountryID
) AS EOM
FULL OUTER JOIN (
    -- New Funded Logic
    SELECT 
        EOMONTH(bddcds.Date) AS Date,
        YEAR(bddcds.Date) * 100 + MONTH(bddcds.Date) AS YearMonth,
        bddcds.CountryID,
        COUNT(DISTINCT RealCID) AS New_Funded_Count
    FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status bddcds
    WHERE bddcds.DateID >= 20260401 
      AND bddcds.FirstTimeFunded = 1 
      AND bddcds.IsValidCustomer = 1
    GROUP BY EOMONTH(bddcds.Date), YEAR(bddcds.Date) * 100 + MONTH(bddcds.Date), bddcds.CountryID
) AS NEW ON EOM.YearMonth = NEW.YearMonth AND EOM.CountryID = NEW.CountryID
JOIN DWH_dbo.Dim_Country dc ON dc.CountryID = COALESCE(EOM.CountryID, NEW.CountryID) -- Joining Dim_Country for Part 2