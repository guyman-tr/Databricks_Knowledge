SELECT DISTINCT 
      -- v.[Id]
      -- ,v.[CryptoId]
      --,v.[Address]
      --,v.[BlockchainProviderWalletId]
      --,v.[Occurred]
      --,v.[WalletTypeId]
      --,v.[IsActive]
      --,v.[Status]
      --,v.[WalletRecordId]
      --,v.[BlockchainCryptoId]
	  cc. CID
	  ,cc. CountryID
	  , cc.GCID
	    ,v.[Gcid]
		, c.Name AS Country
		, r.Name Regulation
		, cus.VerificationLevelID
  FROM [Wallet_Server_WalletDB].[WalletDB].[Wallet].[CustomerWalletsView] v WITH (NOLOCK)
  JOIN   [AZR-W-REAL-DB-2-BIDBUser].etoro.Customer.Customer cc WITH (NOLOCK)ON cc.GCID =v.Gcid
 JOIN  [AZR-W-REAL-DB-2-BIDBUser].etoro.[Dictionary].[Country] c WITH (NOLOCK)ON  cc.CountryID = c.CountryID
 JOIN  [AZR-W-REAL-DB-2-BIDBUser].[etoro].[BackOffice].[Customer] cus WITH (NOLOCK) ON cus.CID=cc.CID 
 JOIN [AZR-W-REAL-DB-2-BIDBUser].etoro.[Dictionary].[Regulation] r WITH (NOLOCK) ON cus.RegulationID =r.ID
 -- WHERE cc. CountryID=169

  WHERE cc. CountryID =  <[Parameters].[Parameter 1]>