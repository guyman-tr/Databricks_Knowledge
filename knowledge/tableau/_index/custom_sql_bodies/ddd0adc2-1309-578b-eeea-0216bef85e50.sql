SELECT 'HBC' AS HedgingType,
bdtfr.ActionType,
bdtfr.Regulation,
    SUM(CASE WHEN bdtfr.Date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) THEN bdtfr.Compensation ELSE 0 END) AS Yesterday_Compensation,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) THEN bdtfr.Compensation ELSE 0 END) AS WeekToDate_Compensation,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE)) THEN bdtfr.Compensation ELSE 0 END) AS MonthToDate_Compensation,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0) THEN bdtfr.Compensation ELSE 0 END) AS QuarterToDate_Compensation
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_HBC bdtfr
WHERE bdtfr.InstrumentTypeID IN (5,6)
AND bdtfr.WithinFirst5Minutes_MarketHours=0
AND bdtfr.ActionType<>'Limit Order'
GROUP BY bdtfr.ActionType, 
bdtfr.Regulation

UNION ALL

SELECT 'CBH' AS HedgingType,
bdtfr.ActionType,
bdtfr.Regulation,
    SUM(CASE WHEN bdtfr.Date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) THEN bdtfr.Compensation ELSE 0 END) AS Yesterday_Compensation,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) THEN bdtfr.Compensation ELSE 0 END) AS WeekToDate_Compensation,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE)) THEN bdtfr.Compensation ELSE 0 END) AS MonthToDate_Compensation,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0) THEN bdtfr.Compensation ELSE 0 END) AS QuarterToDate_Compensation
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_CBH bdtfr
WHERE bdtfr.InstrumentTypeID IN (5,6)
AND bdtfr.WithinFirst5Minutes_MarketHours=0
AND bdtfr.ActionType<>'Limit Order'
GROUP BY bdtfr.ActionType,
bdtfr.Regulation