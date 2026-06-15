SELECT bdppl.Date
	, di.InstrumentType
	, sum(bdppl.NOP) AS TotalNOP
	, sum(CASE WHEN bdppl.IsBuy = 1 THEN bdppl.NOP ELSE - bdppl.NOP end) AS TotalNotional
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
	JOIN DWH_dbo.Dim_Instrument di
		ON bdppl.InstrumentID = di.InstrumentID
	JOIN DWH_dbo.Dim_Customer dc
		ON bdppl.CID = dc.RealCID AND dc.IsValidCustomer = 1
WHERE bdppl.DateID >= CAST(FORMAT(CAST(getdate()-8 AS DATE),'yyyyMMdd') as INT) 
GROUP BY bdppl.Date, di.InstrumentType