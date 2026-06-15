SELECT mda.CID
      ,mda.GCID
	  ,mda.ClubID
	  ,mda.Club
	  ,mda.ClubCategory
	  ,mda.RegClubID
	  ,mda.RegClub
	  ,mda.CountryID
	  ,mda.Country
	  ,mda.RegCountryID
	  ,mda.RegCountry
	  ,mda.RegAccountSubProgramID
	  ,mda.RegAccountSubProgram
	  ,mda.HasAccountSubProgramChanged
	  ,mda.AccountSubProgramID
	  ,mda.AccountSubProgram
	  ,mda.CountAccountSubProgramChanges
	  ,mda.RegAccountProgram
	  ,mda.AccountProgram
	  ,mda.CountAccountProgramChanges
	  ,mda.AccountPropertiesTime
	  ,mda.AccountPropertiesDate
	  ,mda.HasCard
	  ,mda.AccountID
	  ,mda.ProviderHolderID AS HolderID
	  ,mda.CardCreateDate
	  ,mda.CardStatus
	  ,CASE WHEN mda.AccountSubProgramID=1 THEN 'UK Black Card' 
	        WHEN mda.AccountSubProgramID=2 THEN 'UK Green Card'
			WHEN mda.AccountSubProgramID=3 THEN 'UK IBANO' 
	        WHEN mda.AccountSubProgramID=4 THEN 'UK IBANO'
			WHEN mda.AccountSubProgramID=5 THEN 'Test' 
	        WHEN mda.AccountSubProgramID=6 THEN 'EU IBANO Green'
			WHEN mda.AccountSubProgramID=7 THEN 'EU IBANO Black' 
	        WHEN mda.AccountSubProgramID=8 THEN 'eMoney FTD-Temp Program for FTD flow'
			WHEN mda.AccountSubProgramID=9 THEN 'eMoney FTD-Temp Program for FTD flow'
	  ELSE NULL
	  END AS [Destination Program]
	  ,CASE WHEN mda.RegAccountSubProgramID=1 THEN 'UK Black Card' 
	        WHEN mda.RegAccountSubProgramID=2 THEN 'UK Green Card'
			WHEN mda.RegAccountSubProgramID=3 THEN 'UK IBANO' 
	        WHEN mda.RegAccountSubProgramID=4 THEN 'UK IBANO'
			WHEN mda.RegAccountSubProgramID=5 THEN 'Test' 
	        WHEN mda.RegAccountSubProgramID=6 THEN 'EU IBANO Green'
			WHEN mda.RegAccountSubProgramID=7 THEN 'EU IBANO Black' 
	        WHEN mda.RegAccountSubProgramID=8 THEN 'eMoney FTD-Temp Program for FTD flow'
			WHEN mda.RegAccountSubProgramID=9 THEN 'eMoney FTD-Temp Program for FTD flow'
	  ELSE NULL
	  END AS [Source Program]
FROM eMoney_dbo.eMoney_Dim_Account mda
WHERE mda.IsValidETM=1 
AND mda.IsValidCustomer=1