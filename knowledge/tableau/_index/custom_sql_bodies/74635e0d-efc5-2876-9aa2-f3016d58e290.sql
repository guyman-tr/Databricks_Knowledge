SELECT EOMONTH(fca.Occurred) AS 'Month'
      ,dat.[Name] AS 'ActionType'
      ,dft.[Name] AS 'FundingType'
      ,COUNT(DISTINCT fca.GCID) AS 'DistinctGCIDs'
      ,SUM(fca.Amount) AS 'SumAmount'
      ,COUNT(fca.GCID) AS 'CountTransactions'
FROM DWH_dbo.Fact_CustomerAction fca WITH(NOLOCK)
INNER JOIN DWH_dbo.Dim_FundingType dft WITH(NOLOCK) ON fca.FundingTypeID = dft.FundingTypeID
INNER JOIN DWH_dbo.Dim_ActionType dat WITH(NOLOCK) ON fca.ActionTypeID = dat.ActionTypeID
INNER JOIN DWH_dbo.Dim_Customer dc WITH(NOLOCK) ON fca.RealCID = dc.RealCID
INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout mdcr WITH(NOLOCK) ON dc.CountryID = mdcr.CountryID
AND dc.IsValidCustomer = 1 
AND dc.VerificationLevelID = 3 
AND dc.IsDepositor=1
WHERE fca.ActionTypeID IN (7,8) 
AND fca.DateID >= 20221001
GROUP BY EOMONTH(fca.Occurred)
,dat.[Name]
,dft.[Name]