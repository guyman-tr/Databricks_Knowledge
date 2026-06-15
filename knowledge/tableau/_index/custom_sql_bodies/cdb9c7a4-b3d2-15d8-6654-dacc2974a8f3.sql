SELECT	CONVERT(DATE,convert(varchar(10), dr.FromDateID)) AS 'Change_Date',
		mda.CID,
		dr.FromDateID,
		fsc.CountryID,
		dc.Name 'Previous_Country',
		dr.ToDateID,
		mda.RegAccountSubProgram,
		LEAD(dc.Name) OVER (PARTITION BY mda.CID ORDER BY dr.FromDateID) AS 'Current_Country'
FROM eMoney_dbo.eMoney_Dim_Account mda
INNER JOIN	DWH_dbo.Fact_SnapshotCustomer fsc
			ON mda.CID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Country dc
			ON fsc.CountryID = dc.CountryID
INNER JOIN DWH_dbo.Dim_Range dr
			ON fsc.DateRangeID = dr.DateRangeID AND dr.FromDateID >= 20220601 
WHERE	        mda.IsValidETM = 1
		AND fsc.IsValidCustomer = 1
		AND mda.IsTestAccount = 0
		AND mda.GCID_Unique_Count = 1