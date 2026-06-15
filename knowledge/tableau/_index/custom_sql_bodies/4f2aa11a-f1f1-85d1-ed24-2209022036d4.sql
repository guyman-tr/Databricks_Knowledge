SELECT bdvddp.DateID
      ,a.Deposits Deposits_DDR_Daily_Aggregated
	  ,SUM(bdvddp.TPDepositsOldDef) Deposits_V_DDR_Daily_Panel
	  ,a.CashoutsAdjusted CashoutsAdjusted_DDR_Daily_Aggregated
	  ,SUM(bdvddp.TPCashoutsOldDef) - SUM(bdvddp.TransferCoins) - SUM(bdvddp.CashoutAdjustment) AS CashoutsAdjusted_V_DDR_Daily_Panel
	  ,a.Deposits-SUM(bdvddp.TPDepositsOldDef) AS Deposits_Gap
	  ,a.CashoutsAdjusted-(SUM(bdvddp.TPCashoutsOldDef) - SUM(bdvddp.TransferCoins) - SUM(bdvddp.CashoutAdjustment)) AS CO_Gap
FROM  BI_DB_dbo.BI_DB_V_DDR_Daily_Panel bdvddp WITH(NOLOCK)
LEFT JOIN (
SELECT bddda.DateID
      ,SUM(bddda.Deposits)Deposits
	  ,SUM(bddda.CashoutsAdjusted) CashoutsAdjusted
FROM BI_DB_dbo.BI_DB_DDR_Daily_Aggregated bddda
WHERE bddda.DateID>=CAST(CONVERT(VARCHAR(8),DATEADD(MONTH,-1,GETDATE()-1), 112) AS INT)
GROUP BY bddda.DateID) a ON a.DateID=bdvddp.DateID
WHERE bdvddp.DateID >=CAST(CONVERT(VARCHAR(8),DATEADD(MONTH,-1,GETDATE()-1), 112) AS INT)
GROUP BY bdvddp.DateID
       ,a.Deposits 
	   ,a.CashoutsAdjusted