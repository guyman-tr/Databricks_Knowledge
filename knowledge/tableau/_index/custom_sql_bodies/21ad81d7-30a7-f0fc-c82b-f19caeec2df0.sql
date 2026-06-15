SELECT  
       da.Country
	  ,da.Club
	,CASE 
    WHEN da.AccountSubProgramID IN (1, 2, 8) THEN 'UK'
    WHEN da.AccountSubProgramID IN (4, 5, 6, 7, 9, 11, 12) THEN 'EU'
    WHEN da.AccountSubProgramID IN (13, 14) THEN 'AU'
    ELSE 'Other'
END AS IBAN_Region

	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)=cast(GETDATE()-1 AS date) THEN dp.Amount ELSE 0 END) AS Open_Amount_Yesterday
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)=cast(GETDATE()-1 AS date) THEN dp.Amount ELSE 0 END) AS Close_Amount_Yesterday
	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)=cast(GETDATE()-1 AS date) THEN 1 ELSE 0 END) AS Open_TXs_Yesterday
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)=cast(GETDATE()-1 AS date) THEN 1 ELSE 0 END) AS Close_TXs_Yesterday
	  ,COUNT(DISTINCT CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)=cast(GETDATE()-1 AS date) THEN da.CID END) AS Open_Clients_Yesterday
	  ,COUNT(DISTINCT CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)=cast(GETDATE()-1 AS date) THEN da.CID END) AS Close_Clients_Yesterday
	

	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-7 THEN dp.Amount ELSE 0 END) AS Open_Amount_7D
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-7 THEN dp.Amount ELSE 0 END) AS Close_Amount_7D
	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-7 THEN 1 ELSE 0 END) AS Open_TXs_7D
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-7 THEN 1 ELSE 0 END) AS Close_TXs_7D
	  ,COUNT(DISTINCT CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-7 THEN da.CID  END) AS Open_Clients_7D
	  ,COUNT(DISTINCT CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-7 THEN da.CID END) AS Close_Clients_7D
	 

	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-30 THEN dp.Amount ELSE 0 END) AS Open_Amount_30D
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-30 THEN dp.Amount ELSE 0 END) AS Close_Amount_30D
	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-30 THEN 1 ELSE 0 END) AS Open_TXs_30D
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-30 THEN 1 ELSE 0 END) AS Close_TXs_30D
	  ,COUNT(DISTINCT CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-30 THEN da.CID  END) AS Open_Clients_30D
	  ,COUNT(DISTINCT CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-30 THEN da.CID  END) AS Close_Clients_30D


	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-365 THEN dp.Amount ELSE 0 END) AS Open_Amount_365D
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-365 THEN dp.Amount ELSE 0 END) AS Close_Amount_365D
	  ,SUM(CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-365 THEN 1 ELSE 0 END) AS Open_TXs_365D
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-365 THEN 1 ELSE 0 END) AS Close_TXs_365D
	  ,COUNT(DISTINCT CASE WHEN op.PositionID IS NOT NULL AND CAST(dp.OpenOccurred AS DATE)>=GETDATE()-365 THEN da.CID  END) AS Open_Clients_365D
	  ,COUNT(DISTINCT CASE WHEN cl.PositionID IS NOT NULL AND CAST(dp.CloseOccurred AS DATE)>=GETDATE()-365 THEN da.CID  END) AS Close_Clients_365D
	  

	  ,SUM(CASE WHEN op.PositionID IS NOT NULL  THEN dp.Amount ELSE 0 END) AS Open_Amount_Total
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL  THEN dp.Amount ELSE 0 END) AS Close_Amount_Total
	  ,SUM(CASE WHEN op.PositionID IS NOT NULL  THEN 1 ELSE 0 END) AS Open_TXs_Total
	  ,SUM(CASE WHEN cl.PositionID IS NOT NULL  THEN 1 ELSE 0 END) AS Close_TXs_Total
	  ,COUNT(DISTINCT CASE WHEN op.PositionID IS NOT NULL  THEN da.CID  END) AS Open_Clients_Total
	  ,COUNT(DISTINCT CASE WHEN cl.PositionID IS NOT NULL  THEN da.CID  END) AS Close_Clients_Total
	  

FROM DWH_dbo.Dim_Position dp WITH (NOLOCK)
INNER JOIN eMoney_dbo.eMoney_Dim_Account da WITH (NOLOCK) on dp.CID=da.CID and da.IsValidETM=1 and da.GCID_Unique_Count=1 
LEFT JOIN  BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN  op on dp.PositionID=op.PositionID
LEFT JOIN  BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN cl on dp.PositionID=cl.PositionID

WHERE COALESCE(dp.MirrorID, 0) = 0
      AND COALESCE(dp.IsAirDrop, 0) = 0
      AND ((dp.OpenDateID>=20240408) OR (dp.CloseDateID>=20240408))
GROUP BY da.Country
	    ,da.Club
		 ,	CASE 
    WHEN da.AccountSubProgramID IN (1, 2, 8) THEN 'UK'
    WHEN da.AccountSubProgramID IN (4, 5, 6, 7, 9, 11, 12) THEN 'EU'
    WHEN da.AccountSubProgramID IN (13, 14) THEN 'AU'
    ELSE 'Other'
       END