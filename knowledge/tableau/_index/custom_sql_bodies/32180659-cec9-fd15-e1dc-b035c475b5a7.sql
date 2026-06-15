SELECT 

tr.GCID
      ,tr.RealCID
      ,tr.CryptoId
      ,tr.CryptoName
      ,tr.WalletID
      ,tr.TranID
      ,tr.TranStatusID
      ,tr.TranStatus
      ,tr.TranDate
      ,tr.TranDateID
      ,tr.Amount
      ,tr.EtoroFees
   --   ,tr.ProviderFees
    --  ,tr.FeeExchangeRate
      ,tr.BlockchainFees
      ,tr.EstimatedBlockchainFee
	  ,tr.BlockchainFeesUSD
      ,tr.EstimatedBlockchainFeesUSD
      ,tr.ActionTypeID
      ,tr.AmountUSD
      ,tr.EtoroFeesUSD
    --    ,tr.IsEtoroFee
         ,tr.TransactionTypeID
      ,tr.TransactionType
      ,tr.IsRedeem
      ,tr.IsConversion
      ,tr.IsPayment
      ,tr.BlockchainCryptoId
      , CASE WHEN tr.GCID >0 THEN dc.Country
					WHEN tr.GCID =0 AND ew.GCID IS NOT NULL THEN dc1.Country ELSE NULL END Country
	  , CASE WHEN tr.GCID >0 THEN dc.Regulation
					WHEN tr.GCID =0 AND ew.GCID IS NOT NULL THEN dc1.Regulation ELSE NULL END Regulation
--, dc.Regulation
, tr.SenderAddress
 ,tr.ReciverAddress
--, tr.BlockchainTransactionId
,CASE
		WHEN dc.IsTestAccount=1    THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
	, ew.PublicAddress
	, ew.NormalizedAddress
	--, ew.GCID invgcid, dc1.Country invCountry, dc1.Regulation invRegulation

  FROM
 EXW_dbo.EXW_FactTransactions tr with (NOLOcK) 
  left JOIN EXW_dbo.EXW_DimUser dc WITH (nolock) on dc.GCID= tr.GCID
 LEFT JOIN EXW_dbo.EXW_WalletInventory ew WITH (nolock)	ON tr.ReciverAddress = ew.PublicAddress and tr.CryptoId = ew.CryptoID  
  left JOIN EXW_dbo.EXW_DimUser dc1 ON ew.GCID =dc1.GCID 
	where tr.TranDateID >=  cast(CONVERT (VARCHAR(8) , dateadd(month,-<[Parameters].[Parameter 1]>,getdate()), 112 ) AS INT)
and   isnull(tr.TransactionTypeID, 000) <> 10