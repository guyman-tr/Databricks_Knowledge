SELECT dr.Name AS Regulation
      ,COUNT(distinct dc.RealCID) AS Total_CIDs
      ,SUM(ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0)) AS Unrealized_Equity 
      ,SUM(bdppl.Total_Invested_Amount) AS Total_Invested_Amount
      ,SUM(fca.Total_Deposits) AS Total_Deposits
      ,SUM(fca.Total_CashOuts) AS Total_CashOuts

FROM DWH..Dim_Customer dc
     JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.DWHRegulationID
     JOIN DWH..V_Liabilities vl ON dc.RealCID = vl.CID AND vl.DateID = CONVERT(CHAR(8), GETDATE()-1, 112)
     LEFT JOIN (SELECT bdppl.CID, SUM(bdppl.Amount) AS Total_Invested_Amount
	        FROM BI_DB..BI_DB_PositionPnL bdppl 
		WHERE bdppl.DateID = CONVERT(CHAR(8), GETDATE()-1, 112) 
		GROUP BY bdppl.CID) bdppl ON dc.RealCID = bdppl.CID 
     LEFT JOIN (SELECT fca.RealCID
	               ,SUM(CASE WHEN fca.ActionTypeID = 7 THEN ISNULL(fca.Amount, 0) ELSE 0 END) AS Total_Deposits
	               ,SUM(CASE WHEN fca.ActionTypeID = 8 THEN ISNULL(fca.Amount, 0) ELSE 0 END) AS Total_CashOuts
	        FROM DWH..Fact_CustomerAction fca 
		WHERE fca.DateID >= 20210414
		GROUP BY fca.RealCID)fca ON dc.RealCID = fca.RealCID 

WHERE dc.RegulationID = 9
      AND dc.IsCreditReportValidCB = 1
      AND dc.IsDepositor = 1

GROUP BY dr.Name