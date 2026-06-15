SELECT 
  eft.GCID
  ,eft.RealCID
  ,eft.CryptoId
  ,eft.Amount 
  ,eft.AmountUSD
  ,eft.TransactionType
  ,eft.TranDate
  , eft.BlockchainTransactionId
  ,eft.CryptoName
 
FROM EXW.dbo.EXW_FactTransactions eft
	      JOIN EXW.dbo.EXW_DimUser edu1 ON eft.GCID = edu1.GCID AND edu1.IsTestAccount =0
	          WHERE 1=1
			           AND eft.ActionTypeID =1
	       	           AND eft.TransactionTypeID =1
					   AND eft.TranStatusID =2
					   AND eft.CryptoId IN 
					   (SELECT ect.CryptoID FROM  EXW.dbo.ETL_CryptoTypes ect WHERE LOWER(ect.DisplayName )LIKE 'etoro%')