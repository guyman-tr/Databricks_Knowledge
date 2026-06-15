SELECT fca.RealCID
	, fsc.CountryID
	, CASE WHEN fsc.DltStatusID = 4 THEN 1 ELSE 0 END AS IsDLTUser
	, dc.TanganyStatusID
	, 'Open' AS ActionType 
	, sum(fca.Amount) AS InvestedAmount
	, dc.TanganyID
	, dc.DltID
FROM DWH_dbo.Fact_CustomerAction fca
	JOIN DWH_dbo.Dim_Instrument di
		ON fca.InstrumentID = di.InstrumentID AND di.InstrumentTypeID = 10
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON fca.RealCID = fsc.RealCID  AND fsc.DltStatusID = 4
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Customer dc
		ON fca.RealCID = dc.RealCID AND dc.TanganyStatusID IN (2,3)
WHERE fca.DateID between CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT)
AND fca.ActionTypeID IN (1,2,3,39)
AND fca.IsSettled = 1
GROUP BY 
	fca.RealCID
	, fsc.CountryID
	, CASE WHEN fsc.DltStatusID = 4 THEN 1 ELSE 0 END
	, dc.TanganyStatusID
	, dc.TanganyID
	, dc.DltID

UNION ALL 

SELECT fca.RealCID
	, fsc.CountryID
	, CASE WHEN fsc.DltStatusID = 4 THEN 1 ELSE 0 END AS IsDLTUser
	, dc.TanganyStatusID
	, 'Close' AS ActionType 
	, -1 * sum(fca.Amount) AS InvestedAmount
	, dc.TanganyID
	, dc.DltID
FROM DWH_dbo.Fact_CustomerAction fca
	JOIN DWH_dbo.Dim_Instrument di
		ON fca.InstrumentID = di.InstrumentID AND di.InstrumentTypeID = 10
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON fca.RealCID = fsc.RealCID AND fsc.DltStatusID = 4
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Customer dc
		ON fca.RealCID = dc.RealCID AND dc.TanganyStatusID IN (2,3)
WHERE fca.DateID between CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy)]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[ToDateID (copy 2)]> AS DATE),'yyyyMMdd') as INT)
AND fca.ActionTypeID IN (4,5,6,28,40)
AND fca.IsSettled = 1
GROUP BY 
	fca.RealCID
	, fsc.CountryID
	, CASE WHEN fsc.DltStatusID = 4 THEN 1 ELSE 0 END
	, dc.TanganyStatusID
	, dc.TanganyID
	, dc.DltID