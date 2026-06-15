SELECT eft.GCID
      ,eft.RealCID
      ,eft.CryptoId
      ,eft.CryptoName
      ,eft.TranID
      ,eft.TranStatus
      ,eft.TranDate
      ,eft.Amount
      ,eft.ActionTypeName
      ,eft.AmountUSD
      ,eft.SenderAddress
      ,eft.ReciverAddress
     ,eft.BlockchainTransactionId
       FROM  EXW_dbo.EXW_FactTransactions eft 
WHERE eft.GCID>0
AND ActionTypeID =2
AND eft.IsRedeem =0
AND eft.IsConversion =0
AND eft.IsPayment =0
AND ISNULL(eft.IsFunding ,00) <>1
AND ISNULL(eft.ReceivedTransactionTypeID,99) NOT IN (8,3,5,2,6)
AND eft.SenderAddress <>'0x5be786ad38f5846f605a8003550074cdfd4899a1'  -- promo 
AND  CASE WHEN  CryptoId  =21   AND AmountUSD  <=0.000001 then 1 else 0 END   =0-- dust transactions
AND eft.TranStatusID =2 
AND eft.TranDateID >=20250330