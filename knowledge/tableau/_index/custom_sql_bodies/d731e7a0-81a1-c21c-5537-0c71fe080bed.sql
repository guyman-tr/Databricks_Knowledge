SELECT ft.GCID
   ,ft.RealCID
   ,ft.CryptoId 
   ,ft.CryptoName 
   ,ft.InstrumentID
   ,ft.WalletID
   ,ft.TranID
   ,ft.TranStatusID
   ,ft.TranStatus
   ,ft.TranDate
   ,ft.TranDateID
   ,ft.Amount
   ,ft.EtoroFees
   ,ft.ProviderFees
   ,ft.FeeExchangeRate
   ,ft.BlockchainFees
   ,ft.EstimatedBlockchainFee
   ,ft.ActionTypeID
   ,ft.ActionTypeName
   ,ft.AmountUSD
   ,ft.EtoroFeesUSD
   ,ft.BlockchainFeesUSD
   ,ft.EstimatedBlockchainFeesUSD
   ,ft.UpdateDate
   ,ft.SenderAddress
   ,ft.ReciverAddress
   ,ft.AMLProviderStatus
   ,ft.AMLIsPositiveDecision
   ,ft.IsEtoroFee
   ,ft.BlockchainTransactionId
   ,ft.TransactionTypeID
   ,ft.TransactionType
   ,ft.IsRedeem
   ,ft.IsConversion
   ,ft.IsPayment
   ,ft.BlockchainCryptoId 
   ,ft.BlockchainCryptoName 
   ,due.PlayerLevelID
   ,due.VerificationLevelID
   ,due.Country
   , due.Region
   ,due.RegisterState 
   ,CASE 
   	When due.Country ='United States' THEN 'US'
   	   	ELSE 'NotUS'
   END isUS
from EXW_FactTransactions ft
JOIN EXW_DimUser_Enriched due ON ft.GCID = due.GCID
WHERE due.IsValidCustomer =1
AND ft.GCID>0