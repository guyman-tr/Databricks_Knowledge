SELECT a.EOM_ModificationDate
      ,a.DepositStatus
	  ,a.DepositMethod
	  ,a.DepositFundingType
	  ,COUNT(a.DepositID) AS 'Count_Deposits'
FROM(
SELECT EOMONTH(fbd.ModificationDate) AS 'EOM_ModificationDate'
	  ,CASE WHEN fbd.PaymentStatusID = 2 THEN 'Approved' 
	        WHEN fbd.PaymentStatusID IN (1, 5, 11, 12) THEN 'Exclude'
	        WHEN fbd.PaymentStatusID = 6 AND fbd.FundingTypeID IN (35, 37) THEN 'Exclude'
	        WHEN fbd.PaymentStatusID = 13 AND fbd.FundingTypeID IN (1, 34, 11, 28) THEN 'Exclude'
	        ELSE 'Declined' 
	   END AS 'DepositStatus'
	  ,dft.Name AS 'DepositMethod'
	  ,CASE WHEN fbd.FundingTypeID = 2 THEN 'Manual' 
	        WHEN fbd.FundingTypeID = 0 THEN 'Error' 
	        ELSE 'Automatic' END AS 'DepositFundingType'
	  ,fbd.DepositID
FROM DWH.dbo.Fact_BillingDeposit fbd WITH(NOLOCK)
INNER JOIN DWH.dbo.Dim_Customer dc WITH(NOLOCK) ON fbd.CID = dc.RealCID AND dc.IsValidCustomer = 1
INNER JOIN DWH.dbo.Dim_FundingType dft WITH(NOLOCK) ON fbd.FundingTypeID = dft.FundingTypeID
WHERE fbd.ModificationDateID >= CAST(CONVERT(CHAR(8), DATEADD(MONTH,-7, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)), 112) AS INT)
) a WHERE a.DepositStatus != 'Exclude'
GROUP BY a.EOM_ModificationDate
        ,a.DepositStatus
		,a.DepositMethod
	    ,a.DepositFundingType