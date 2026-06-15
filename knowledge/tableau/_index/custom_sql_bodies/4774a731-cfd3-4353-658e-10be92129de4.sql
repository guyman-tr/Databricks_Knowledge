SELECT ub.BalanceDate
, ub.CryptoName
,euswa.UserWalletAllowance
, COUNT(*)'Total Wallets Number'
,SUM(CASE WHEN bkg.WalletId IS NULL THEN  ub.BalanceUSD 
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END)*epd.AvgPrice) 
																																		END)  'Balance USD'

,SUM(CASE WHEN bkg.WalletId IS NULL THEN  ub.Balance 
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END) ) 
																																		END)    'Coin Balance'

, SUM(CASE WHEN

(CASE WHEN bkg.WalletId IS NULL THEN  ub.Balance  
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END)) 
																																		END) <>0 THEN 1 ELSE 0 END) 'Non Zero Wallets Number'
, SUM(CASE WHEN 
(CASE WHEN bkg.WalletId IS NULL THEN  ub.Balance  
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END) ) 
																																		END)=0 THEN 1 ELSE 0 END) 'Zero Wallets Number'
, CASE WHEN ub.CryptoName IN ( 'USDEX' ,'EURX','GBPX','GLDX','SLVX ','CNYX','SGDX','HKDX','CHFX','AUDX','JPYX ','RUBX','PLNX','TRYX','CADX','NZDX','ZARX') THEN 'X' ELSE 'ERC20' END 'TokenType'
FROM EXW.dbo.EXW_UserCalculatedBalance ub 
	JOIN EXW.dbo.EXW_UserSettingsWalletAllowance euswa ON ub.GCID = euswa.GCID
    JOIN EXW.dbo.EXW_PriceDaily epd ON ub.CryptoId = epd.CryptoID
	                            AND epd.FullDateID= CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT) 
	LEFT JOIN EXW.dbo.BalanceKnownGaps bkg ON ub.WalletId = bkg.WalletId AND ub.CryptoId = bkg.CryptoId 
	LEFT JOIN EXW.dbo.ETL_FinanceReportsBalances efrb 
	                              ON efrb.WalletId=bkg.WalletId 
								  AND bkg.CryptoId = efrb.CryptoId 
								  AND efrb.Date =CAST(getdate()-1AS date) 
	WHERE ub.BalanceDateId =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT) 
	AND epd.BlockchainCryptoId <>epd.CryptoID
	AND ub.IsTestAccount=0 
--AND ub.CryptoName IN ( 'USDEX' ,'EURX','GBPX','GLDX','SLVX ','CNYX','SGDX','HKDX','CHFX','AUDX','JPYX ','RUBX','PLNX','TRYX','CADX','NZDX','ZARX')  
--	AND  UserWalletAllowance='Allowed'

 GROUP BY
 ub.BalanceDate
,ub.CryptoName
, euswa.UserWalletAllowance
, CASE WHEN ub.CryptoName IN
( 'USDEX' ,'EURX','GBPX','GLDX','SLVX ','CNYX','SGDX','HKDX'
,'CHFX','AUDX','JPYX ','RUBX','PLNX','TRYX','CADX','NZDX','ZARX') 
THEN 'X' ELSE 'ERC20' END