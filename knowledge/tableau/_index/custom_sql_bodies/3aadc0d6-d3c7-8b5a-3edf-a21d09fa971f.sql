SELECT a.CID
      ,a.Regulation
      ,a.IsDLT
	 ,[Label]
	  ,a.IsBuy
	  ,SUM(CASE WHEN a.IsSettled = 1 THEN NOP ELSE 0 END) AS Real_NOP
	  ,SUM(CASE WHEN a.IsSettled = 0 THEN NOP ELSE 0 END) AS CFD_NOP
	  ,SUM(a.NOP) AS Total_NOP
	  ,SUM(CASE WHEN a.IsSettled = 1 THEN a.Amount ELSE 0 END) AS Real_InvestedAmount
	  ,SUM(CASE WHEN a.IsSettled = 0 THEN a.Amount ELSE 0 END) AS CFD_InvestedAmount
	  ,SUM(a.Amount) AS Total_InvestedAmount
      ,SUM(CASE WHEN a.IsSettled = 1 THEN (a.Amount + a.PositionPnL) ELSE 0 END)  AS Real_Equity
	  ,SUM(CASE WHEN a.IsSettled = 0 THEN (a.Amount + a.PositionPnL) ELSE 0 END) AS CFD_Equity
	  ,SUM(a.Amount + a.PositionPnL) AS Total_Equity
          ,SUM(CASE WHEN a.IsSettled = 1 THEN a.Units ELSE 0 END) Units
FROM
(
SELECT  pp.CID 
	   ,pp.IsSettled
	   ,pp.AmountInUnitsDecimal Units
	   ,pp.Amount
	   ,pp.IsBuy
	   ,dr1.Name AS Regulation
	   ,dl.Name AS [Label]
	   ,pp.NOP
	   ,pp.PositionPnL
	   ,pp.PositionID
	   ,di.InstrumentDisplayName
           ,case when sc.DltStatusID = 4 then 1 else 0 end as IsDLT
FROM BI_DB_dbo.BI_DB_PositionPnL pp
JOIN DWH_dbo.Fact_SnapshotCustomer sc 
ON sc.RealCID = pp.CID 
JOIN DWH_dbo.Dim_Range dr
ON dr.DateRangeID = sc.DateRangeID
JOIN DWH_dbo.Dim_Regulation dr1
ON dr1.DWHRegulationID = sc.RegulationID
JOIN DWH_dbo.Dim_Label dl
ON dl.LabelID = sc.LabelID
JOIN DWH_dbo.Dim_Instrument di
ON di.InstrumentID = pp.InstrumentID
WHERE pp.DateID = <[Parameters].[Parameter 1]>
AND pp.DateID >= dr.FromDateID
AND pp.DateID < dr.ToDateID
AND di.InstrumentTypeID = 10
AND sc.IsValidCustomer = 1
) a
GROUP BY a.CID
      ,a.Regulation
	,[Label]
	    ,a.IsBuy
        ,a.IsDLT