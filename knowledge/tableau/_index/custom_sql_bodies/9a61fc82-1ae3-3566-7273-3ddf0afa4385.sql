SELECT bp.*
, di.InstrumentType
, di.Name
, di.InstrumentDisplayName
, di.Exchange
FROM [BI_DB_dbo].[BI_DB_Finance_Panel_Reports] bp
LEFT JOIN [DWH_dbo].[Dim_Instrument] di 
    ON bp.InstrumentID = di.InstrumentID
WHERE bp.DateID >= CONVERT(INT, CONVERT(CHAR(8), DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0), 112))
  AND bp.DateID <  CONVERT(INT, CONVERT(CHAR(8), DATEFROMPARTS(YEAR(DATEADD(MONTH,-1,GETDATE())), MONTH(DATEADD(MONTH,-1,GETDATE())), 16), 112))