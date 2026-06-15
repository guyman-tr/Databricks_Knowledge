SELECT dd.FullDate ,
CASE WHEN bdppl.IsSettled=1 AND di.InstrumentTypeID=10 THEN 'Real Crypto'	
	 WHEN bdppl.IsSettled=1 AND di.InstrumentTypeID IN (5,6) THEN 'Real Stocks'
	 WHEN bdppl.IsSettled=0 THEN 'CFD'
	 ELSE 'Else' END AS 'AssetType',
	 
sum(CASE WHEN bdppl.MirrorID<>0 THEN bdppl.Amount+bdppl.PositionPnL ELSE 0 END) AS 'Invested in copy'	
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl	
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON bdppl.CID=fsc.RealCID	
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND bdppl.DateID BETWEEN dr.FromDateID AND dr.ToDateID	
JOIN DWH_dbo.Dim_Instrument di ON bdppl.InstrumentID = di.InstrumentID	
JOIN (SELECT DISTINCT dd.DateKey,dd.FullDate FROM DWH_dbo.Dim_Date dd WHERE DATEADD(qq,DATEDIFF(qq,-1,FullDate),-1)=dd.FullDate)dd ON dd.DateKey=bdppl.DateID
WHERE bdppl.DateID>=20240101-->=20240101	
AND fsc.IsCreditReportValidCB=1	
AND fsc.RegulationID=11	
GROUP BY CASE WHEN bdppl.IsSettled=1 AND di.InstrumentTypeID=10 THEN 'Real Crypto'	
	 WHEN bdppl.IsSettled=1 AND di.InstrumentTypeID IN (5,6) THEN 'Real Stocks'
	 WHEN bdppl.IsSettled=0 THEN 'CFD'
	 ELSE 'Else' END,
	 dd.FullDate