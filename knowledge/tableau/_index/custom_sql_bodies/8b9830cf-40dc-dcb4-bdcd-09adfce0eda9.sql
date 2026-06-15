SELECT sum(AmountInUnitsDecimal)Units,  'PositionPnL' AS 'Source', bdppl.Date , bdppl.HedgeServerID, bdppl.InstrumentID
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
JOIN DWH_dbo.Dim_Instrument di
	ON bdppl.InstrumentID = di.InstrumentID
WHERE DateID between 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and 
CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND di.InstrumentTypeID IN (5,6)
 GROUP BY bdppl.Date , bdppl.HedgeServerID, bdppl.InstrumentID

 UNION ALL 

SELECT sum(EOD_Units)Units, 'SettlementReport' AS 'Source' ,  Date ,HedgeServerID, InstrumentID
FROM BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025
WHERE DateID between 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and 
CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
AND ClientHoldings ='Client_Holdings'
GROUP BY Date,HedgeServerID, InstrumentID
UNION all
SELECT sum(bdftvp.TP_UnitsTotal)Units   ,'eToro_vs_Positions' AS 'Source' ,  Date ,HedgeServerID, InstrumentID
FROM BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions bdftvp
WHERE DateID between 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and 
CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
GROUP BY Date,HedgeServerID, InstrumentID