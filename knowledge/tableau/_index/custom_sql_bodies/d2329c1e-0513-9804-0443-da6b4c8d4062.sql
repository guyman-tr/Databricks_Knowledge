SELECT  
         du.GCID
       , du.RealCID
	   , v.Address 'Sender Blockchain Address'
       ,ta.[Id] AS TravelRulesID
      ,ta.[WalletId]
      ,ta.[ToAddress]   'To Blockchain Address'
      ,ta.[TravelRuleAddressTypeId]
      ,ta.[SelfAccount]
      ,ta.[HostingCompany]
      ,ta.[Name]
      ,ta.[CountryAlpha3Code]
      ,ta.[State]
      ,ta.[City]
      ,ta.[Address] 'Customer Address'
      ,ta.[Zipcode]
      ,ta.[Created]
	  ,t.Name AS AddressType
	 
 FROM  Wallet_Server_WalletDB.WalletDB.[Wallet].[TravelRuleAddresses] ta
    JOIN Wallet_Server_WalletDB.WalletDB.[Dictionary].[TravelRuleAddressType] t ON ta.TravelRuleAddressTypeId = t.Id
	JOIN EXW.[dbo].[ETL_CustomerWalletsView]  v  ON v.Id = ta.[WalletId] 
	JOIN EXW.[dbo].[EXW_DimUser] du ON v.Gcid = du.GCID
	WHERE v.CryptoId=v.BlockchainCryptoId