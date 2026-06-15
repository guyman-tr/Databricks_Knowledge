SELECT b.YearMonth, 
       COUNT(DISTINCT CASE WHEN b.AccountActivated=1 THEN b.AffiliateID END)AccountActivated,
	   COUNT(DISTINCT CASE WHEN b.Registration>0 AND CAST(b.YearMonthID AS INT) BETWEEN CAST(LEFT(CONVERT(VARCHAR(6),DATEADD(MONTH,-3,CAST(CONCAT(b.YearMonth,'-01') AS DATE)),112),4) AS INT) AND CAST(b.YearMonthID AS INT) THEN b.AffiliateID END) RegLast3MonthsAffs,
	   COUNT(DISTINCT CASE WHEN b.FTD>0 AND CAST(b.YearMonthID AS INT) BETWEEN CAST(LEFT(CONVERT(VARCHAR(6),DATEADD(YEAR,-1,CAST(CONCAT(b.YearMonth,'-01') AS DATE)),112),4) AS INT) AND CAST(b.YearMonthID AS INT) THEN b.AffiliateID END) FTDLast3MonthsAffs,
	   COUNT(DISTINCT CASE WHEN b.YearMonthID=CONVERT(VARCHAR(6),b.DateCreated,112) THEN b.AffiliateID END) NewAffiliates
FROM BI_DB..BI_DB_MarketingMonthlyRawData b
WHERE b.YearMonthID>='202101'
GROUP BY b.YearMonth