SELECT a.ModificationDate
	  ,a.DepositStatus
	  ,a.DepositID
	  ,a.Deposit_Indicator
	  ,a.IsWireTransfer 
	  ,NewMarketinRegion
FROM 
(SELECT fbd.ModificationDate  AS 'ModificationDate'
	  ,CASE WHEN fbd.PaymentStatusID = 2 THEN 'Approved' 
			WHEN fbd.PaymentStatusID IN (1, 5, 11, 12) THEN 'Exclude'
			WHEN fbd.PaymentStatusID = 6 AND fbd.FundingTypeID IN (35, 37) THEN 'Exclude'
			WHEN fbd.PaymentStatusID = 13 AND fbd.FundingTypeID IN (1, 34, 11, 28) THEN 'Exclude'
			ELSE 'Declined' END AS 'DepositStatus'
	  ,CASE WHEN fbd.FundingTypeID =2 THEN 1 ELSE 0 END IsWireTransfer 
      ,fbd.DepositID
	  ,1 AS 'Deposit_Indicator'
	  ,dc1.MarketingRegionManualName NewMarketinRegion
FROM DWH.dbo.Fact_BillingDeposit fbd WITH(NOLOCK)
INNER JOIN DWH.dbo.Dim_Customer dc ON fbd.CID = dc.RealCID AND dc.IsValidCustomer = 1
INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
WHERE fbd.ModificationDateID >= CAST(CONVERT(CHAR(8), DATEADD(MONTH,-3, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)), 112) AS INT)
AND fbd.PaymentStatusID = 2 
) a