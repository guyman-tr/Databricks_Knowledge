SELECT di.InstrumentDisplayName,
       bdppl.DateID,
       COUNT(bdppl.PositionID) AS 'Positions',
	   COUNT(DISTINCT bdppl.CID) AS 'UniqueCustomers',

	   SUM(bdppl.NOP) AS 'NOP'
FROM BI_DB..BI_DB_PositionPnL bdppl
INNER JOIN DWH..Dim_Customer  fsc ON bdppl.CID=fsc.RealCID AND fsc.CountryID=79 AND fsc.IsValidCustomer=1
--INNER JOIN DWH..Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND bdppl.DateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH..Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID=10
WHERE bdppl.DateID=CONVERT(CHAR(8), DATEADD(DAY,-1,GETDATE()),112)	 AND bdppl.IsSettled=1
GROUP BY di.InstrumentDisplayName,bdppl.DateID