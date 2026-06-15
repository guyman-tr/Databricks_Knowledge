SELECT 
  dd.FullDate AS Date
, YEAR(dd.FullDate) * 100 + MONTH(dd.FullDate) AS Year_Month
, a.BuyCurrency
, 'Real' AS [CFD/Real]
, ISNULL(a.PriceEOM,0) AS PriceEOM
, ISNULL(a.Avg_Units,0) AS Avg_Units
, ISNULL(a.Avg_Value_OptIn,0) AS Avg_Value_OptIn
, CAST(GETDATE() AS DATE) AS LoadDate
FROM 
(
    SELECT DateKey, FullDate
    FROM DWH_dbo.Dim_Date dd WITH (NOLOCK)	
    WHERE (IsLastDayOfMonth='Y' AND dd.CalendarYear>=2022		
    AND dd.DateKey<=CAST(FORMAT(EOMONTH(DATEADD(MONTH, -1, GETDATE())), 'yyyyMMdd') AS INT))
    OR DateKey=CAST(FORMAT(EOMONTH(GETDATE() - 1), 'yyyyMMdd') AS INT)
) dd
LEFT JOIN 
(
    SELECT 
        EOMONTH(base.[Date]) AS [Date],
        base.Year_Month,
        base.BuyCurrency,
        MAX(fcws.BidSpreaded) AS PriceEOM,
        SUM(base.Avg_Units) AS Avg_Units,
        SUM(base.Avg_Units * fcws.BidSpreaded) AS Avg_Value_OptIn
    FROM (
        -- Part 1: Historical Data (Pre-July 2024)
        SELECT 
            EOMONTH(bdcn.Date) AS [Date],
            YEAR(bdcn.Date) * 100 + MONTH(bdcn.Date) AS Year_Month,
            bdcn.BuyCurrency,
            /* Subquery to find the primary USD InstrumentID for consistent pricing */
            (SELECT MIN(InstrumentID) FROM DWH_dbo.Dim_Instrument 
             WHERE BuyCurrency = bdcn.BuyCurrency AND SellCurrency = 'USD' 
             AND Tradable = 1 AND IsFuture = 0) AS USD_InstrumentID,
            (
                SUM(Real_Units)
                - SUM(CASE WHEN bdcn.TanganyStatus IN ('Customer','Internal') THEN Real_Units ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation IN ('FinCEN','eToroUS','FinCEN+FINRA','FINRAONLY') THEN Real_Units ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation = 'None' THEN Real_Units ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation = 'FCA' AND bdcn.CountryName = 'United Kingdom' AND bdcn.NewUsers = 1 THEN Real_Units ELSE 0 END)
            ) * 1.0 / COUNT(DISTINCT bdcn.Date) AS Avg_Units
        FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn
        JOIN Dealing_dbo.Dealing_Staking_Parameters dsp 
            ON bdcn.InstrumentID = dsp.InstrumentID 
            AND bdcn.Date >= DATEADD(MONTH, -1, Distribution_StartDate)
        WHERE bdcn.IsCreditReportValidCB = 1
          AND bdcn.Date >= '2024-01-01' 
          AND bdcn.Date < '2024-07-01'
        GROUP BY EOMONTH(bdcn.Date), YEAR(bdcn.Date) * 100 + MONTH(bdcn.Date), bdcn.BuyCurrency

        UNION ALL

        -- Part 2: Current Logic (Post-July 2024)
        SELECT 
            MAX(bdcn.Date) AS [Date],
            YEAR(bdcn.Date) * 100 + MONTH(bdcn.Date) AS Year_Month,
            bdcn.BuyCurrency,
            (SELECT MIN(InstrumentID) FROM DWH_dbo.Dim_Instrument 
             WHERE BuyCurrency = bdcn.BuyCurrency AND SellCurrency = 'USD' 
             AND Tradable = 1 AND IsFuture = 0) AS USD_InstrumentID,
            (
                SUM(Real_Units_Staking_OptIn)
                - SUM(CASE WHEN bdcn.TanganyStatus IN ('Customer','Internal') THEN Real_Units_Staking_OptIn ELSE 0 END)
                - SUM(CASE WHEN bdcn.TanganyStatus IN ('MicaCustomer') AND bdcn.Date >= '20251201' THEN Real_Units_Staking_OptIn ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation IN ('FinCEN','eToroUS','FinCEN+FINRA','FINRAONLY') THEN Real_Units_Staking_OptIn ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation = 'None' THEN Real_Units_Staking_OptIn ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation = 'FCA' AND bdcn.CountryName = 'United Kingdom' AND bdcn.NewUsers = 1 AND bdcn.Date < '20250201' THEN Real_Units_Staking_OptIn ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation = 'FSRA' AND bdcn.Date >= '20240701' AND bdcn.Date < '20240801' THEN Real_Units_Staking_OptIn ELSE 0 END)
                - SUM(CASE WHEN bdcn.Regulation = 'FCA' AND bdcn.BuyCurrency NOT IN ('ADA','TRX','SOL','ETH','POL','NEAR') AND bdcn.Date < '20251201' THEN Real_Units_Staking_OptIn ELSE 0 END)
            ) * 1.0 / COUNT(DISTINCT bdcn.Date) AS Avg_Units
        FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn
        JOIN Dealing_dbo.Dealing_Staking_Parameters dsp 
            ON bdcn.InstrumentID = dsp.InstrumentID 
            AND bdcn.Date >= DATEADD(MONTH, -1, Distribution_StartDate)
        WHERE bdcn.IsCreditReportValidCB = 1
          AND bdcn.Date >= '2024-07-01' 
        GROUP BY YEAR(bdcn.Date) * 100 + MONTH(bdcn.Date), bdcn.BuyCurrency

        UNION ALL 

        -- Part 3: Staking US (FINCEN+FINRA)
        SELECT 
            MAX(p.Date) AS [Date],
            YEAR(p.Date) * 100 + MONTH(p.Date) AS Year_Month,
            di.BuyCurrency,
            (SELECT MIN(InstrumentID) FROM DWH_dbo.Dim_Instrument 
             WHERE BuyCurrency = di.BuyCurrency AND SellCurrency = 'USD' 
             AND Tradable = 1 AND IsFuture = 0) AS USD_InstrumentID,
            SUM([Real_Units_Staking_OptIn]) * 1.0 / COUNT(DISTINCT p.Date) AS Avg_Units 
        FROM [BI_DB_dbo].[BI_DB_Crypto_NOP_CID] p
        INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON p.CID = fsc.RealCID
        INNER JOIN DWH_dbo.Dim_Range drr ON fsc.DateRangeID = drr.DateRangeID 
            AND CONVERT(int, CONVERT(char(8), [Date], 112)) BETWEEN drr.FromDateID AND drr.ToDateID
        INNER JOIN DWH_dbo.Dim_Instrument di ON di.Name = p.InstrumentName
        JOIN Dealing_dbo.Dealing_Staking_Parameters_US dsp ON dsp.InstrumentID = di.InstrumentID 
            AND p.Date >= DATEADD(MONTH, -1, Distribution_StartDate)
        LEFT JOIN DWH_dbo.Dim_State_and_Province dsap ON fsc.RegionID = dsap.RegionByIP_ID
        WHERE p.[Date] >= '20251201'
          AND [Regulation] IN ('FinCEN+FINRA')
          AND fsc.IsCreditReportValidCB = 1 
          AND fsc.IsValidCustomer = 1
          AND dsap.Name NOT IN ('California','Maryland','New Jersey','Washington','Wisconsin')
        GROUP BY YEAR(p.Date) * 100 + MONTH(p.Date), di.BuyCurrency
    ) AS base
    /* Final Join for REAL part using the USD InstrumentID */
    JOIN DWH_dbo.Fact_CurrencyPriceWithSplit fcws
        ON base.USD_InstrumentID = fcws.InstrumentID 
        AND fcws.OccurredDate = base.[Date]
    GROUP BY EOMONTH(base.[Date]), base.Year_Month, base.BuyCurrency	
) a ON dd.FullDate = a.[Date]

