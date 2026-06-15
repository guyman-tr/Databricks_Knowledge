SELECT di.Symbol,
       dc.IsCreditReportValidCB,
       CASE WHEN dcpr.ClosePositionReasonID = 22 THEN 'Transferred Out' ELSE 'Other Close Reason' END AS ClosePositionReason,
       SUM(ISNULL(dp.AmountInUnitsDecimal, 0)) Units,
       SUM(ISNULL(dp.Amount, 0)+ISNULL(dp.NetProfit, 0)) AS 'Value',
	   fsc.DltStatusID
	   ,CASE WHEN dc.TanganyStatusID = 1 THEN 'Pending' 
			 WHEN dc.TanganyStatusID = 2 THEN 'Internal'
			 WHEN dc.TanganyStatusID = 3 THEN 'Customer'
			  WHEN dc.TanganyStatusID = 4 THEN 'Inactive'
			  WHEN dc.TanganyStatusID = 5 THEN 'MicaCustomer'
			  ELSE 'Error' END AS TanganyStatus
FROM DWH_dbo.Dim_Position dp
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
ON dp.CID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Range dr
ON fsc.DateRangeID = dr.DateRangeID
AND CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT) BETWEEN dr.FromDateID AND dr.ToDateID
--AND 20241101 BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH_dbo.Dim_Customer dc 
ON dp.CID = dc.RealCID
AND dc.TanganyStatusID IS NOT NULL
INNER JOIN DWH_dbo.Dim_Instrument di 
ON dp.InstrumentID = di.InstrumentID
LEFT JOIN DWH_dbo.Dim_ClosePositionReason dcpr 
ON dp.ClosePositionReasonID = dcpr.ClosePositionReasonID
WHERE --dp.CloseDateID>>=20240101
     (dp.CloseDateID BETWEEN 
	  CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT) AND 
	  CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT))
     AND dp.IsSettled = 1
     AND di.InstrumentTypeID = 10

GROUP BY di.Symbol,
         CASE WHEN dcpr.ClosePositionReasonID=22 THEN 'Transferred Out' ELSE 'Other Close Reason' END,
         dc.IsCreditReportValidCB,
		 fsc.DltStatusID
		 ,CASE WHEN dc.TanganyStatusID = 1 THEN 'Pending' 
			 WHEN dc.TanganyStatusID = 2 THEN 'Internal'
			 WHEN dc.TanganyStatusID = 3 THEN 'Customer'
			  WHEN dc.TanganyStatusID = 4 THEN 'Inactive'
			  WHEN dc.TanganyStatusID = 5 THEN 'MicaCustomer'
			  ELSE 'Error' END