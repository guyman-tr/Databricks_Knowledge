SELECT map.GCID
      ,map.AccountID
	  ,mda.RegCountry 
	  ,dc.Name AS Country
	  ,fsc.IsValidCustomer
	  ,mda.IsValidETM
	  ,ISNULL(c.AccountSubProgram, map.AccountSubProgram) AS 'AccountSubProgram'
	  ,CASE WHEN sub2.CurrencyBalanceStatusID	  IS NULL   THEN '0'
	        WHEN sub2.CurrencyBalanceStatusID	  = 0   THEN '0'  
	        WHEN sub2.CurrencyBalanceStatusID	  = 1 THEN '1'  
			WHEN sub2.CurrencyBalanceStatusID	  = 2 THEN '2' 
			WHEN sub2.CurrencyBalanceStatusID	  = 3 THEN '3'
			WHEN sub2.CurrencyBalanceStatusID	  = 4 THEN '4'
	        ELSE 'Error' END AccountStatusID
	  ,CASE WHEN sub2.CurrencyBalanceStatus	   IS NULL   THEN 'Active' 
	        WHEN sub2.CurrencyBalanceStatus	  = 'Active'   THEN 'Active'  
	        WHEN sub2.CurrencyBalanceStatus	  = 'Blocked' THEN 'Blocked'  
			WHEN sub2.CurrencyBalanceStatus	  = 'Suspended' THEN 'Suspended'  
			WHEN sub2.CurrencyBalanceStatus	  = 'SpendOnly' THEN 'SpendOnly'  
			WHEN sub2.CurrencyBalanceStatus	  = 'ReceiveOnly' THEN 'ReceiveOnly'   
	        ELSE 'Error' END AccountStatus
	  ,CASE WHEN sub3.GCID IS NOT NULL THEN 1 ELSE 0 END AS Is_Test_User
FROM [eMoney_dbo].[eMoney_Account_Mappings] map WITH(NOLOCK)

LEFT JOIN (
SELECT sub.CurrencyBalanceID
      ,sub.CurrencyBalanceStatusID
      ,sub.CurrencyBalanceStatus
      ,sub.CurrencyBalanceStatusTime
      ,sub.CurrencyBalanceStatusDate 
FROM(SELECT cbs.CurrencyBalancesId AS 'CurrencyBalanceID'
	       ,cbs.StatusType AS 'CurrencyBalanceStatusID'
	       ,dcbs.CurrencyBalanceStatus
	       ,cbs.EventTimestamp AS 'CurrencyBalanceStatusTime'
	       ,CAST(cbs.EventTimestamp AS DATE) AS 'CurrencyBalanceStatusDate'
	       ,ROW_NUMBER() OVER (PARTITION BY cbs.CurrencyBalancesId ORDER BY cbs.EventTimestamp DESC) AS 'RNDesc'
     FROM [eMoney_dbo].[FiatCurrencyBalancesStatuses] cbs WITH(NOLOCK) 
	 LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_CurrencyBalanceStatus] dcbs WITH(NOLOCK) ON cbs.StatusType = dcbs.CurrencyBalanceStatusID
	 WHERE CAST(CONVERT(CHAR(8), cbs.EventTimestamp, 112) AS INT)<=<[Parameters].[Parameter 3]>) sub
WHERE sub.RNDesc = 1 ) sub2 ON sub2.CurrencyBalanceID=map.CurrencyBalanceID

INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON map.GCID = fsc.GCID
INNER JOIN DWH_dbo.Dim_Range drr WITH(NOLOCK) ON fsc.DateRangeID = drr.DateRangeID AND <[Parameters].[Parameter 3]>  BETWEEN drr.FromDateID AND drr.ToDateID
INNER JOIN DWH_dbo.Dim_Country dc WITH(NOLOCK) ON fsc.CountryID = dc.CountryID
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON map.CurrencyBalanceID = mda.CurrencyBalanceID AND mda.AccountCreateDateID <= <[Parameters].[Parameter 3]>
LEFT JOIN (
SELECT DISTINCT sub.GCID 
FROM(SELECT CAST(etu.[gcid] AS INT) AS 'GCID'
	 FROM eMoney_google_sheets.emoney_test_users etu WITH(NOLOCK)
	 WHERE ISNUMERIC(etu.[gcid]) = 1) sub) sub3 ON map.GCID=sub3.GCID

LEFT JOIN (
SELECT sub.AccountID
      ,sub.AccountProgramID
	  ,sub.AccountProgram
      ,sub.AccountSubProgramID
	  ,sub.AccountSubProgram
      ,sub.AccountPropertiesTime
      ,sub.AccountPropertiesDate 
FROM(SELECT fap.AccountId AS 'AccountID'
           ,fap.AccountProgramId AS 'AccountProgramID'
		   ,dapm.AccountProgram AS 'AccountProgram'
		   ,fap.SubProgramId AS 'AccountSubProgramID'
		   ,dsub.AccountSubProgram AS 'AccountSubProgram'
		   ,fap.Created AS 'AccountPropertiesTime'
	       ,CAST(fap.Created AS DATE) AS 'AccountPropertiesDate'
	       ,ROW_NUMBER() OVER (PARTITION BY fap.AccountId ORDER BY fap.Created DESC) AS 'RNDesc'
     FROM [eMoney_dbo].[FiatAccountsProperties] fap WITH(NOLOCK)
	 LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_AccountProgram] dapm WITH(NOLOCK) ON fap.AccountProgramId = dapm.AccountProgramID
     LEFT JOIN [eMoney_dbo].[eMoney_Dictionary_AccountSubProgram] dsub WITH(NOLOCK) ON fap.SubProgramId = dsub.AccountSubProgramID 
	 WHERE CAST(CONVERT(CHAR(8), fap.Created, 112) AS INT)<=<[Parameters].[Parameter 3]>) sub
WHERE sub.RNDesc = 1) c ON c.AccountID=map.AccountID