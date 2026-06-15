SELECT
	dc.Country
	, dc.Regulation
,tr.GCID
   ,tr.EtoroFeesUSD 
    ,tr.EtoroFees
    ,tr.TranDate
      ,tr.TranDateID  
    ,tr.CryptoId
      ,tr.CryptoName 
      ,tr.TransactionType
      ,tr.IsRedeem
      ,tr.IsConversion
      ,tr.IsPayment
	    ,tr.ProviderFees
      ,tr.FeeExchangeRate
      ,tr.BlockchainFees
      ,tr.EstimatedBlockchainFee
      ,tr.ActionTypeID
,CASE
		WHEN 
			dc.IsTestAccount=1     THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
FROM EXW.dbo.EXW_FactTransactions tr
 JOIN EXW.dbo.EXW_WalletInventory ew	ON tr.ReciverAddress = ew.PublicAddress 
and tr.CryptoId = ew.CryptoID
   JOIN  dbo.EXW_DimUser  dc WITH (nolock) on dc.GCID=ew.GCID
 
WHERE 1=1
AND tr.EtoroFees > 0
AND tr.TransactionTypeID IN (6, 7,0)
And tr.TranDateID >=  cast(CONVERT (VARCHAR(8) , dateadd(month,-4,getdate()), 112 ) AS INT)