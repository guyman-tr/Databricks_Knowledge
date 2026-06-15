SELECT DISTINCT
	bdsajlt.GCID
   ,bdcd.CID
   ,bdcd.NewMarketingRegion AS [Region]
   ,bdcd.Country
   ,LEFT(CONVERT(CHAR(8),bdcd.registered,112),6) RegistrationMonth
   ,dr.[Name] Regulation
   ,MAX(CASE WHEN ad.CID IS NOT NULL THEN 1 ELSE 0 END) Redeposit
   ,MAX(CASE WHEN fca.GCID IS NOT NULL THEN 1 ELSE 0 END) Login
   ,bdfa.FirstAction_Detailed
   ,SUM(CASE WHEN fca.GCID IS NOT NULL THEN 1 ELSE 0 END) NumOfLogins
   ,CASE WHEN bdkscl.Cluster  IN ('1','2','3') THEN 'Low'
		  WHEN bdkscl.Cluster  IN ('4','5','6') THEN 'Medium'
		  WHEN bdkscl.Cluster  IN ('7','8','9','10') THEN 'High'
		  ELSE 'No Cluster' END AS LeadScore

   ,bdcd.Language
   ,CASE WHEN bdsajlt.[Action]='TestGroup' THEN 'Test' ELSE 'Control' END AS [Group]
   ,bdsajlt.TimeStampConvert  AS [CampaignEntryDate]
   ,bdcd.registered AS RegistrationDate
   ,bdcd.FirstPosOpenDate
   ,CASE WHEN bdcd.FirstDepositAmount=0 THEN NULL ELSE bdcd.FirstDepositAmount END AS  FTDA
   ,bdcd.FirstDepositDate  AS [FTD_Date]
   ,bdcd.FirstNewFundedDate AS [FirstFundedDate] 
FROM BI_DB_SFMC_AccountJourneyLogTracking bdsajlt WITH (NOLOCK)
LEFT JOIN BI_DB_CIDFirstDates bdcd WITH (NOLOCK)
	ON bdsajlt.GCID = bdcd.GCID
LEFT JOIN BI_DB_KYC_Score_CID_Level bdkscl 
	ON bdcd.CID=bdkscl.RealCID
LEFT JOIN BI_DB_First5Actions bdfa 
ON bdcd.CID = bdfa.CID
LEFT JOIN DWH..Fact_CustomerAction fca ON fca.GCID=bdsajlt.GCID		
    and fca.ActionTypeID = 14 and datediff(DAY,TimeStampConvert,Occurred)<=17
LEFT JOIN DWH..Dim_Regulation_2022 dr ON bdcd.RegulationID=dr.ID
LEFT JOIN BI_DB..BI_DB_AllDeposits ad ON bdcd.CID = ad.CID AND datediff(DAY,CAST(bdsajlt.TimeStampConvert AS DATE),ad.[Deposit Time])<=17 AND ad.Category='REDEPOSIT'
WHERE bdsajlt.Journey_Name = 'LeadsOnboardingJourney'
AND bdsajlt.Action IN ('TestGroup', 'ControlGroup')
AND bdsajlt.GCID IS NOT NULL
AND bdsajlt.TimeStampConvert>'2022-07-05'
AND bdcd.registered is not null
GROUP BY bdsajlt.GCID
   ,bdcd.CID
   ,bdcd.NewMarketingRegion 
   ,bdcd.Country
   ,LEFT(CONVERT(CHAR(8),bdcd.registered,112),6) 
   ,dr.[Name] 
   ,bdfa.FirstAction_Detailed
   ,CASE WHEN bdkscl.Cluster  IN ('1','2','3') THEN 'Low'
		  WHEN bdkscl.Cluster  IN ('4','5','6') THEN 'Medium'
		  WHEN bdkscl.Cluster  IN ('7','8','9','10') THEN 'High'
		  ELSE 'No Cluster' END
   , bdcd.Language
   ,CASE WHEN bdsajlt.[Action]='TestGroup' THEN 'Test' ELSE 'Control' END 
   ,bdsajlt.TimeStampConvert 
   ,bdcd.registered 
   ,bdcd.FirstPosOpenDate
   ,CASE WHEN bdcd.FirstDepositAmount=0 THEN NULL ELSE bdcd.FirstDepositAmount END 
   ,bdcd.FirstDepositDate 
   ,bdcd.FirstNewFundedDate