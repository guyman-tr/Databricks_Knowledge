SELECT 
       bdad.CID,
	   bdad.DepositID,
	   CAST(bdad.ModificationDate AS DATE) AS ModificationDate,
          CONVERT(VARCHAR(6),bdad.ModificationDate,112) AS YearMonth,
	   frst.NewMarketingRegion, 
	   frst.Country,
	   frst.Club,
       bdad.FundingType, 
       COUNT(bdad.DepositID) AS _Try,
       SUM([Amount in $]) AS Amount,
       ld.LastDepositDate,
	   ld.LastDepositAmount,
	   inf.VerificationLevelID,
	   inf.AM_FirstName,
	   inf.AM_LastName,
	   DepCo.TotalDeposit,
	   DepCo.TotalCashout,
	   c.ActionName,
	   c.CreatedDate_SF Last_Contact_Date,
    case WHEN CAST(bdad.ModificationDate AS DATE) > ld.LastDepositDate
	OR ld.LastDepositDate IS null  THEN 'Not Deposit After Try' 
    ELSE 'Deposited After Try' 
END AS DepositAfter_Status,

                CASE WHEN [Amount in $] >= 0  AND[Amount in $]  <= 999.99 THEN '$0-$1,000' 
              WHEN [Amount in $]  >= 1000  AND [Amount in $]  <= 4999.99 THEN '$1,000-$5,000' 
              WHEN [Amount in $]  >= 5000  AND [Amount in $]  <= 9999.99 THEN '$5,000-$10,000' 
              WHEN [Amount in $]  >= 10000  AND [Amount in $]  <= 24999.99 THEN '$10,000-$25,000' 
              WHEN [Amount in $]  >= 25000  AND [Amount in $]  <= 49999.99 THEN '$25,000-$50,000' 
              WHEN [Amount in $]  >= 50000  AND [Amount in $]  <= 99999.99 THEN '$50000-$100,000' 
              WHEN [Amount in $]  >= 100000   THEN '$100,000+' 
              ELSE 'other' END AS Amount_Tier

FROM BI_DB_dbo.BI_DB_AllDeposits bdad
JOIN DWH_dbo.Dim_Customer dc ON bdad.CID = dc.RealCID AND dc.IsValidCustomer = 1
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID 
JOIN BI_DB_dbo.BI_DB_CIDFirstDates as frst ON frst.CID = dc.RealCID
LEFT JOIN #LastDep AS ld ON ld.CID = bdad.CID
LEFT JOIN #inf AS inf ON inf.CID = bdad.CID
LEFT JOIN #DepCo AS DepCo ON DepCo.CID = bdad.CID
LEFT JOIN #Contact c ON c.CID=bdad.CID
WHERE bdad.ModificationDateID >= 20250101
AND bdad.FundingType = 'WireTransfer'
AND  bdad.PaymentStatus = 'InProcess'

GROUP BY 
       bdad.CID,
	   bdad.DepositID,
	   frst.NewMarketingRegion, 
	   frst.Club,
	   frst.Country,
       CAST(bdad.ModificationDate AS DATE) ,
       dc1.MarketingRegionManualName,
       bdad.FundingType, 
	   c.ActionName,
	   c.CreatedDate_SF,
         CASE WHEN [Amount in $] >= 0  AND[Amount in $]  <= 999.99 THEN '$0-$1,000' 
              WHEN [Amount in $]  >= 1000  AND [Amount in $]  <= 4999.99 THEN '$1,000-$5,000' 
              WHEN [Amount in $]  >= 5000  AND [Amount in $]  <= 9999.99 THEN '$5,000-$10,000' 
              WHEN [Amount in $]  >= 10000  AND [Amount in $]  <= 24999.99 THEN '$10,000-$25,000' 
              WHEN [Amount in $]  >= 25000  AND [Amount in $]  <= 49999.99 THEN '$25,000-$50,000' 
              WHEN [Amount in $]  >= 50000  AND [Amount in $]  <= 99999.99 THEN '$50000-$100,000' 
              WHEN [Amount in $]  >= 100000   THEN '$100,000+' 
              ELSE 'other' END,

	CASE 
    WHEN CAST(bdad.ModificationDate AS DATE) > ld.LastDepositDate
	OR ld.LastDepositDate IS null  THEN 'Not Deposit After Try' 
    ELSE 'Deposited After Try' 
    END,
	ld.LastDepositDate,
	ld.LastDepositAmount,
	inf.VerificationLevelID,
	inf.AM_FirstName,
	inf.AM_LastName,
	DepCo.TotalDeposit,
	DepCo.TotalCashout,
    CONVERT(VARCHAR(6),bdad.ModificationDate,112)