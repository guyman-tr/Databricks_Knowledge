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
,mda.AccountProgram
	  ,efd.LastSettledTXDate
FROM eMoney.dbo.eMoney_Reports_AcquisitionFunnel fnl
LEFT JOIN eMoney.dbo.eMoney_Dim_Account mda ON fnl.GCID = mda.GCID
LEFT JOIN eMoney.dbo.eMoney_Panel_FirstDates efd ON mda.GCID = efd.GCID