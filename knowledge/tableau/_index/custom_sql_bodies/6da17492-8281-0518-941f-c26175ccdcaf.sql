SELECT 
 ewe.GCID
,ewe.Date
,ewe.RealCID
,CASE WHEN edu.IsTestAccount =1 THEN 'Test'
      WHEN edu.IsValidCustomer =0 THEN 'eTorian'
	  ELSE 'RealUser' END UserType
,ewe.WalletEntity 
,ewe.JoinDate 
,dr.Name Regulation
,dc.Name Country
,ewe.TermsAndConditionDate AS 'TnC Sign Date'
,dpsr.Name PlayerStatusReason
,euswa.UserWalletAllowance AS LastWalletStatus
,bal.ComplianceClosureEvent
,bal.AMLClosureEvent
,bal.BalanceUSD
,edu.CurrentStatus PlayerStatus
FROM  EXW_dbo.EXW_WalletEntity ewe
JOIN DWH_dbo.Dim_Country dc 
ON ewe.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_Regulation dr 
ON ewe.RegulationID = dr.DWHRegulationID
left JOIN EXW_dbo.EXW_UserSettingsWalletAllowance euswa 
ON ewe.GCID = euswa.GCID
JOIN EXW_dbo.EXW_DimUser_Enriched  edu 
ON ewe.GCID = edu.GCID
left JOIN DWH_dbo.Dim_PlayerStatus dps 
ON edu.PlayerStatusID = dps.PlayerStatusID
JOIN DWH_dbo.Dim_Customer dcu
ON ewe.GCID = dcu.GCID
left JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr
ON dcu.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
LEFT JOIN
( SELECT GCID
, SUM(BalanceUSD)BalanceUSD 
, AMLClosureEvent
, ComplianceClosureEvent
, BalanceDate
FROM EXW_dbo.EXW_FinanceReportsBalancesNew 
where	BalanceDate  = COALESCE(CAST (GETDATE()-1 AS date),CAST (GETDATE()-2 AS date))
GROUP BY GCID
        ,AMLClosureEvent
        ,ComplianceClosureEvent
        ,BalanceDate ) bal
        	
ON bal.GCID =ewe.GCID
WHERE ewe.Date = COALESCE(CAST (GETDATE()-1 AS date),CAST (GETDATE()-2 AS date))