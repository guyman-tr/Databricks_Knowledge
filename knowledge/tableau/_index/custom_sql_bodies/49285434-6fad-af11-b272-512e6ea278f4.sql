SELECT
	frtfbp.InstrumentID
  , frtfbp.DateID
  , di.Name AS InstrumentName
  , frtfbp.IsValidCustomer
  , frtfbp.IsCreditReportValidCB
  , frtfbp.TicketFeeByPercentAction
  , CASE WHEN frtfbp.IsSettled=1 THEN 'Real' ELSE 'CFD' END AS RealCFD
  , sum(frtfbp.TicketFeeByPercent) TicketFeeByPercent
 , CASE WHEN dc.TanganyStatusID = 1 THEN 'Pending'
		WHEN dc.TanganyStatusID = 2 THEN 'Internal'
		WHEN dc.TanganyStatusID = 3 THEN 'Customer'
		WHEN dc.TanganyStatusID = 4 THEN 'Inactive'
		WHEN dc.TanganyStatusID = 5 THEN 'MicaCustomer'
	ELSE 'NA' END AS TanganyStatus
  , CASE WHEN fsc.DltStatusID = 4 THEN 1 ELSE 0 END AS IsDLTUser
,  di.InstrumentType
FROM BI_DB_dbo.Function_Revenue_TicketFeeByPercent (CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT) , CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT), 0) frtfbp
JOIN DWH_dbo.Dim_Customer dc
	ON frtfbp.RealCID = dc.RealCID
JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON frtfbp.RealCID = fsc.RealCID
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND frtfbp.DateID BETWEEN dr.FromDateID AND dr.ToDateID
JOIN DWH_dbo.Dim_Instrument di
	ON frtfbp.InstrumentID = di.InstrumentID
GROUP BY 
	frtfbp.InstrumentID
  , di.Name
  , frtfbp.IsValidCustomer
  , frtfbp.IsCreditReportValidCB
  , frtfbp.TicketFeeByPercentAction
  , CASE WHEN frtfbp.IsSettled=1 THEN 'Real' ELSE 'CFD' END 
  , frtfbp.DateID
 , CASE WHEN dc.TanganyStatusID = 1 THEN 'Pending'
		WHEN dc.TanganyStatusID = 2 THEN 'Internal'
		WHEN dc.TanganyStatusID = 3 THEN 'Customer'
		WHEN dc.TanganyStatusID = 4 THEN 'Inactive'
		WHEN dc.TanganyStatusID = 5 THEN 'MicaCustomer'
	ELSE 'NA' END
  , CASE WHEN fsc.DltStatusID = 4 THEN 1 ELSE 0 END,  di.InstrumentType
-- ORDER BY frtfbp.TicketFeeByPercentAction