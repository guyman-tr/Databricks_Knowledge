SELECT 
  'Latest' AS 'BalanceTimeLine'
 ,efrb.WalletId
 ,efrb.CryptoId  CryptoID
 ,edct.Name AS CryptoName
 ,eiw.InternalType as 'Omnibus Type'
 ,epd.FullDate BalanceDate
 ,eiw.Id as 'Omnibus Wallet ID'
 ,eiw.Address as 'Omnibus Address'
 ,CASE  WHEN edct.CryptoID = edct.BlockchainCryptoId then 'Main Crypto' else 'ERC20'end 'Crypto Type'
 ,efrb.Occurred
 ,CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
				WHEN efrb.LevelId IS NOT NULL AND efrb.BitgoValue IS NULL THEN efrb.BloxBalance 
				ELSE   efrb.BitgoValue END   Balance
,(CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
				WHEN efrb.LevelId IS NOT NULL AND efrb.BitgoValue IS NULL THEN efrb.BloxBalance 
				ELSE   efrb.BitgoValue END)*AvgPrice   USDBalance
FROM CopyFromLake.WalletBalancesReportDB_Wallet_FinanceReportsBalances efrb    
  JOIN EXW_dbo.EXW_InternalWallet eiw with (NOLOCK) ON efrb.WalletId = eiw.Id AND efrb.CryptoId = eiw.CryptoId 
  JOIN EXW_Wallet.CryptoTypes  edct 	ON eiw.CryptoId = edct.CryptoID
  JOIN EXW_Wallet.EXW_PriceDaily epd ON epd.CryptoID = efrb.CryptoId  
WHERE   efrb.ReportId IN 
(SELECT  MAX( [Id])Id FROM EXW_Wallet.FinanceReports  efr  --1921  select * from EXW_Wallet.FinanceReports where Id =1921   select * from 
		WHERE EndTime IS NOT NULL )
AND epd.FullDate = ( SELECT Max(Cast (StartTime AS DATE )) FROM EXW_Wallet.FinanceReports  WHERE EndTime IS NOT NULL)
UNION ALL 
  SELECT 
  'Prev' AS 'BalanceTimeLine'
 ,efrb.WalletId
 ,efrb.CryptoId  CryptoID
 ,edct.Name AS CryptoName
 ,eiw.InternalType as 'Omnibus Type'
 ,epd.FullDate BalanceDate
 ,eiw.Id as 'Omnibus Wallet ID'
 ,eiw.Address as 'Omnibus Address'
 ,CASE  WHEN edct.CryptoID = edct.BlockchainCryptoId then 'Main Crypto' else 'ERC20'end 'Crypto Type'
 ,efrb.Occurred
 ,CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
				WHEN efrb.LevelId IS NOT NULL AND efrb.BitgoValue IS NULL THEN efrb.BloxBalance 
				ELSE   efrb.BitgoValue END   Balance
,(CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
				WHEN efrb.LevelId IS NOT NULL AND efrb.BitgoValue IS NULL THEN efrb.BloxBalance 
				ELSE   efrb.BitgoValue END)*AvgPrice   USDBalance
FROM CopyFromLake.WalletBalancesReportDB_Wallet_FinanceReportsBalances efrb    
  JOIN EXW_dbo.EXW_InternalWallet eiw with (NOLOCK) ON efrb.WalletId = eiw.Id AND efrb.CryptoId = eiw.CryptoId 
  JOIN EXW_Wallet.CryptoTypes  edct 	ON eiw.CryptoId = edct.CryptoID
  JOIN EXW_Wallet.EXW_PriceDaily epd ON epd.CryptoID = efrb.CryptoId  
WHERE   efrb.ReportId IN 

(
SELECT    MAX(efr.[Id] )Id
        FROM EXW_Wallet.FinanceReports efr
		 WHERE efr.EndTime IS NOT NULL 
		 AND Id <
(SELECT    MAX(efr.[Id] )Id
        FROM EXW_Wallet.FinanceReports efr
		 WHERE efr.EndTime IS NOT NULL) )
AND epd.FullDate = ( SELECT Max(Cast (StartTime AS DATE )) FROM EXW_Wallet.FinanceReports  WHERE EndTime IS NOT NULL
                    AND Cast (StartTime AS DATE ) <
                        (SELECT Max(Cast (StartTime AS DATE )) FROM EXW_Wallet.FinanceReports  WHERE EndTime IS NOT NULL))