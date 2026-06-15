SELECT fnl.GCID
	  ,fnl.Country
	  ,fnl.Club
	  ,fnl.IsValidForFunnel
	  ,fnl.IsVerifiedFTD
	  ,fnl.IsVerifiedFTDPlus2Weeks
	  ,fnl.IsActiveMIMO
	  ,fnl.IseMoneyAccount
	  ,fnl.IsFMI
	  ,fnl.IsFMO
	  ,fnl.IsCardCreated
	  ,fnl.IsCardActivated
	  ,fnl.IsCardFirstTx
	  ,fnl.UpdateDate	
      ,CASE WHEN fnl.Club IN ('Bronze') THEN 'NoClub'
            WHEN fnl.Club IN ('Gold','Silver') THEN 'LowClub'
            WHEN fnl.Club IN ('Platinum','Platinum Plus','Diamond') THEN 'HighClub'
       ELSE 'Error' END AS ClubCategory
       ,CASE WHEN mda.AccountSubProgram IS NOT NULL AND mda.AccountSubProgram IN ('IBAN Standard EU Test', 'IBAN LIMITED EU', 'IBAN EU Green', 'IBAN EU Black') THEN 'EU' 
             WHEN mda.AccountSubProgram IS NOT NULL AND mda.AccountSubProgram IN ('Card Premium UK', 'IBAN LIMITED UK', 'Card Standard UK', 'IBAN Standard UK') THEN 'UK' 
             WHEN mda.AccountSubProgram IS NULL AND fnl.Country <> 'United Kingdom' THEN 'EU'
             WHEN mda.AccountSubProgram IS NULL AND fnl.Country = 'United Kingdom' THEN 'UK' 
             ELSE 'Other' END AS UK_EU_Flag 
        ,CASE WHEN fnl.Country='United Kingdom' AND fnl.Club <> 'Bronze' THEN 1 
              WHEN fnl.Country <> 'United Kingdom' AND fnl.Club = 'Diamond' THEN 1 
              ELSE 0 END AS IsCardEligible 
			  , case WHEN mda.AccountProgram = 'card' AND fnl.IsFMI=1 THEN 1 else 0 END AS IsFMIAndCardProgram
      ,mda.RegClub
      ,mda.RegClubCategory
      ,mda.RegCountry
      ,mda.RegRegion
      ,mda.RegPlayerStatus
      ,mda.AccountProgram
	  , mda.AccountSubProgram 
      ,efd.LastSettledTXDate
FROM eMoney_dbo.eMoney_Reports_AcquisitionFunnel fnl WITH(NOLOCK)
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) 
       ON fnl.GCID = mda.GCID 
      AND mda.GCID_Unique_Count = 1
LEFT JOIN eMoney_dbo.eMoney_Panel_FirstDates efd WITH(NOLOCK) 
       ON mda.GCID = efd.GCID