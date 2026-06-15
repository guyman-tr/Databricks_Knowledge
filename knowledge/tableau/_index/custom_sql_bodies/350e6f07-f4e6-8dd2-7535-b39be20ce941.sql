SELECT
    CAST(FirstActionDate AS DATE) AS EventDate,
    YEAR(CAST(FirstActionDate AS DATE)) AS EventYear,
    MONTH(CAST(FirstActionDate AS DATE)) AS EventMonth,
    dc1.Name AS Country,
    dc1.MarketingRegionManualName AS Region,

    SUM(CASE WHEN FirstAction = 'Copy' THEN 1 ELSE 0 END) AS Copy_FAs,
    SUM(CASE WHEN FirstAction = 'Copy Fund' THEN 1 ELSE 0 END) AS CopyFund_FAs,
    SUM(CASE WHEN FirstAction = 'Crypto' THEN 1 ELSE 0 END) AS Crypto_FAs,
    SUM(CASE WHEN FirstAction = 'FX/Commodities/Indices' THEN 1 ELSE 0 END) AS FX_Comm_Ind_FAs,
    SUM(CASE WHEN FirstAction = 'Stocks/ETFs' THEN 1 ELSE 0 END) AS Stocks_ETFs_FAs,

    --SUM(
    --    CASE
    --        WHEN FirstAction NOT IN (
    --            'Copy',
    --            'Copy Fund',
    --            'Crypto',
    --            'FX/Commodities/Indices',
    --            'Stocks/ETFs'
    --        ) OR FirstAction IS NULL
    --        THEN 1
    --        ELSE 0
    --    END
    --) AS Other_FAs,

    COUNT(DISTINCT CID) AS Total_FAs

FROM BI_DB_dbo.[BI_DB_First5Actions] f5
JOIN DWH_dbo.Dim_Customer dc
    ON dc.RealCID = f5.CID
JOIN DWH_dbo.Dim_Country dc1
    ON dc.CountryID = dc1.CountryID

WHERE FirstActionDate >= '20240101'

GROUP BY
    CAST(FirstActionDate AS DATE),
    YEAR(CAST(FirstActionDate AS DATE)),
    MONTH(CAST(FirstActionDate AS DATE)),
    dc1.Name,
    dc1.MarketingRegionManualName