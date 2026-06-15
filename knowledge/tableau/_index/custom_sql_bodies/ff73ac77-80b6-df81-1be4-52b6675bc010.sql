SELECT
    calc.MonthStart,
    CONVERT(VARCHAR(7), calc.MonthStart, 126) AS YearMonth,
    calc.Region,
    calc.Country,
    calc.Copy,
    calc.[Smart Portfolio],
    calc.Crypto,
    calc.[FX/Com/Indi],
    calc.[Stocks/ETFs],
    calc.[Total FAs]
FROM (
    SELECT
        monthly.MonthStart,
        monthly.Region,
        monthly.Country,

        CASE
            WHEN monthly.MonthStart = DATEFROMPARTS(
                YEAR(DATEADD(DAY, -1, GETDATE())),
                MONTH(DATEADD(DAY, -1, GETDATE())),
                1
            )
            THEN CAST(
                monthly.Copy_FAs * 1.0
                / DAY(DATEADD(DAY, -1, GETDATE()))
                * DAY(EOMONTH(monthly.MonthStart))
                AS DECIMAL(18,0)
            )
            ELSE monthly.Copy_FAs
        END AS Copy,

        CASE
            WHEN monthly.MonthStart = DATEFROMPARTS(
                YEAR(DATEADD(DAY, -1, GETDATE())),
                MONTH(DATEADD(DAY, -1, GETDATE())),
                1
            )
            THEN CAST(
                monthly.SmartPortfolio_FAs * 1.0
                / DAY(DATEADD(DAY, -1, GETDATE()))
                * DAY(EOMONTH(monthly.MonthStart))
                AS DECIMAL(18,0)
            )
            ELSE monthly.SmartPortfolio_FAs
        END AS [Smart Portfolio],

        CASE
            WHEN monthly.MonthStart = DATEFROMPARTS(
                YEAR(DATEADD(DAY, -1, GETDATE())),
                MONTH(DATEADD(DAY, -1, GETDATE())),
                1
            )
            THEN CAST(
                monthly.Crypto_FAs * 1.0
                / DAY(DATEADD(DAY, -1, GETDATE()))
                * DAY(EOMONTH(monthly.MonthStart))
                AS DECIMAL(18,0)
            )
            ELSE monthly.Crypto_FAs
        END AS Crypto,

        CASE
            WHEN monthly.MonthStart = DATEFROMPARTS(
                YEAR(DATEADD(DAY, -1, GETDATE())),
                MONTH(DATEADD(DAY, -1, GETDATE())),
                1
            )
            THEN CAST(
                monthly.FXComIndi_FAs * 1.0
                / DAY(DATEADD(DAY, -1, GETDATE()))
                * DAY(EOMONTH(monthly.MonthStart))
                AS DECIMAL(18,0)
            )
            ELSE monthly.FXComIndi_FAs
        END AS [FX/Com/Indi],

        CASE
            WHEN monthly.MonthStart = DATEFROMPARTS(
                YEAR(DATEADD(DAY, -1, GETDATE())),
                MONTH(DATEADD(DAY, -1, GETDATE())),
                1
            )
            THEN CAST(
                monthly.StocksETFs_FAs * 1.0
                / DAY(DATEADD(DAY, -1, GETDATE()))
                * DAY(EOMONTH(monthly.MonthStart))
                AS DECIMAL(18,0)
            )
            ELSE monthly.StocksETFs_FAs
        END AS [Stocks/ETFs],

        CASE
            WHEN monthly.MonthStart = DATEFROMPARTS(
                YEAR(DATEADD(DAY, -1, GETDATE())),
                MONTH(DATEADD(DAY, -1, GETDATE())),
                1
            )
            THEN CAST(
                monthly.Total_FAs * 1.0
                / DAY(DATEADD(DAY, -1, GETDATE()))
                * DAY(EOMONTH(monthly.MonthStart))
                AS DECIMAL(18,0)
            )
            ELSE monthly.Total_FAs
        END AS [Total FAs]

    FROM (
        SELECT
            DATEFROMPARTS(YEAR(base.EventDate), MONTH(base.EventDate), 1) AS MonthStart,
            base.Region,
            base.Country,
            SUM(CASE WHEN base.ActionType = 'Copy' THEN 1 ELSE 0 END) AS Copy_FAs,
            SUM(CASE WHEN base.ActionType = 'Smart Portfolio' THEN 1 ELSE 0 END) AS SmartPortfolio_FAs,
            SUM(CASE WHEN base.ActionType = 'Crypto' THEN 1 ELSE 0 END) AS Crypto_FAs,
            SUM(CASE WHEN base.ActionType = 'FX/Com/Indi' THEN 1 ELSE 0 END) AS FXComIndi_FAs,
            SUM(CASE WHEN base.ActionType = 'Stocks/ETFs' THEN 1 ELSE 0 END) AS StocksETFs_FAs,
            COUNT(DISTINCT base.CID) AS Total_FAs
        FROM (
            SELECT
                CAST(f5.FirstActionDate AS DATE) AS EventDate,
                dc1.MarketingRegionManualName AS Region,
                dc1.Name AS Country,
                CASE
                    WHEN f5.FirstAction = 'Copy' THEN 'Copy'
                    WHEN f5.FirstAction = 'Copy Fund' THEN 'Smart Portfolio'
                    WHEN f5.FirstAction = 'Crypto' THEN 'Crypto'
                    WHEN f5.FirstAction = 'FX/Commodities/Indices' THEN 'FX/Com/Indi'
                    WHEN f5.FirstAction = 'Stocks/ETFs' THEN 'Stocks/ETFs'
                    ELSE 'Other'
                END AS ActionType,
                f5.CID
            FROM BI_DB_dbo.[BI_DB_First5Actions] f5
            JOIN DWH_dbo.Dim_Customer dc
                ON dc.RealCID = f5.CID
            JOIN DWH_dbo.Dim_Country dc1
                ON dc.CountryID = dc1.CountryID
            WHERE f5.FirstActionDate >= '20250101'
        ) base
        GROUP BY
            DATEFROMPARTS(YEAR(base.EventDate), MONTH(base.EventDate), 1),
            base.Region,
            base.Country
    ) monthly
) calc