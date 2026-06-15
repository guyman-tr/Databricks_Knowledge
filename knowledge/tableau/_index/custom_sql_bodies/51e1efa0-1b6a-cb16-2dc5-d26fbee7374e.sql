SELECT
   eft.SenderAddress
  ,eft.TranDate
  ,eft.CryptoName
  ,eft.ReceivedTransactionType
  ,eft.ReceivedTransactionTypeID
  ,count(eft.WalletID) Users
  ,count(eft.TranID) TxNumber
  ,sum(eft.Amount) TotalAmount
  ,sum(eft.AmountUSD)TotalUsd
 -- ,CASE WHEN eft.GCID >0 THEN 0 ELSE 1 END IsOmnubusAddress
FROM EXW_dbo.EXW_FactTransactions eft
WHERE eft.ActionTypeID =2
 -- AND eft.GCID>0
  AND eft.IsRedeem =0
  AND eft.IsConversion =0
  AND eft.AmountUSD<1
--  AND eft.ReceivedTransactionTypeID =1
GROUP BY 
   eft.SenderAddress
  ,eft.TranDate
  ,eft.CryptoName
  ,eft.ReceivedTransactionType
  ,eft.ReceivedTransactionTypeID
  --,CASE WHEN eft.GCID >0 THEN 0 ELSE 1 END 
HAVING count(eft.TranID)>50