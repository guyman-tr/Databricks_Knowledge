SELECT 
       LEFT(bdad.ModificationDateID, 6) AS YearMonth,
	   bdad.CID,
	   bdad.ModificationDate AS ModificationDate,
	   cast (bdad.ModificationDate AS DATE) AS cast_ModificationDate,
	   dc.FirstDepositDate AS FTDDate,
	   cast (dc.FirstDepositDate AS DATE) AS cast_FTDDate,
	  
	   CASE WHEN bdad.ModificationDate > dc.FirstDepositDate THEN 'Redeposit'
	        WHEN bdad.ModificationDate <= dc.FirstDepositDate THEN 'FTD'
			ELSE 'Other' END AS 'DepositType',

       dc1.MarketingRegionManualName AS Region,
       dc1.Name AS Country, 
	   frst.Channel, 
	   frst.SubChannel,
       bdad.FundingType, 
	   bdad.CardType, 
    -- SUM(CASE WHEN bdad.PaymentStatus = 'Approved' THEN 1 ELSE 0 END) * 1.00 / COUNT(*) AS '%Approved',
       COUNT(bdad.DepositID) AS _Try,
       SUM(CASE WHEN bdad.PaymentStatus = 'Approved' THEN 1 ELSE 0 END) AS Approved,
       SUM(CASE WHEN bdad.PaymentStatus != 'Approved' THEN 1 ELSE 0 END) AS Declined,
	   bdad.PaymentStatus,
	   [Amount in $] AS AmountPayment

FROM BI_DB_dbo.BI_DB_AllDeposits bdad
JOIN DWH_dbo.Dim_Customer dc ON bdad.CID = dc.RealCID AND dc.IsValidCustomer = 1
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID 
JOIN BI_DB_dbo.BI_DB_CIDFirstDates as frst ON frst.CID = bdad.CID 

WHERE 
 bdad.ModificationDateID >= 20250101

GROUP BY LEFT(bdad.ModificationDateID, 6),
         dc1.MarketingRegionManualName, 
		 bdad.CID,
         bdad.ModificationDate ,
	     cast(bdad.ModificationDate AS DATE),
	     dc.FirstDepositDate,
	     cast(dc.FirstDepositDate AS DATE),
         dc1.Name,
	     frst.Channel, 
	     frst.SubChannel,
         bdad.FundingType,
		 bdad.CardType,
	     bdad.PaymentStatus,
		 [Amount in $],
		  CASE WHEN bdad.ModificationDate > dc.FirstDepositDate THEN 'Redeposit'
	      WHEN bdad.ModificationDate <= dc.FirstDepositDate THEN 'FTD'
	 	  ELSE 'Other' END