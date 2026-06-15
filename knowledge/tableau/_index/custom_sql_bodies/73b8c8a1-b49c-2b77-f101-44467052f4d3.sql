SELECT EOMONTH(fca.Occurred) AS 'ActionDate'
	  ,dat.Name AS 'ActionType'
	  ,dft.Name AS 'FundingType'
	  ,SUM(fca.Amount) AS 'SumAmount'
FROM DWH.dbo.Fact_CustomerAction fca WITH(NOLOCK)
INNER JOIN DWH.dbo.Dim_ActionType dat WITH(NOLOCK) ON fca.ActionTypeID = dat.ActionTypeID
INNER JOIN DWH.dbo.Dim_FundingType dft WITH(NOLOCK) ON fca.FundingTypeID = dft.FundingTypeID
INNER JOIN DWH.dbo.Dim_Customer dc WITH(NOLOCK) ON fca.GCID = dc.GCID 
                                                AND dc.IsDepositor = 1
                                                AND dc.IsValidCustomer = 1
	                                            AND dc.VerificationLevelID = 3
	                                            AND dc.CountryID IN (218, 54, 100, 168)
	                                            AND dc.PlayerStatusID NOT IN (2, 4, 14, 15)
WHERE fca.DateID >= CAST(CONVERT(CHAR(8), DATEADD(DAY,1,EOMONTH(GETDATE(),-1)), 112) AS INT)
      AND fca.ActionTypeID IN (7, 8)
GROUP BY EOMONTH(fca.Occurred)
	    ,dat.Name
	    ,dft.Name