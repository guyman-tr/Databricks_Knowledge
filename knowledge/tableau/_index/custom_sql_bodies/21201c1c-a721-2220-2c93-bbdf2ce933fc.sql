SELECT  EOMONTH(eft.TranDate)EOM
 , count(eft.TranID) TxNumber
 , sum(eft.AmountUSD)UsdAmount 
 , COUNT(DISTINCT eft.GCID) Users
 , eft.CryptoName Crypto
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
union all


SELECT 
  EOMONTH(ecfee.LastModificationDate) EOM
, count(ecfee.CorrelationID) TxNumber
, sum (ecfee.FactActionCompensationAmountUSD) UsdAmount
, COUNT(DISTINCT ecfee.GCID) Users
, ecfee.Crypto
, 'C2P' AS 'Activity'
FROM EXW_dbo.EXW_C2P_E2E  ecfee
JOIN 
(
SELECT DISTINCT eft.GCID
 , eft.CryptoName
 , EOMONTH(eft.TranDate)EOM
 , Max(eft.TranDate ) MaxDate
 , Min(eft.TranDate ) MinDate
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
  AND a.Address IS NULL
 GROUP BY eft.GCID
 , eft.CryptoName , EOMONTH(eft.TranDate))u
ON ecfee.GCID = u.GCID
AND ecfee.Crypto = u.CryptoName
AND u.EOM  =  EOMONTH(ecfee.LastModificationDate)  
AND ecfee.LastModificationDate > u.MinDate
WHERE 1=1
AND ecfee.LastModificationDate>=<[Parameters].[Parameter 1]>
AND ecfee.ConversionCycle ='Full Cycle'
GROUP BY   EOMONTH(ecfee.LastModificationDate), Crypto 



Union All  
SELECT 
EOMONTH(ecfee.LastModificationDate) EOM
, count(ecfee.C2FCorrelationID) TxNumber
, sum (ecfee.UsdAmount) UsdAmount
, COUNT(DISTINCT ecfee.GCID) Users
, ecfee.Crypto
, 'C2F' AS 'Activity'
FROM EXW_dbo.EXW_C2F_E2E ecfee
JOIN (SELECT DISTINCT eft.GCID
 , eft.CryptoName
 , EOMONTH(eft.TranDate)EOM
 , Max(eft.TranDate ) MaxDate
 , Min(eft.TranDate ) MinDate
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
  AND a.Address IS NULL
 GROUP BY eft.GCID
 , eft.CryptoName , EOMONTH(eft.TranDate)) u
ON ecfee.GCID = u.GCID
AND ecfee.Crypto = u.CryptoName
AND u.EOM  =  EOMONTH(ecfee.LastModificationDate)  
AND ecfee.LastModificationDate > u.MinDate
WHERE 1=1
AND ecfee.LastModificationDate>= <[Parameters].[Parameter 1]>
AND ecfee.ConversionCycle ='Full Cycle'

GROUP BY   EOMONTH(ecfee.LastModificationDate), Crypto 

Union All 
 
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

JOIN (SELECT DISTINCT eft.GCID
 , eft.CryptoName
 , EOMONTH(eft.TranDate)EOM
 , Max(eft.TranDate ) MaxDate
 , Min(eft.TranDate ) MinDate
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
  AND a.Address IS NULL
 GROUP BY eft.GCID
 , eft.CryptoName , EOMONTH(eft.TranDate)) u
ON eft.GCID = u.GCID
AND eft.CryptoName = u.CryptoName
AND u.EOM  =   EOMONTH(eft.TranDate)
AND eft.TranDate > u.MinDate
WHERE 1=1
AND edu.IsTestAccount =0
AND eft.ActionTypeID =1
AND eft.TranStatusID =2
AND eft.TransactionTypeID =1
AND eft.GCID>0
   AND eft.TranDate>= <[Parameters].[Parameter 1]>
   AND a.Address IS NULL
GROUP BY   EOMONTH(eft.TranDate), eft.CryptoName
--ORDER BY   USD , EOMONTH(eft.TranDate) 

Union All 
 

 SELECT  EOMONTH(err.[etoro - ModificationDate])EOM
 , count(err.PositionID) TxNumber
 , sum(err.[eToro - AmountOnCloseUSD])USD 
 , COUNT(DISTINCT err.[Wallet - RequestingGCID]) Users
 ,err.CryptoName
 , 'Redeem' AS 'Activity'
 FROM EXW_dbo.EXW_RedeemReconciliation err
 JOIN (SELECT DISTINCT eft.GCID
 , eft.CryptoName
 , EOMONTH(eft.TranDate)EOM
 , Max(eft.TranDate ) MaxDate
 , Min(eft.TranDate ) MinDate
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
  AND a.Address IS NULL
 GROUP BY eft.GCID
 , eft.CryptoName , EOMONTH(eft.TranDate)) u
ON err.[Wallet - RequestingGCID] = u.GCID
AND err.CryptoName = u.CryptoName
AND u.EOM  =    EOMONTH(err.[etoro - ModificationDate])
AND err.[etoro - ModificationDate] > u.MinDate
 WHERE err.[etoro - ModificationDate] >= <[Parameters].[Parameter 1]>
 AND err.EntryAppears ='BothSidesEntry'
 AND err.[etoro - RedeemStatus] ='TransactionDone'
  GROUP BY EOMONTH(err.[etoro - ModificationDate]) , err.CryptoName