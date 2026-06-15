SELECT 
    CAST(<[Parameters].[Parameter 1]> AS DATE) AS 'Date',
    'Data3 EU Tableau' AS DataSource,
    b.ISINCode,
    b.InstrumentID,
    b.InstrumentDisplayName,
	b.CID,
	b.HashedPositionID,
    SUM(b.AmountInUnitsDecimal) AS AmountInUnitsDecimal,
    SUM(b.NOP) AS NOP,
    SUM(b.Amount) AS Amount,
    SUM(b.PositionPnL) AS PositionPnL,
    SUM(ISNULL(b.Amount, 0) + ISNULL(b.PositionPnL, 0)) AS Equity
FROM 


(
    SELECT 
        bdppl.InstrumentID,
        bdppl.USD_CR,
		CASE
            WHEN HedgeServerID IN (20, 25, 5000) THEN 'Unknown'
            WHEN HedgeServerID = 24 THEN 'FXCM'
            WHEN HedgeServerID = 101 THEN 'IG'
            WHEN HedgeServerID = 102 THEN 'Apex'
            -- Add more WHEN conditions for other HedgeServerID values
            ELSE 'Unknown'
        END AS LiquidityProvider,
		di.ISINCode,
		di.InstrumentDisplayName,
		bdppl.CID,
		bdppl.Amount,
		bdppl.PositionPnL,
		bdppl.NOP,
		bdppl.AmountInUnitsDecimal,
		CONVERT(NVARCHAR(40), HASHBYTES('SHA1', CONVERT(NVARCHAR(MAX), PositionID)), 2) AS HashedPositionID
		
    FROM
        BI_DB_dbo.BI_DB_PositionPnL bdppl
        JOIN DWH_dbo.Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5, 6)
    WHERE
        bdppl.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
		--AND bdppl.Date =CAST(<[Parameters].[Parameter 1]> AS DATE)*/
        AND bdppl.IsSettled = 1
) b --ON a.InstrumentID = b.InstrumentID
JOIN (SELECT fsc.RealCID, fsc.IsCreditReportValidCB, fsc.IsValidCustomer, fsc.RegulationID
FROM DWH_dbo.Fact_SnapshotCustomer fsc
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) BETWEEN dr.FromDateID AND dr.ToDateID
	  WHERE fsc.RegulationID = 2
	  AND fsc.IsCreditReportValidCB=1 
	  AND fsc.IsValidCustomer = 1)fsc ON fsc.RealCID=b.CID
JOIN DWH_dbo.Dim_Instrument di ON b.InstrumentID = di.InstrumentID
JOIN (
    SELECT
        ps.InstrumentID,
        ps.Bid
    FROM
        DWH_dbo.Fact_CurrencyPriceWithSplit ps
    WHERE
        ps.OccurredDateID =CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
) c ON b.InstrumentID = c.InstrumentID
GROUP BY
    b.ISINCode,
    b.InstrumentID,
    b.InstrumentDisplayName,
	b.CID,
	b.HashedPositionID