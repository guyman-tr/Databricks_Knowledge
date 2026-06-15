SELECT YEAR(Date) * 100 + MONTH(Date) AS Year_Month
,EOMONTH (Date) AS 'Date'	
,bddztsn.InstrumentType
,SUM(bddztsn.OpenPositions) /COUNT(DISTINCT Date)  AvgOpenPosition
,CAST(GETDATE() AS DATE) AS LoadDate

FROM BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW bddztsn
WHERE Date>='20220101'
AND bddztsn.Date<=CAST(GETDATE()-1 AS DATE)
AND bddztsn.Leverage>1
AND bddztsn.IsCFD=1
GROUP BY  YEAR(Date) * 100 + MONTH(Date)
,EOMONTH (Date)
,bddztsn.InstrumentType