SELECT fca.RealCID, fca.DateID, CAST(fca.Occurred AS DATE) Date, dcr.Name AS CompensationReason,  SUM(fca.Amount) AS Amount
FROM DWH_dbo.Fact_CustomerAction fca
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON fca.RealCID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_CompensationReason dcr
		ON fca.CompensationReasonID = dcr.CompensationReasonID
WHERE ActionTypeID = 36 AND fca.CompensationReasonID IN (45,60,62,63,64,65,66,67,68,69,70,71,72,75,76,78,79,81,82,83,84,85,86,87,88,89,92) 
AND fca.DateID = CAST(CONVERT(VARCHAR(10),CAST(<[Parameters].[Parameter 8]> as DATE), 112) AS INT)
AND fsc.RegulationID = 8
GROUP BY fca.RealCID, fca.DateID, dcr.Name ,CAST(fca.Occurred AS DATE)