UNION ALL

-- CFD SECTION
SELECT 
    dd.FullDate AS Date
    , YEAR(dd.FullDate) * 100 + MONTH(dd.FullDate) AS Year_Month
    , a.BuyCurrency
    , 'CFD' AS [CFD/Real]
    , ISNULL(a.PriceEOM,0) AS PriceEOM
    , ISNULL(a.Avg_Units_CFD,0) AS Avg_Units_CFD
    , ISNULL(a.Avg_Value_CFD,0) AS Avg_Value_CFD
    , CAST(GETDATE() AS DATE) AS LoadDate
FROM 
(
    SELECT DateKey, FullDate
    FROM DWH_dbo.Dim_Date dd WITH (NOLOCK)	
    WHERE (IsLastDayOfMonth='Y' AND dd.CalendarYear>=2022		
    AND dd.DateKey<=CAST(FORMAT(EOMONTH(DATEADD(MONTH, -1, GETDATE())), 'yyyyMMdd') AS INT))
    OR DateKey=CAST(FORMAT(EOMONTH(GETDATE() - 1), 'yyyyMMdd') AS INT)
) dd
LEFT JOIN 
(
    SELECT 
        EOMONTH(base.[Date]) AS Date,
        base.Year_Month,
        base.BuyCurrency,
        fcws.BidSpreaded AS PriceEOM,
        base.Avg_Units_CFD,
        base.Avg_Units_CFD * fcws.BidSpreaded AS Avg_Value_CFD
    FROM 
    (
        SELECT
            MAX(bdcn.Date) AS [Date],
            YEAR(bdcn.Date) * 100 + MONTH(bdcn.Date) AS Year_Month,
            bdcn.BuyCurrency,		
            (SELECT MIN(InstrumentID) FROM DWH_dbo.Dim_Instrument 
             WHERE BuyCurrency = bdcn.BuyCurrency AND SellCurrency = 'USD' 
             AND Tradable = 1 AND IsFuture = 0) AS USD_InstrumentID,
            SUM(CASE WHEN IsBuy = 1 THEN bdcn.CFD_Units ELSE -bdcn.CFD_Units END) * 1.0 / COUNT(DISTINCT bdcn.Date) AS Avg_Units_CFD			
        FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
        JOIN Dealing_dbo.Dealing_Staking_Parameters dsp 
            ON dsp.Currency = bdcn.BuyCurrency
            AND bdcn.Date >= DATEADD(MONTH, -1, Distribution_StartDate)
        WHERE bdcn.IsCreditReportValidCB = 1
        GROUP BY YEAR(bdcn.Date) * 100 + MONTH(bdcn.Date), bdcn.BuyCurrency
    ) base
    /* Final Join for CFD part using the USD InstrumentID */
    JOIN DWH_dbo.Fact_CurrencyPriceWithSplit fcws
        ON base.USD_InstrumentID = fcws.InstrumentID 
        AND fcws.OccurredDate = base.[Date]
) a ON dd.FullDate = a.[Date]