SELECT  dc.GCID,
CAST(fbw.ModificationDate AS DATE) [Date] ,
CASE WHEN mda.GCID IS NULL THEN 0 ELSE 1 END AS IseTMAccount,
dc1.Name AS [Country],
SUM(fbw.AmountUSD) AS Amount,

SUM(CASE WHEN fbw.FundingTypeID=33 THEN fbw.AmountUSD ELSE NULL end) AS eMoney_Amount,
SUM(CASE WHEN fbw.FundingTypeID<>33 THEN fbw.AmountUSD ELSE NULL end) AS Other_MOP_Amount,
SUM(CASE WHEN fbw.FundingTypeID=33 THEN 1 ELSE 0 END) AS isMoneyTrn,
COUNT(*) AS total_trn
 FROM DWH..Fact_BillingDeposit fbw
 INNER JOIN DWH..Dim_Customer dc 
 ON dc.RealCID=fbw.CID and dc.VerificationLevelID=3 AND dc.IsValidCustomer=1 AND dc.IsDepositor=1
 INNER JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID
 left JOIN eMoney_Dim_Account mda ON mda.CID=dc.RealCID AND mda.IsValidETM=1
 JOIN [DWH].[dbo].[Dim_FundingType] df ON df.FundingTypeID = fbw.FundingTypeID
 WHERE    CAST(fbw.ModificationDate AS DATE)  >= DATEADD(mm,-6,GETDATE()-1)
 AND fbw.PaymentStatusID=2
 GROUP BY dc.GCID,
 dc1.Name ,
CAST(fbw.ModificationDate AS DATE) ,
CASE WHEN mda.GCID IS NULL THEN 0 ELSE 1 END