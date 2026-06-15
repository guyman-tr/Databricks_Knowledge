SELECT eft.GCID		
	   ,eft.RealCID	
	   ,eft.CryptoId	
	   ,eft.CryptoName	
	   ,eft.TranStatus	
	   ,eft.TranDate	
	   ,eft.ActionTypeName AS ActionDirection	
	   ,eft.Amount	
	   ,eft.AmountUSD	
	   ,eft.SenderAddress	
	   ,eft.ReciverAddress	
	   ,eft.BlockchainTransactionId
	   , CASE WHEN eft.ActionTypeName  ='Sent' THEN eft.TransactionType 
	     WHEN eft.ActionTypeName ='Recive'  THEN (CASE WHEN eft.IsRedeem =1 THEN 'Redeem' ELSE eft.ReceivedTransactionType END)
				 ELSE NULL END TransactionType	
	   ,eft.TranDateTime	
	   ,eft.DateOccured	
	   ,eft.LastStatusUpdateOccurred	
	   ,eft.ActionTypeID	
	   ,eft.TranID
           , dc.Name Country , dr.Name Regulation
        
  FROM EXW_dbo.EXW_FactTransactions eft		
  JOIN EXW_dbo.EXW_WalletEntity ewe
  ON eft.GCID = ewe.GCID
  AND eft.TranDateID = ewe.DateID
  AND ewe.WalletEntity ='eToroME'
  LEFT JOIN DWH_dbo.Dim_Country dc 
ON ewe.CountryID = dc.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation dr
ON dc.RegulationID = ewe.RegulationID
  LEFT JOIN EXW_dbo.EXW_TestUsers etu
  ON eft.GCID = etu.GCID
 WHERE etu.GCID IS NULL
 AND eft.TranStatusID =2
 AND eft.GCID >0	
 AND (eft.ActionTypeID <> 2 OR eft.AmountUSD > 0.0001)
 AND eft.TranDateID		
 BETWEEN 
    CAST(CONVERT(varchar(8), CAST(<[Parameters].[Parameter 2]> AS DATE), 112) AS int) 
    AND 
    CAST(CONVERT(varchar(8), CAST(<[Parameters].[Parameter 3]> AS DATE), 112) AS int)