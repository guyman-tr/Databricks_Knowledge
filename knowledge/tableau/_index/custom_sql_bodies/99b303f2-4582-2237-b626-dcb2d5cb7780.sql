SELECT 
        ewec.CountryID
		,ewec.Country
		
		,ewec.CountryOpenforWallet
		,ewec.[US State]
		,ewec.Regulation
		,ewec.RegulationID
		, ewec.RegionByIP_ID StateID
		, UpdateDate FROM EXW_dbo.EXW_WalletElligibleCountries ewec