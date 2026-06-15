SELECT fca.DateID,  dc.Name AS Country, dr1.Name AS Regulation, sum(fca.TotalMirrorCash) TotalMirrorCash
FROM DWH_dbo.V_Liabilities fca
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON fca.CID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Country dc
		ON fsc.CountryID = dc.CountryID
	JOIN DWH_dbo.Dim_Regulation dr1
		ON fsc.RegulationID = dr1.DWHRegulationID
WHERE fca.DateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) AND  CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
GROUP BY fca.DateID,  dc.Name , dr1.Name