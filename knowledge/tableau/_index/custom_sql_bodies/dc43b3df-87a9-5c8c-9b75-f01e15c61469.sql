SELECT	YEAR(frt.Occurred) AS Year,
		MONTH(frt.Occurred) AS Month,
		frt.Occurred,
		mda.CID,
		frt.FromRegulationID,
		dr1.Name AS 'From_Regulation',
		frt.ToRegulationID,
		dr2.Name AS 'To_Regulation',
		mda.RegAccountSubProgram
FROM DWH_dbo.Fact_RegulationTransfer frt
INNER JOIN	eMoney_dbo.eMoney_Dim_Account mda
			ON frt.CID = mda.CID
INNER JOIN  DWH_dbo.Dim_Regulation dr1
			ON frt.FromRegulationID = dr1.ID
INNER JOIN  DWH_dbo.Dim_Regulation dr2
			ON frt.ToRegulationID = dr2.ID
WHERE	--frt.FromRegulationID <> 5
		 mda.IsValidETM=1
		AND mda.IsValidCustomer=1
		AND mda.IsTestAccount=0
		AND mda.GCID_Unique_Count=1
		AND frt.Occurred >= '2022-06-01'