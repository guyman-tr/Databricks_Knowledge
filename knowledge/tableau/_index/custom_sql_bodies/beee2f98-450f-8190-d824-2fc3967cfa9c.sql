/*SELECT 
   efb.FullDate
 , efb.CryptoName
, SUM(efb.Balance) 'Balance Coins'
, sum (efb.BalanceUSD) 'Balance USD'
, COUNT (DISTINCT efb.GCID) 'Wallets'
  FROM EXW_FactBalance efb WITH (NOLOCK)
JOIN EXW_DimUser edu ON efb.GCID = edu.GCID AND edu.IsTestAccount =0
WHERE efb.GCID >0 
AND efb.FullDateID >=    CAST(CONVERT(VARCHAR(8), DATEADD(week, -5,  DATEADD(DD,-(DATEPART(DW,CAST(GETDATE()AS DATE))-7),CAST(GETDATE()AS DATE))  ) , 112) AS INT) 
AND efb.FullDate  = DATEADD(DAY, 7 - DATEPART(WEEKDAY, FullDate), FullDate)
AND efb.BlockchainCryptoId =efb.CryptoId
GROUP BY efb.FullDate, efb.CryptoName*/

SELECT 
   efb.FullDate
 , CASE WHEN efb.BlockchainCryptoId =efb.CryptoId   and efb.CryptoId<>23 /*EOS*/
        THEN efb.CryptoName ELSE 'ERC20' END Crypto
 , sum (efb.BalanceUSD) 'Balance USD'
 FROM EXW.dbo.EXW_FactBalance efb WITH (NOLOCK)
 JOIN EXW.dbo.EXW_DimUser edu ON efb.GCID = edu.GCID AND edu.IsTestAccount =0
 WHERE efb.GCID >0 
    AND efb.FullDateID =  CAST(CONVERT(VARCHAR(8), GETDATE()-1, 112) AS INT) 
 GROUP BY efb.FullDate 
, CASE WHEN efb.BlockchainCryptoId =efb.CryptoId and  efb.CryptoId<>23  THEN efb.CryptoName ELSE 'ERC20' END