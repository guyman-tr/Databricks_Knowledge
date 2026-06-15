SELECT DATEFROMPARTS(YEAR(cl.Date),MONTH(cl.Date),1) Active_Date
        ,cl.UpgradeDate
		,cl.Deposit_Date
        ,cl.CID
		,cl.AccountManager
		,cl.ClubEquity
		,cl.Date
		,cl.IsUpgrade
		,cl.ClubTier
        ,CASE WHEN oa.CID IS NOT NULL THEN 1 ELSE 0 END IsRelevant
		,oa.CreatedDate_SF ContactDate
FROM #LastDeposit  cl
OUTER APPLY  
(SELECT TOP 1 * 
FROM #UsageTracking_SF bduts
where bduts.CID=cl.CID
AND cl.UpgradeDate >= ISNULL(bduts.CreatedDate_SF, '29991231') 
AND DATEDIFF(dd, ISNULL(bduts.CreatedDate_SF, '29991231'), cl.UpgradeDate) <= 30 
ORDER BY bduts.CreatedDate_SF)oa
GROUP BY DATEFROMPARTS(YEAR(cl.UpgradeDate),MONTH(cl.UpgradeDate),1) 
          ,cl.UpgradeDate
		,cl.Deposit_Date
        ,cl.CID
		,cl.AccountManager
		,cl.ClubEquity
		,cl.Date
		,cl.IsUpgrade
		,cl.ClubTier
        ,CASE WHEN oa.CID IS NOT NULL THEN 1 ELSE 0 END
		,oa.CreatedDate_SF