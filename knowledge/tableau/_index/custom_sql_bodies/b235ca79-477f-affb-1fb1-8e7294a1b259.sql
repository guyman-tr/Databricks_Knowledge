SELECT  DISTINCT --distinct is temp untill wallet alloance fix will be done 
     BalanceDate
	,'X Non Zero Balance' AS TokenType
	, euswa.UserWalletAllowance
  ,COUNT(DISTINCT ub.GCID )'Users'
  ,SUM(CASE WHEN bkg.WalletId IS NULL THEN  ub.BalanceUSD 
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END)*epd.AvgPrice) 
																																		END)  'Balance USD'

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
	AND ub.CryptoName IN ( 'USDEX' ,'EURX','GBPX','GLDX','SLVX ','CNYX','SGDX','HKDX','CHFX','AUDX','JPYX ','RUBX','PLNX','TRYX','CADX','NZDX','ZARX')  
	AND 
	(CASE WHEN bkg.WalletId IS NULL THEN  ub.Balance
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END)) 
																																		END) >0
	GROUP BY
	  ub.BalanceDate
	  , euswa.UserWalletAllowance


UNION all
SELECT  DISTINCT --distinct is temp untill wallet alloance fix will be done 
     BalanceDate
	,'X Balance' AS TokenType
	, euswa.UserWalletAllowance
  ,COUNT(DISTINCT ub.GCID )'Users'
  ,SUM(CASE WHEN bkg.WalletId IS NULL THEN  ub.BalanceUSD 
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END)*epd.AvgPrice) 
																																		END)  'Balance USD'
 
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
	AND ub.CryptoName IN ( 'USDEX' ,'EURX','GBPX','GLDX','SLVX ','CNYX','SGDX','HKDX','CHFX','AUDX','JPYX ','RUBX','PLNX','TRYX','CADX','NZDX','ZARX')  

	GROUP BY
	  ub.BalanceDate
	  , euswa.UserWalletAllowance
					UNION ALL
					
SELECT  DISTINCT --distinct is temp untill wallet alloance fix will be done 
     BalanceDate
	,'ERC20 Balance' AS TokenType
	, euswa.UserWalletAllowance
  ,COUNT(DISTINCT ub.GCID )'Users'
  ,SUM(CASE WHEN bkg.WalletId IS NULL THEN  ub.BalanceUSD 
							ELSE 
							      ((CASE  WHEN efrb.LevelId IS NULL THEN efrb.BloxBalance 
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND BloxValue IS NOT NULL  THEN BloxValue  
								                 WHEN LevelId IS NOT NULL AND BitgoValue IS NULL AND  BloxValue  IS NULL THEN efrb.BloxBalance
												              ELSE   efrb.BitgoValue END)*epd.AvgPrice) 
																																		END)  'Balance USD'
 
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
	AND ub.CryptoName NOT IN ( 'USDEX' ,'EURX','GBPX','GLDX','SLVX ','CNYX','SGDX','HKDX','CHFX','AUDX','JPYX ','RUBX','PLNX','TRYX','CADX','NZDX','ZARX')  

	GROUP BY
	  ub.BalanceDate
	  , euswa.UserWalletAllowance

UNION ALL
SELECT 
      CAST(GETDATE()-1 AS date) AS Date
	,'X Tokens -SentOut Coins' AS TokenType
	, euswa.UserWalletAllowance
	,COUNT (DISTINCT  eft.GCID) Users
	 ,SUM(eft.AmountUSD)AmountUSD
FROM EXW.dbo.EXW_FactTransactions eft
	         JOIN EXW.dbo.EXW_DimUser edu ON eft.GCID = edu.GCID
			 JOIN EXW.dbo.EXW_UserSettingsWalletAllowance euswa ON eft.GCID = euswa.GCID
	          WHERE 1=1
	           AND edu.IsTestAccount =0 
	           AND eft.TransactionTypeID =1
	           AND CryptoName 
	                                    IN ( 'USDEX' ,'EURX','GBPX','GLDX','SLVX ','CNYX','SGDX','HKDX','CHFX'
										,'AUDX','JPYX ','RUBX','PLNX','TRYX','CADX','NZDX','ZARX')   
GROUP BY euswa.UserWalletAllowance