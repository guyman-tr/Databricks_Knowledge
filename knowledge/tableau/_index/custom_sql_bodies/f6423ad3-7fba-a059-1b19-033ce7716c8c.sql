SELECT 
  EOMONTH(ecfee.LastModificationDate) EOM
, count(ecfee.CorrelationID) TxNumber
, sum (ecfee.FactActionCompensationAmountUSD) UsdAmount
, COUNT(DISTINCT ecfee.GCID) Users
, ecfee.Crypto
, 'C2P' AS 'Activity'
FROM EXW_dbo.EXW_C2P_E2E  ecfee
WHERE 1=1
AND ecfee.LastModificationDate>=  <[Parameters].[Parameter 1]>
AND ecfee.ConversionCycle ='Full Cycle'
GROUP BY   EOMONTH(ecfee.LastModificationDate), Crypto 

UNION all
SELECT 
EOMONTH(ecfee.LastModificationDate) EOM
, count(ecfee.C2FCorrelationID) TxNumber
, sum (ecfee.UsdAmount) UsdAmount
, COUNT(DISTINCT ecfee.GCID) Users
, ecfee.Crypto
, 'C2F' AS 'Activity'
FROM EXW_dbo.EXW_C2F_E2E ecfee
WHERE 1=1
AND ecfee.LastModificationDate>=  <[Parameters].[Parameter 1]>
AND ecfee.ConversionCycle ='Full Cycle'
GROUP BY   EOMONTH(ecfee.LastModificationDate), Crypto 
 
 UNION all

SELECT  EOMONTH(eft.TranDate)EOM
 , count(eft.TranID) TxNumber
 , sum(eft.AmountUSD)USD 
 , COUNT(DISTINCT eft.GCID) Users
 , eft.CryptoName
 , 'CryptoIN' AS 'Activity'
FROM EXW_dbo.EXW_FactTransactions eft
JOIN EXW_dbo.EXW_DimUser edu
ON eft.GCID = edu.GCID
LEFT JOIN 
(select 
  CASE WHEN NormalizedAddress = Address THEN Address  ELSE NormalizedAddress  END 'Address'
  from EXW_Wallet.WalletAddresses wa
) a
    ON eft.SenderAddress = a.Address
WHERE 1=1
AND edu.IsTestAccount =0
AND eft.AmountUSD>0.1
AND eft.ActionTypeID =2
AND eft.TranStatusID =2
AND eft.IsRedeem =0
 AND eft.GCID>0
   AND eft.TranDate>=  <[Parameters].[Parameter 1]>
   AND a.Address IS NULL
GROUP BY   EOMONTH(eft.TranDate), CryptoName
 
Union all
 
  SELECT  EOMONTH(eft.TranDate)EOM
 , count(eft.TranID) TxNumber
 , sum(eft.AmountUSD)USD 
 , COUNT(DISTINCT eft.GCID) Users
 , eft.CryptoName
 , 'CryptoOut' AS 'Activity'
FROM EXW_dbo.EXW_FactTransactions eft
JOIN EXW_dbo.EXW_DimUser edu
ON eft.GCID = edu.GCID
LEFT JOIN 
(select 
  CASE WHEN NormalizedAddress = Address THEN Address  ELSE NormalizedAddress  END 'Address'
  from EXW_Wallet.WalletAddresses wa
) a
    ON eft.ReciverAddress = a.Address
WHERE 1=1
AND edu.IsTestAccount =0
AND eft.ActionTypeID =1
AND eft.TranStatusID =2
AND eft.TransactionTypeID =1
AND eft.GCID>0
   AND eft.TranDate>=  <[Parameters].[Parameter 1]>
   AND a.Address IS NULL
GROUP BY   EOMONTH(eft.TranDate), CryptoName
--ORDER BY   USD , EOMONTH(eft.TranDate) 

Union  all
 

 SELECT  EOMONTH(err.[etoro - ModificationDate])EOM
 , count(err.PositionID) TxNumber
 , sum(err.[eToro - AmountOnCloseUSD])USD 
 , COUNT(DISTINCT err.[Wallet - RequestingGCID]) Users
 ,err.CryptoName
 , 'Redeem' AS 'Activity'
 FROM EXW_dbo.EXW_RedeemReconciliation err
 WHERE err.[etoro - ModificationDate] >=  <[Parameters].[Parameter 1]>
 AND err.EntryAppears ='BothSidesEntry'
 AND err.[etoro - RedeemStatus] ='TransactionDone'
  GROUP BY EOMONTH(err.[etoro - ModificationDate]) , err.CryptoName