SELECT  a.CID
       ,a.Risk_Final_Result
	   ,a.CountryAddress
	   ,a.CountryCitizenship
	   ,a.CountryPOB
	   ,a.Regulation
	   ,CASE WHEN dc.PlayerStatusID=13 THEN 0
	         WHEN dc.PlayerStatusID=1 THEN 1
			 WHEN dc.PlayerStatusID IN (3,5,12) THEN 2
			 WHEN dc.PlayerStatusID IN (10,11) THEN 2
			 WHEN dc.PlayerStatusID IN (9,15) THEN 2
			 WHEN dc.PlayerStatusID IN (2,4,6,7,8,14) THEN 3
	      ELSE 'Error' END AS Player_Status_Score_2
	   ,dps.*
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment a
INNER JOIN DWH_dbo.Dim_Customer dc ON a.GCID = dc.GCID
INNER JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID