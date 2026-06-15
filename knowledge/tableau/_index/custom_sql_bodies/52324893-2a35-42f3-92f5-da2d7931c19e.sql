SELECT CONVERT(date, CONVERT(char(8), fca.DateID)) as Date,
			fca.RealCID,
			fca.Amount AS 'Compensation Added',
			fsc.IsCreditReportValidCB,
			fca.PositionID,
			di.InstrumentType

	FROM DWH_dbo.Fact_CustomerAction fca
	INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc
	ON fca.RealCID = fsc.RealCID
	INNER JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Instrument di ON fca.InstrumentID = di.InstrumentID
	WHERE  fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
                              AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and fca.Amount >= 0 
	AND fca.ActionTypeID = 36 
	AND fca.CompensationReasonID = 120  
	and fsc.IsCreditReportValidCB = 1