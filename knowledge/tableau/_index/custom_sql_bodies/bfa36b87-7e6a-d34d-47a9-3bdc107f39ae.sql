SELECT Year_Month
,[Date]
,InstrumentType
,InstrumentGroup
,SUM(TotalFullCommission)TotalFullCommission_TicketFees
,CAST(GETDATE() AS DATE) AS LoadDate
from
(SELECT YEAR(Occurred) * 100 + MONTH(Occurred) AS Year_Month
,EOMONTH (Occurred) AS 'Date'	 
,di.InstrumentType
,CASE
WHEN frfc.InstrumentTypeID  IN (10) THEN 'Crypto'
WHEN frfc.InstrumentTypeID  IN (4,5,6) THEN 'Equities'
ELSE InstrumentType
END AS InstrumentGroup
,SUM(ISNULL(frfc.TotalFullCommission,0)) TotalFullCommission
FROM BI_DB_dbo.Function_Revenue_FullCommissions(20220101, CAST(FORMAT( GETDATE()-1, 'yyyyMMdd') AS INT) , 1) frfc   
JOIN DWH_dbo.Dim_Instrument di                    
ON di.InstrumentID=frfc.InstrumentID   
GROUP BY YEAR(Occurred) * 100 + MONTH(Occurred) 
,EOMONTH (Occurred) 	 
,di.InstrumentType
,CASE
WHEN frfc.InstrumentTypeID  IN (10) THEN 'Crypto'
WHEN frfc.InstrumentTypeID  IN (4,5,6) THEN 'Equities'
ELSE InstrumentType
END
UNION ALL
SELECT LEFT(frtfb.DateID,6) AS Year_Month
,EOMONTH(CONVERT(DATE, CAST(DateID AS CHAR(8)))) 'Date'
,di.InstrumentType 
,CASE
WHEN frtfb.InstrumentTypeID  IN (10) THEN 'Crypto'
WHEN frtfb.InstrumentTypeID  IN (4,5,6) THEN 'Equities'
ELSE InstrumentType
END AS InstrumentGroup
,SUM(frtfb.Amount)'Trading_Fees'
FROM BI_DB_dbo.Function_Revenue_Trading_Fees_Breakdown (20220101, CAST(FORMAT( GETDATE()-1, 'yyyyMMdd') AS INT), 1) frtfb
JOIN DWH_dbo.Dim_Instrument di                    
ON di.InstrumentID=frtfb.InstrumentID 
WHERE TradingFeeName='TicketFee'
GROUP BY LEFT(frtfb.DateID,6)
,EOMONTH(CONVERT(DATE, CAST(DateID AS CHAR(8))))
,di.InstrumentType 
,CASE
WHEN frtfb.InstrumentTypeID  IN (10) THEN 'Crypto'
WHEN frtfb.InstrumentTypeID  IN (4,5,6) THEN 'Equities'
ELSE InstrumentType
END
 ) A
group BY  
Year_Month
,[Date]
,InstrumentType
,InstrumentGroup