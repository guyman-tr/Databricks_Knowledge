SELECT 
 eft.AskRate
,eft.BidRate 
--,eft.DateFrom
--eft.DateTo 
,eft.ActionTypeName
,eft.CryptoName
,eft.TranStatus
,eft.TransactionType
,eft.TranDateTime
,eft.TranDate
,eft.Amount
,eft.AmountUSD
, eft.Amount*eft.AskRate USD_By_AskRate
, eft.Amount*eft.BidRate  USD_By_BidRate
, eft.Amount*((eft.AskRate+eft.BidRate)/2) USD_By_AVG
,eft.AMLProviderStatus
,eft.BlockchainTransactionId
,eft.SenderAddress
,eft.ReciverAddress
,eft.GCID
,eft.RealCID
,eft.VerificationLevelID
,eft.IsValidCustomer
,eft.Club
,eft.Regulation
,eft.State
, eft.RegionID
	   FROM #final eft