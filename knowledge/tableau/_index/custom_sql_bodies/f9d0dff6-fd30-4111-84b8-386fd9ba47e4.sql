SELECT dd.FullDate
      ,a.CID
		,a.Islamic
		,b.FullCommissions
		,a.InstrumentID
		,a.InstrumentType
FROM [DWH_dbo].[Dim_Date]  dd
LEFT JOIN (SELECT Date, CID, InstrumentID, InstrumentType, SUM(Islamic) Islamic FROM [Dealing_dbo].[Dealing_Rollover_Assurance] GROUP BY Date,CID, InstrumentID, InstrumentType)a
ON dd.FullDate=a.Date
LEFT JOIN (SELECT FullDate,RealCID, InstrumentID, InstrumentType, SUM(FullCommissions) FullCommissions FROM [BI_DB_dbo].[BI_DB_DailyCommisionReport] GROUP BY FullDate,RealCID, InstrumentID, InstrumentType) b
ON dd.FullDate=b.FullDate AND a.CID=b.RealCID AND a.InstrumentID = b.InstrumentID
WHERE YEAR(dd.FullDate) >= 2022
AND dd.FullDate < CAST(GETDATE() AS DATE)