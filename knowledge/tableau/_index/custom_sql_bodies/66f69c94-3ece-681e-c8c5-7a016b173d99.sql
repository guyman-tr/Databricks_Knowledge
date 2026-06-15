SELECT di.InstrumentID
	  ,dp.CID
      ,dp.OpenOccurred
	  ,dp.CloseOccurred
	  ,DATEDIFF(HOUR,dp.OpenOccurred,GETDATE())AS 'Duration_IN_Hours'
	  ,di.InstrumentDisplayName
	  ,di.InstrumentType
	  ,dp.PositionID
	  ,dp.Amount AS 'Invested_Amount'
	  ,dp.PnLInDollars AS 'P&L'
	  ,ISNULL(dp.IsPartialCloseChild,0) AS IsPartialCloseChild
	  ,ISNULL(dp.IsPartialCloseParent,0) AS IsPartialCloseParent
	  ,CASE WHEN ISNULL(dp.MirrorID,0)=0 THEN 'Manual' ELSE 'Copy' END AS 'CopyIND'
	  ,CASE WHEN ISNULL(dp.IsSettled,0)=0 THEN 'CFD' ELSE 'Real' END AS  'Settlement_Type'
	  ,'Currently_Opened' AS 'Opened_Closed'
FROM DWH_dbo.Dim_Position dp
INNER JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID

WHERE dp.CID=<[Parameters].[Parameter 1]> AND dp.OpenDateID>= cast(convert(varchar(8),DATEADD(month,-3,GETDATE()),112) as int)  AND dp.CloseDateID=0 
UNION
SELECT di.InstrumentID
	  ,dp.CID
	  ,dp.OpenOccurred
	  ,dp.CloseOccurred
	  ,DATEDIFF(HOUR,dp.OpenOccurred,dp.CloseOccurred) AS 'Duration_IN_Hours'
	  ,di.InstrumentDisplayName
	  ,di.InstrumentType
	  ,dp.PositionID
	  ,dp.Amount AS 'Invested_Amount'
	  ,dp.NetProfit AS PNL
	  ,ISNULL(dp.IsPartialCloseChild,0) AS IsPartialCloseChild
	  ,ISNULL(dp.IsPartialCloseParent,0) AS IsPartialCloseParent
	  ,CASE WHEN ISNULL(dp.MirrorID,0)=0 THEN 'Manual' ELSE 'Copy' END AS 'CopyIND'
	  ,CASE WHEN ISNULL(dp.IsSettled,0)=0 THEN 'CFD' ELSE 'Real' END AS  'Settlement_Type'
	  ,'Closed' AS 'Opened_Closed'
FROM DWH_dbo.Dim_Position dp
INNER JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
WHERE dp.CID=<[Parameters].[Parameter 1]> AND dp.CloseDateID>= cast(convert(varchar(8),DATEADD(month,-3,GETDATE()),112) as int)
	 -- AND dp.CloseDateID>0