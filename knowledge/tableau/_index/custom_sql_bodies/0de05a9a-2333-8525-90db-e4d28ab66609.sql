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
,dps.Name PlayerStatus
,dpsr.Name PlayerStatusReason
,euswa.UserWalletAllowance AS LastWalletStatus
,bal.UserWalletAllowance WalletStatusForDate
,bal.ComplianceClosureEvent
,bal.AMLClosureEvent
,bal.BalanceUSD
FROM  EXW_dbo.EXW_WalletEntity ewe
JOIN DWH_dbo.Fact_SnapshotCustomer fsc  
ON fsc.RealCID = ewe.RealCID
JOIN DWH_dbo.Dim_Range dra 
ON fsc.DateRangeID = dra.DateRangeID
AND ewe.DateID BETWEEN dra.FromDateID AND dra.ToDateID
JOIN DWH_dbo.Dim_Country dc 
ON ewe.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_Regulation dr 
ON ewe.RegulationID = dr.DWHRegulationID
JOIN DWH_dbo.Dim_PlayerStatus dps 
ON fsc.PlayerStatusID = dps.PlayerStatusID
JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr
ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
JOIN EXW_dbo.EXW_UserSettingsWalletAllowance euswa 
ON ewe.GCID = euswa.GCID
JOIN EXW_dbo.EXW_DimUser edu 
ON ewe.GCID = edu.GCID
LEFT JOIN
( SELECT GCID
, SUM(BalanceUSD)BalanceUSD 
, AMLClosureEvent
, ComplianceClosureEvent
, BalanceDate
, UserWalletAllowance 
FROM EXW_dbo.EXW_FinanceReportsBalancesNew 
GROUP BY GCID
        ,AMLClosureEvent
        ,ComplianceClosureEvent
        ,BalanceDate
        ,UserWalletAllowance)bal
ON bal.BalanceDate = ewe.Date
AND bal.GCID =ewe.GCID
WHERE ewe.Date >=<[Parameters].[Parameter 1]>
AND ewe.Date<= <[Parameters].[Parameter 2]>