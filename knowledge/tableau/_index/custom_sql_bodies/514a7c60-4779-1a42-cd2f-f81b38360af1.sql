SELECT
    CAST(<[Parameters].[Parameter 1]> AS DATE) AS 'Date',
    'Data1 Client Data' AS DataSource,
    ISINCode,
    InstrumentID,
    InstrumentDisplayName,
	CID,
	PositionID,
    SUM(AmountInUnitsDecimal) AS AmountInUnitsDecimal,
    SUM(NOP) AS NOP,
    SUM(Amount) AS Amount,
    SUM(PositionPnL) AS PositionPnL,
    SUM(ISNULL(Amount, 0) + ISNULL(PositionPnL, 0)) AS Equity
FROM (
    SELECT  
        p.*, fsc.IsCreditReportValidCB, fsc.IsValidCustomer
    FROM (
        SELECT 
            bdppl.*, di.ISINCode, di.InstrumentDisplayName
        FROM
            BI_DB_dbo.BI_DB_PositionPnL bdppl
            JOIN DWH_dbo.Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5, 6)
        WHERE
            DateID =CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))
			AND bdppl.Date = CAST(<[Parameters].[Parameter 1]> AS DATE) 
            AND bdppl.IsSettled = 1
    ) p
    JOIN (
        SELECT
            fsc.RealCID, fsc.IsCreditReportValidCB, fsc.IsValidCustomer, fsc.RegulationID
        FROM
            DWH_dbo.Fact_SnapshotCustomer fsc
            JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND CONVERT(INT, CONVERT(VARCHAR(8), REPLACE(CAST(<[Parameters].[Parameter 1]> AS DATE), '-', ''), 112))  BETWEEN dr.FromDateID AND dr.ToDateID
        WHERE
            fsc.RegulationID = 2 AND fsc.IsCreditReportValidCB = 1 AND fsc.IsValidCustomer = 1
    ) fsc
    ON fsc.RealCID = p.CID
) posFCA
WHERE
    IsCreditReportValidCB = 1
GROUP BY
    ISINCode,
    InstrumentID,
    InstrumentDisplayName,
	CID,
	PositionID