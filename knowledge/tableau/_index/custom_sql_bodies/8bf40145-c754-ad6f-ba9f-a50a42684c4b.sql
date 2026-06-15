SELECT 
       vl.FullDate AS Date1,
       --@DateID AS DateID, 
       dr1.Name AS Regulation, 
	   dc.IsValidCustomer,
	   dc.IsCreditReportValidCB, 
	   dc.IsDepositor,
       COUNT(vl.CID) AS Total_CIDs,
       SUM(ISNULL(vl.Liabilities, 0)) AS Liabilities,
	   SUM(ISNULL(vl.LiabilitiesCryptoReal, 0)) AS LiabilitiesCryptoReal,
	   SUM(CASE WHEN ISNULL(vl.Liabilities, 0) - ISNULL(vl.LiabilitiesCryptoReal, 0) = 0 THEN 1 ELSE 0 END) AS Total_CIDs_Liabilities_Crypto_Only,
	   SUM(CASE WHEN ISNULL(vl.Liabilities, 0) - ISNULL(vl.LiabilitiesCryptoReal, 0) = 0 THEN ISNULL(vl.LiabilitiesCryptoReal, 0) ELSE 0 END) AS Liabilities_Crypto_Only

FROM DWH_dbo.V_Liabilities vl WITH (NOLOCK)
     
	 INNER JOIN DWH_dbo.Fact_SnapshotCustomer dc WITH (NOLOCK) ON vl.CID = dc.RealCID	                                                      
     INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK) ON dc.DateRangeID = dr.DateRangeID 
	                                           AND vl.DateID BETWEEN dr.FromDateID AND dr.ToDateID 
     INNER JOIN DWH_dbo.Dim_Regulation dr1 ON dc.RegulationID = dr1.DWHRegulationID
	                                   AND dr1.DWHRegulationID = 2

WHERE vl.DateID  between CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
                         and CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
      AND vl.Liabilities <> 0

GROUP BY dr1.Name,
	     dc.IsValidCustomer,
	     dc.IsCreditReportValidCB,
	     dc.IsDepositor,
		 vl.FullDate