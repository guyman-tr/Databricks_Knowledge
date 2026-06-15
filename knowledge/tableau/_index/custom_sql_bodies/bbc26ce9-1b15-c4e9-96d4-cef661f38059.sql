Select 
 
  eft.CryptoId 
 , eft.CryptoName as Crypto 
 , eiw.Id as 'Omnibus Wallet ID'
 , eiw.Address as 'Omnibus Address'
 , eiw.InternalType as 'Omnibus Type'
 , CASE WHEN  eft.CryptoId = eft.BlockchainCryptoId THEN  'Main Crypto' ELSE 'ERC20' END 'Crypto Type'
 , eft.TranDate
 , SUM(eft.AmountUSD) as 'USD' -- Out
 , SUM (eft.Amount) as 'Unit' -- Out
 , MAX(z.CoinBalance) [Coin Balance]
 , MAX(z.Occurred) AS [Coin Balance DateTime]
 FROM EXW.dbo.EXW_FactTransactions eft WITH (NOLOCK)
 JOIN EXW.dbo.EXW_InternalWallet eiw on WalletID= eiw.Id and eft.CryptoId = eiw.CryptoId
  CROSS APPLY 
   ( SELECT  efrb.WalletId, efrb.CryptoId, efrb.Occurred ,
			 CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN efrb.LevelId IS NOT NULL AND efrb.BitgoValue IS NULL THEN efrb.BloxBalance 
												              ELSE   efrb.BitgoValue END   CoinBalance
FROM EXW.dbo.ETL_FinanceReportsBalances efrb
WHERE   efrb.ReportId IN 

  (SELECT   [Id]
        FROM EXW.dbo.ETL_FinanceReports efr
WHERE CAST(StartTime AS DATE)  =CAST(GETDATE()-1 AS date)
) 
	AND efrb.Gcid =0 AND eft.WalletID = efrb.WalletId AND eft.CryptoId =efrb.CryptoId  
)  z   
WHERE eft.ActionTypeID=1 
and eft.GCID <= 0 and eft.TranStatusID=2
AND eft.TranDate>='20230101'
  GROUP BY eft.CryptoId, eft.WalletID, eft.TranDate,eft.CryptoName, eiw.Id, eiw.InternalType, eiw.Address 
, CASE WHEN  eft.CryptoId = eft.BlockchainCryptoId THEN  'Main Crypto' ELSE 'ERC20' END