SELECT	 CONCAT(YEAR(sub.OccurredDate),'-',MONTH(sub.OccurredDate),'-01') AS 'ActiveMonth'
		,sub.CID
		,sub.RegAccountSubProgram
		,sub.BankAccountIBAN
		,SUM(CASE WHEN sub.PreviousOccurred IS NULL THEN 1 ELSE 0 END) AS 'IsOpenFirstTime'
FROM (
SELECT fca.RealCID AS 'CID'
           ,CAST(fca.Occurred AS DATE) AS 'OccurredDate'
		   ,fca.Occurred
           ,fca.DateID AS 'OccurredDateID'
           ,fsc.IsValidCustomer
           ,fsc.CountryID
	       ,fsc.PlayerLevelID
           ,fca.Amount
           ,fca.ActionTypeID
		   ,mda.RegAccountSubProgram
           ,mda.BankAccountIBAN
		   ,lag(fca.Occurred) OVER(PARTITION BY fca.RealCID ORDER BY fca.Occurred) AS PreviousOccurred
     FROM [DWH_dbo].[Fact_CustomerAction] fca WITH(NOLOCK)
     INNER JOIN [DWH_dbo].[Fact_SnapshotCustomer] fsc WITH(NOLOCK) ON fca.RealCID = fsc.RealCID
     INNER JOIN [DWH_dbo].[Dim_Range] drg WITH(NOLOCK) ON fsc.DateRangeID = drg.DateRangeID AND fca.DateID BETWEEN drg.FromDateID AND drg.ToDateID 
	 INNER JOIN eMoney_dbo.eMoney_Dim_Account mda ON fca.GCID = mda.GCID AND mda.GCID_Unique_Count=1
     WHERE fca.ActionTypeID = 44 AND fca.DateID >= 20240401
	 ) sub
GROUP BY	CONCAT(YEAR(sub.OccurredDate),'-',MONTH(sub.OccurredDate),'-01')
			,sub.CID
			,sub.RegAccountSubProgram
			,sub.BankAccountIBAN