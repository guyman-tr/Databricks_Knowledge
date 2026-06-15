SELECT
concat(fb.GCID,'_',fb.WalletID,'_' ,fb.CryptoId)  AS 'Key'
	,fb.FullDate
   ,fb.FullDateID
   ,fb.GCID
   ,fb.RealCID
   ,fb.Username
   ,fb.FirstName
   ,fb.LastName
   ,fb.BlockchainCryptoId 
   ,fb.BlockchainCryptoName 
   ,fb.InstrumentID
   ,fb.WalletID
   ,fb.Balance
   ,fb.BalanceUSD
   ,fb.UpdateDate
   ,fb.CryptoId 
   ,fb.CryptoName 
   ,ue.Country
   ,ROW_NUMBER() OVER (PARTITION BY concat(fb.GCID,'_',fb.WalletID,'_' ,fb.CryptoId) ORDER BY fb.FullDate ASC) AS keyRN
       ,CASE
		WHEN ue.Username LIKE '%RedeemProd%' OR
			ue.Username LIKE '%RedeemProd%' OR
			ue.Username LIKE '%WalletProd%' OR
			ue.Username LIKE '%InternalProd%' OR
			ue.Username LIKE '%NoWalletProd' OR
                        ue.Username ='RonaMaltz' OR
                        ue.Username = 'DanGanon' THEN 'TestUser'
		WHEN ue.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END AS RealUser
	   FROM [dbo].[EXW_FactBalance] fb  WITH (NOLOCK)
LEFT JOIN dbo.EXW_DimUser_Enriched ue
	ON fb.RealCID = ue.RealCID
WHERE 1=1
and fb.FullDateID >= 20190615 
AND fb.GCID > 0 
AND fb.BlockchainCryptoId =2 AND fb.CryptoId <>2