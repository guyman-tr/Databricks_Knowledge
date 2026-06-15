SELECT 
  dc.GCID
 ,dc.RealCID
 ,at.Name AS AccountType
 ,at2.Name AS PrevAccountType
 ,u.Change_Date AccountTypeChangeDate
 ,c.Name Country
 ,r.Name Regulation
 ,ps.Name PlayerStatus
 ,dpl.Name Club
 ,sr.Name PlayerStatusReason
 ,ssr.PlayerStatusSubReasonName  PlayerStatusSubReason
 ,edue.JoinDate WalletJoinDate
 ,dc.HasWallet
 ,euswa.UserWalletAllowance
 ,dss.Name ScreeningStatus
 ,CASE WHEN s.SelectedValue IS NOT NULL AND s.SelectedValue =0 THEN 'Manual Block'  
       WHEN s.SelectedValue IS NOT NULL AND s.SelectedValue =1 THEN 'Manual Read Only'  
	   WHEN s.SelectedValue IS NOT NULL AND s.SelectedValue =2 THEN 'Manual Open'
	   ELSE 'NA'  END ManualWalletStatus
 ,IsWalletOpenCountry
,dc.RegisteredReal
FROM DWH_dbo.Dim_Customer dc 
LEFT JOIN  DWH_dbo.Dim_AccountType at ON dc.AccountTypeID = at.AccountTypeID
LEFT JOIN DWH_dbo.Dim_Country c ON dc.CountryID = c.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation r ON r.DWHRegulationID =dc.RegulationID
LEFT JOIN DWH_dbo.Dim_PlayerStatus ps ON dc.PlayerStatusID = ps.PlayerStatusID
LEFT JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_PlayerStatusReasons  sr ON dc.PlayerStatusReasonID = sr.PlayerStatusReasonID
LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons ssr ON dc.PlayerStatusSubReasonID = ssr.PlayerStatusSubReasonID
LEFT JOIN EXW_dbo.EXW_DimUser edu ON dc.GCID = edu.GCID 
LEFT JOIN EXW_dbo.EXW_DimUser_Enriched edue ON edu.GCID = edue.GCID
LEFT JOIN EXW_dbo.EXW_UserSettingsWalletAllowance euswa ON edu.GCID = euswa.GCID
LEFT JOIN #setprep s ON dc.GCID = s.Gcid
LEFT JOIN #users u ON dc.RealCID = u.RealCID 
LEFT JOIN  DWH_dbo.Dim_AccountType at2 ON u.PrevAccountTypeID = at2.AccountTypeID
LEFT JOIN  DWH_dbo.Dim_ScreeningStatus dss ON dc.ScreeningStatusID = dss.ScreeningStatusID
LEFT JOIN (SELECT DISTINCT CountryID,RegulationID, CountryOpenforWalletDescription IsWalletOpenCountry 
FROM  EXW_dbo.EXW_WalletElligibleCountries) ewec ON dc.CountryID = ewec.CountryID AND dc.RegulationID =ewec.RegulationID  
WHERE 1=1
 --AND  dc.AccountTypeID =2
 AND dc.CountryID NOT IN (74,219,79, 143,144) --France,Germany,United States,Netherlands,Netherlands Antilles
 AND dc.RegulationID NOT IN (6,7,8) --eToroUS, FinCEN,FinCEN+FINRA
  AND dc.ScreeningStatusID = 3    --PEP
AND dc.VerificationLevelID =3