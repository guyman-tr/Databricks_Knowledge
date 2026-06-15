SELECT
    CAST(<[Parameters].[Parameter 1]> AS DATE) AS 'Date',
    'Data2 UK Tableau' AS DataSource2,
    d2.ISINCode,
    d2.InstrumentID,
    d2.InstrumentDisplayName,
    SUM(d2.AmountInUnitsDecimal) AS 'AmountInUnitsDecimal_2',
    SUM(d2.Equity) AS 'Equity_2',
    'Data3 EU Tableau' AS DataSource3,
    --d3.ISINCode AS 'Data3_ISINCode',
    --d3.InstrumentID AS 'Data3_InstrumentID',
    --d3.InstrumentDisplayName AS 'Data3_InstrumentDisplayName',
    SUM(d3.AmountInUnitsDecimal) AS 'AmountInUnitsDecimal_3',
    SUM(d3.Equity) AS 'Equity_3',
    ISNULL(SUM(d3.AmountInUnitsDecimal), 0) - ISNULL(SUM(d2.AmountInUnitsDecimal), 0) AS 'Diff_AmountInUnitsDecimal',
    ISNULL(SUM(d3.Equity), 0) - ISNULL(SUM(d2.Equity), 0) AS 'Diff_Equity'
FROM
    (
        SELECT
            a.ISINCode,
            a.InstrumentID,
            a.InstrumentDisplayName,
            SUM(a.AmountInUnitsDecimal) AS AmountInUnitsDecimal,
            SUM(ISNULL(a.Amount, 0) + ISNULL(a.PositionPnL, 0)) AS Equity
        FROM
            (
                SELECT
                    ia.*,
                    di.ISINCode,
                    di.InstrumentDisplayName,
                    CASE
                        WHEN HedgeServerID IN (20, 25, 5000) THEN 'Unknown'
                        WHEN HedgeServerID = 24 THEN 'FXCM'
                        WHEN HedgeServerID = 101 THEN 'IG'
                        -- Add more WHEN conditions for other HedgeServerID values
                        ELSE 'Unknown'
                    END AS LiquidityProvider
                FROM
                    [BI_DB_dbo].[BI_DB_PositionPnL_UK_Instrument_Agg] ia
                    JOIN DWH_dbo.Dim_Instrument di ON ia.InstrumentID = di.InstrumentID
                WHERE
                    DateID = CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
                    AND ia.IsCreditReportValidCB = 1
                    AND ia.IsValidCustomer = 1
            ) a
            JOIN
            (
                SELECT DISTINCT
                    bdppl.InstrumentID,
                    bdppl.USD_CR
                FROM
                    BI_DB_dbo.BI_DB_PositionPnL bdppl
                    JOIN DWH_dbo.Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5, 6)
                WHERE
                    bdppl.DateID = CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
					AND bdppl.Date = CAST(<[Parameters].[Parameter 1]> AS DATE)
                    AND bdppl.IsSettled = 1
            ) b ON a.InstrumentID = b.InstrumentID
            JOIN DWH_dbo.Dim_Instrument di ON a.InstrumentID = di.InstrumentID
            JOIN
            (
                SELECT
                    ps.InstrumentID,
                    ps.Bid
                FROM
                    DWH_dbo.Fact_CurrencyPriceWithSplit ps
                WHERE
                    ps.OccurredDateID = CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
            ) c ON a.InstrumentID = c.InstrumentID
        GROUP BY
            a.ISINCode,
            a.InstrumentID,
            a.InstrumentDisplayName
    ) d2
FULL OUTER JOIN
    (
        SELECT
            a.ISINCode,
            a.InstrumentID,
            a.InstrumentDisplayName,
            SUM(a.AmountInUnitsDecimal) AS AmountInUnitsDecimal,
            SUM(ISNULL(a.Amount, 0) + ISNULL(a.PositionPnL, 0)) AS Equity
        FROM
            (
                SELECT
                    ia.*,
                    di.ISINCode,
                    di.InstrumentDisplayName,
                    CASE
                        WHEN HedgeServerID IN (20, 25, 5000) THEN 'Unknown'
                        WHEN HedgeServerID = 24 THEN 'FXCM'
                        WHEN HedgeServerID = 101 THEN 'IG'
                        -- Add more WHEN conditions for other HedgeServerID values
                        ELSE 'Unknown'
                    END AS LiquidityProvider
                FROM
                    [BI_DB_dbo].[BI_DB_PositionPnL_EU_Custody_Instrument_Agg] ia
                    JOIN DWH_dbo.Dim_Instrument di ON ia.InstrumentID = di.InstrumentID
                WHERE
                    DateID = CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
                    AND ia.IsCreditReportValidCB = 1
                    AND ia.IsValidCustomer = 1
            ) a
            JOIN
            (
                SELECT DISTINCT
                    bdppl.InstrumentID,
                    bdppl.USD_CR
                FROM
                    BI_DB_dbo.BI_DB_PositionPnL bdppl
                    JOIN DWH_dbo.Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5, 6)
                WHERE
                    bdppl.DateID = CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
					AND bdppl.Date = CAST(<[Parameters].[Parameter 1]> AS DATE)
                    AND bdppl.IsSettled = 1
            ) b ON a.InstrumentID = b.InstrumentID
            JOIN DWH_dbo.Dim_Instrument di ON a.InstrumentID = di.InstrumentID
            JOIN
            (
                SELECT
                    ps.InstrumentID,
                    ps.Bid
                FROM
                    DWH_dbo.Fact_CurrencyPriceWithSplit ps
                WHERE
                    ps.OccurredDateID = CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
            ) c ON a.InstrumentID = c.InstrumentID
        GROUP BY
            a.ISINCode,
            a.InstrumentID,
            a.InstrumentDisplayName
    ) d3 ON d2.InstrumentID = d3.InstrumentID
GROUP BY
    d2.ISINCode,
    d2.InstrumentID,
    d2.InstrumentDisplayName,
    d3.ISINCode,
    d3.InstrumentID,
    d3.InstrumentDisplayName