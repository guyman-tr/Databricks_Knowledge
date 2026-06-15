SELECT
	a.*
	,b.HVAR
	,b.PnL
FROM BI_DB.dbo.DWH_RiskVAR_Majors a
 LEFT JOIN dbo.BI_DB_BBookBudgetLimits b
 ON (a.InstrumentName =  LEFT(b.InstrumentName,3)  AND b.InstrumentID = 500)
 OR a.InstrumentType = b.InstrumentID AND b.InstrumentID = 0 AND b.InstrumentName = 'Bbook - FX'