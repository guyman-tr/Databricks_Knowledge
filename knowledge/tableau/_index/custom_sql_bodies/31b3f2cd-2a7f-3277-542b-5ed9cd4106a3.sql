SELECT
    CAST(<[Parameters].[Parameter 1]> AS DATE) AS 'Date',
    'Data2 UK Tableau' AS DataSource,
    a.ISINCode,
    a.InstrumentID,
    a.InstrumentDisplayName,
    SUM(a.AmountInUnitsDecimal) AS AmountInUnitsDecimal,
    SUM(a.NOP) AS NOP,
    SUM(a.Amount) AS Amount,
    SUM(a.PositionPnL) AS PositionPnL,
    SUM(ISNULL(a.Amount, 0) + ISNULL(a.PositionPnL, 0)) AS Equity
FROM (
    SELECT
        ia.*,
        di.ISINCode,
        di.InstrumentDisplayName,
        CASE
            WHEN HedgeServerID IN (20, 25, 5000) THEN 'Unknown'
            WHEN HedgeServerID = 24 THEN 'FXCM'
            WHEN HedgeServerID = 101 THEN 'IG'
            WHEN HedgeServerID = 102 THEN 'Apex'
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
JOIN (
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
JOIN (
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