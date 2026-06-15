SELECT
	fs.GCID
   ,fs.RealCID
   ,fs.TranID
   ,fs.TranStatus
   ,fs.TranDate
   ,fs.TranDateID
   ,fs.Amount
    ,fs.ActionTypeName
   ,fs.AmountUSD
    ,fs.SenderAddress
   ,fs.ReciverAddress
   ,fs.BlockchainTransactionId
   ,CASE WHEN  fs.ActionTypeID =1 THEN  fs.TransactionType						
               WHEN  fs.ActionTypeID =2 THEN edrtt.Name END TransactionType	
   ,fs.IsRedeem
   ,fs.IsConversion
   ,fs.IsPayment
   ,fs.CryptoId 
   ,fs.CryptoName 
   ,du.Region
  -- ,pu.ProviderUserID
 --  , pu.ProviderUserIDNormalized
   ,CASE
		WHEN fs.GCID <= 0 THEN 'Omnibus'
		WHEN 	du.IsTestAccount =1      THEN 'TestAccount'
		WHEN  dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
   ,du.Country
   ,du.Regulation
   ,ps.Name AS PlayerStatus
    ,das.AccountStatusName AS AccountStatus
  FROM EXW.dbo.EXW_FactTransactions fs
LEFT JOIN EXW.dbo.ETL_ReceivedTransactions ert 
     ON fs.TranID = ert.Id			
LEFT JOIN EXW.dbo.ETL_DictionaryReceivedTransactionTypes edrtt 
    ON ert.ReceivedTransactionTypeId =edrtt.Id						
				
JOIN EXW_DimUser du
	ON fs.RealCID = du.RealCID
LEFT JOIN DWH.dbo.Dim_Customer dc
	ON fs.RealCID = dc.RealCID
LEFT JOIN DWH.dbo.Dim_Regulation dr
	ON dc.RegulationID = dr.DWHRegulationID
LEFT JOIN DWH.dbo.Dim_Country c
	ON du.CountryID = c.CountryID
LEFT JOIN DWH.dbo.Dim_PlayerStatus ps
	ON dc.PlayerStatusID = ps.PlayerStatusID
--LEFT JOIN [dbo].[EXW_TermsAndConditions] tc ON dc.GCID = tc.GCID
LEFT JOIN DWH.dbo.Dim_AccountStatus das
	ON dc.AccountStatusID = das.AccountStatusID

WHERE du.CountryID =79

AND IsTestAccount =0 AND TranDateID >20230901