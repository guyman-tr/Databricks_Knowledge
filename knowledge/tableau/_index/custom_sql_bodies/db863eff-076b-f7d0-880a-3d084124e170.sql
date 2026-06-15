SELECT
    CAST(<[Parameters].[Parameter 1]> AS DATE) AS 'Date',
    'Data1 Client Data' AS DataSource1,
    d1.ISINCode
   ,d1.InstrumentID
   ,d1.InstrumentDisplayName
   ,d1.AmountInUnitsDecimal AS AmountInUnitsDecimal_1
   ,d1.Equity AS Equity_1
   ,'Data2 UK Tableau' AS DataSource2
   --,d2.ISINCode
   --,d2.InstrumentID
   --,d2.InstrumentDisplayName
   ,d2.AmountInUnitsDecimal AS AmountInUnitsDecimal_2
   ,d2.Equity AS Equity_2,
    ISNULL(d2.AmountInUnitsDecimal, 0) - ISNULL(d1.AmountInUnitsDecimal, 0) AS Diff_AmountInUnitsDecimal,
    ISNULL(d2.Equity, 0) - ISNULL(d1.Equity, 0) AS Diff_Equity
FROM
    (
        SELECT
            ISINCode,
            InstrumentID,
            InstrumentDisplayName,
            SUM(AmountInUnitsDecimal) AS AmountInUnitsDecimal,
            SUM(ISNULL(Amount, 0) + ISNULL(PositionPnL, 0)) AS Equity
        FROM
            (
                SELECT
                    p.*,
                    fsc.IsCreditReportValidCB,
                    fsc.IsValidCustomer
                FROM
                    (
                        SELECT
                            bdppl.*,
                            di.ISINCode,
                            di.InstrumentDisplayName
                        FROM
                            BI_DB_dbo.BI_DB_PositionPnL bdppl
                            JOIN DWH_dbo.Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5, 6)
                        WHERE
                            DateID = CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
							AND bdppl.Date = CAST(<[Parameters].[Parameter 1]> AS DATE)
                            AND bdppl.IsSettled = 1
                    ) p
                    JOIN
                    (
                        SELECT
                            fsc.RealCID,
                            fsc.IsCreditReportValidCB,
                            fsc.IsValidCustomer,
                            fsc.RegulationID
                        FROM
                            DWH_dbo.Fact_SnapshotCustomer fsc
                            JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112)) BETWEEN dr.FromDateID AND dr.ToDateID
                        WHERE
                            fsc.RegulationID = 2
                            AND fsc.IsCreditReportValidCB = 1
                            AND fsc.IsValidCustomer = 1
                    ) fsc ON fsc.RealCID = p.CID
            ) posFCA
        WHERE
            IsCreditReportValidCB = 1
        GROUP BY
            ISINCode,
            InstrumentID,
            InstrumentDisplayName
    ) d1
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
                        -- Additional WHEN conditions...
                        ELSE 'Unknown'
                    END AS LiquidityProvider
                FROM
                    BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg ia
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
    ) d2 ON d1.InstrumentID = d2.InstrumentID