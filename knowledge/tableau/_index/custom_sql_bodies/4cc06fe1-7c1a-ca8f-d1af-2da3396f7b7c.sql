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
	   ELSE 'Error' END AS 'ClubCategory'
	  ,mda.RegClub
	  ,mda.RegClubCategory
	  ,mda.RegCountry
	  ,mda.RegRegion
	  ,mda.RegPlayerStatus
, mda.AccountSubProgramID
	, mda.Entity
, mda.AccountSubProgram
      ,mda.AccountProgram
	  ,efd.LastSettledTXDate
FROM eMoney_dbo.eMoney_Reports_AcquisitionFunnel fnl WITH(NOLOCK)
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON fnl.GCID = mda.GCID and mda.GCID_Unique_Count=1

LEFT JOIN eMoney_dbo.eMoney_Panel_FirstDates efd WITH(NOLOCK) ON mda.GCID = efd.GCID