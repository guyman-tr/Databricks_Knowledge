SELECT DISTINCT 
  eaa.WorkDate 
  ,eaa.ProgramId
  ,eaa.HolderId 
  ,eaa.AccountId 
  ,eaa.TransactionCode 
  ,eaa.TransactionCodeDescription 
  ,eaa.TransactionDateTime 
  ,eaa.TransactionAmount 
  ,eaa.TransactionCurrencyCode
  ,eaa.TransactionCurrencyAlpha 
  ,eaa.ReferenceNumber 
  ,eaa.TransactionId 
  ,eaa.LoadType 
  ,eaa.LoadSource 
  ,eaa.Date 
  ,eaa.HolderCurrencyAlpha 
  ,eaa.EpmMethodId 
   ,w.WalletEntity
   ,mda.CID
   ,mda.GCID
     
  
FROM eMoney_dbo.ETL_AccountsActivities eaa 

 JOIN eMoney_dbo.eMoney_Dim_Account mda
 ON eaa.HolderId = mda.ProviderHolderID AND mda.GCID_Unique_Count=1 

 LEFT JOIN EXW_dbo.EXW_WalletEntity w 
    ON mda.GCID = w.GCID 
    AND eaa.Date = w.Date
	
WHERE 1=1 
AND eaa.LoadSource IN (20,21,22,23,24,34)
AND eaa.LoadType=1 
AND eaa.TransactionCode=1 


   AND eaa.DateID >= CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
 AND eaa.DateID <= CAST(FORMAT(CAST(<[Parameters].[Start Date for Report (copy)_144396673912111106]> AS DATE),'yyyyMMdd') as INT)