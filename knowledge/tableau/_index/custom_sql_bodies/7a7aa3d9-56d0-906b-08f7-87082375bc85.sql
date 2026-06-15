SELECT DISTINCT vl.DateID, CAST(CONVERT(char(8), DateID) as date) Date, vl.CID, dc.GCID, dc.Email, dc.UserName, vl.RealizedEquity, vl.TotalCash,
dc1.Name Country, dr1.Name Regulation, dr2.Name DesignatedRegulation, dsap.ShortName State_Short, dsap.Name State_Name
--, vl.InProcessCashouts, vl.TotalMirrorCash
FROM DWH_dbo.V_Liabilities vl
JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) 
ON vl.CID=dc.RealCID AND dc.DesignatedRegulationID IN (6,7,8) AND dc.RegulationID IN (6,7,8) 
JOIN DWH_dbo.Dim_Country dc1 
		ON dc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_Regulation dr1  WITH (NOLOCK) 
ON dc.RegulationID = dr1.DWHRegulationID
JOIN DWH_dbo.Dim_Regulation dr2  WITH (NOLOCK) 
ON dc.DesignatedRegulationID = dr2.DWHRegulationID
LEFT JOIN DWH_dbo.Dim_State_and_Province dsap 
ON dc.RegionID = dsap.RegionByIP_ID
WHERE vl.DateID >=20230101
AND  vl.TotalCash>=240000
--ORDER BY vl.DateID