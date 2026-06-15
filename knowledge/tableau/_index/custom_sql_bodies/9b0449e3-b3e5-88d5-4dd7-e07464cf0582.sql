SELECT
	fc.ConversionID
   ,fc.CorrelationID
   ,fc.RequestTime
   ,fc.FromWalletId
   ,fc.FromAddress
   ,fc.SendingGCID
   ,fc.RequestedFromAmount
   ,fc.FromBlockchainCryptoId as FromCryptoID
   ,fc.FromBlockchainCryptoName as FromCrypto
   ,fc.ConversionStatus
   ,fc.ModificationTime
   ,fc.FromAmount
   ,fc.ToEtoroEstimatedBCFee
   ,fc.ToEtoroDate
   ,fc.ConversionID2
   ,fc.ToWalletId
   ,fc.ToAddress
   ,fc.RecievingGCID
   ,fc.RequestedToAmount
   ,fc.ToBlockchainCryptoId as ToCryptoID
   ,fc.ToBlockchainCryptoName as ToCrypto
   ,fc.ToAmount
   ,fc.FromEtoroEstimatedBCFee
   ,fc.FromEtoroDate
   ,fc.ToEtoroSentTXID
   ,fc.ToEtoroSentBlockchainTXID
   ,fc.FromEtoroSentTXID
   ,fc.FromEtoroSentBlockchainTXID
   ,fc.SentToEtoroWalletAmount
   ,fc.SentToEtoroWalletEtoroFees
   ,fc.SentToEtoroBlockchainFees
   ,fc.SentFromEtoroWalletAmount
   ,fc.SentFromEtoroWalletEtoroFees
   ,fc.SentFromEtoroBlockchainFees
   ,fc.ToEtoroReceivedTXID
   ,fc.ToEtoroReceivedAmount
   ,fc.ToEtoroReceiveBlockchainFee
   ,fc.FromEtoroReceivedTXID
   ,fc.FromEtoroReceivedAmount
   ,fc.FromEtoroReceiveBlockchainFee
   ,fc.ReceivedTime
   ,fc.UpdateDate
   ,fc.FromCryptoID	AS FromCryptoIdERC
   ,fc.FromCrypto	AS FromCryptoNameERC
   ,fc.ToCryptoID	AS ToCryptoIdERC
   ,fc.ToCrypto		AS ToCryptoNameERC
   ,du.RealCID
   ,du.IsTestAccount
, du.IsValidCustomer
   ,du.Region
   ,du.Country
   ,iw.InternalType
   ,dr.Name AS Regulation
   ,sp.ShortName AS StateCode
   ,sp.Name AS State
FROM EXW_dbo.EXW_FactConversions fc
JOIN EXW_dbo.EXW_DimUser du
	ON fc.SendingGCID = du.GCID
LEFT JOIN EXW_dbo.EXW_InternalWallet iw
	ON fc.FromAddress = iw.Address
LEFT JOIN DWH_dbo.Dim_Customer dc
	ON fc.RecievingGCID = dc.GCID
LEFT JOIN DWH_dbo.Dim_State_and_Province sp
	ON dc.RegionID = sp.RegionByIP_ID
JOIN DWH_dbo.Dim_Regulation dr
	ON dc.RegulationID = dr.DWHRegulationID
--WHERE fc.ToEtoroDate >= getdate()-30