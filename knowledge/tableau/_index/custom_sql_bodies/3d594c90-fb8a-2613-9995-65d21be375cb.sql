SELECT bdtfr.ErrorCode,
    bdtfr.Regulation,
    bdtfr.InstrumentID,
    bdtfr.Copy_Manual, 
    bdtfr.Type, 
    SUM(CASE WHEN bdtfr.Date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) THEN bdtfr.Orders_Positions ELSE 0 END) AS Yesterday,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) THEN bdtfr.Orders_Positions ELSE 0 END) AS WeekToDate,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(DAY, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE)) THEN bdtfr.Orders_Positions ELSE 0 END) AS MonthToDate,
    SUM(CASE WHEN bdtfr.Date >= DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0) THEN bdtfr.Orders_Positions ELSE 0 END) AS QuarterToDate
FROM BI_DB_dbo.BI_DB_Trading_Failures_Risk bdtfr
GROUP BY 
    bdtfr.ErrorCode,
    bdtfr.Regulation,
    bdtfr.InstrumentID,
    bdtfr.Copy_Manual, 
    bdtfr.Type