SELECT map.GCID
      ,map.AccountID
	  ,mda.RegCountry AS Country
	  ,mda.IsValidETM
	  ,ssdss.Name ScreeningStatus
	  ,mda.AccountSubProgram
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
	,sub2.CurrencyBalanceStatusTime
FROM [eMoney_dbo].[eMoney_Account_Mappings] map WITH(NOLOCK)
JOIN eMoney_dbo.eMoney_Dim_Account mda ON map.GCID = mda.GCID
JOIN DWH_dbo.Dim_Customer dc ON map.GCID = dc.GCID
JOIN DWH_staging.ScreeningService_Dictionary_ScreeningStatus ssdss ON dc.ScreeningStatusID=ssdss.ID
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
	 WHERE CAST(CONVERT(CHAR(8), cbs.EventTimestamp, 112) AS INT)<=<[Parameters].[Parameter 1]>) sub
WHERE sub.RNDesc = 1 ) sub2 ON sub2.CurrencyBalanceID=map.CurrencyBalanceID
WHERE mda.GCID_Unique_Count=1
AND mda.IsTestAccount=0
AND mda.AccountSubProgramID IN (6,7,9)
AND dc.ScreeningStatusID IN (4,7,3)