SELECT bddcr.ParentCID,bddcr.Date,(bddcr.Revenue_Real_Stocks+bddcr.Revenue_CFD_Stocks) AS Revenue_Stocks,'Stocks&ETFs' AS InstrumntType
FROM BI_DB..BI_DB_DailyCopyRevenue bddcr
WHERE bddcr.DateID >=CONVERT(CHAR(8), DATEADD(MONTH,-5, DATEFROMPARTS(YEAR(GETDATE()-1),MONTH(GETDATE()-1),1)),112)

UNION ALL

SELECT bddcr.ParentCID,bddcr.Date,(bddcr.Revenue_Real_Crypto + bddcr.Revenue_CFD_Crypto) AS Revenue_Crypto,'Crypto' AS InstrumntType
FROM BI_DB..BI_DB_DailyCopyRevenue bddcr
WHERE bddcr.DateID >=CONVERT(CHAR(8), DATEADD(MONTH,-5, DATEFROMPARTS(YEAR(GETDATE()-1),MONTH(GETDATE()-1),1)),112)

UNION ALL

SELECT bddcr.ParentCID,bddcr.Date,(bddcr.Revenue_Comm) AS Revenue_Comm,'Commodities' AS InstrumntType
FROM BI_DB..BI_DB_DailyCopyRevenue bddcr
WHERE bddcr.DateID >=CONVERT(CHAR(8), DATEADD(MONTH,-5, DATEFROMPARTS(YEAR(GETDATE()-1),MONTH(GETDATE()-1),1)),112)

UNION ALL

SELECT bddcr.ParentCID,bddcr.Date,(bddcr.Revenue_FX) AS Revenue_FX,'Currencies' AS InstrumntType
FROM BI_DB..BI_DB_DailyCopyRevenue bddcr
WHERE bddcr.DateID >=CONVERT(CHAR(8), DATEADD(MONTH,-5, DATEFROMPARTS(YEAR(GETDATE()-1),MONTH(GETDATE()-1),1)),112)

UNION ALL

SELECT bddcr.ParentCID,bddcr.Date,(bddcr.Revenue_Ind) AS Revenue_Ind ,'Indices' AS InstrumntType
FROM BI_DB..BI_DB_DailyCopyRevenue bddcr
WHERE bddcr.DateID >=CONVERT(CHAR(8), DATEADD(MONTH,-5, DATEFROMPARTS(YEAR(GETDATE()-1),MONTH(GETDATE()-1),1)),112)