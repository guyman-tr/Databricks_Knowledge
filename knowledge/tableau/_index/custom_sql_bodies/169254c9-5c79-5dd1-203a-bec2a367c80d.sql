SELECT 
bd.FirstAction_Detailed FirstAction,
NewMarketingRegion region,
Country,
'Q' + CAST(DATEPART(QUARTER, bd.FirstDepositDate) AS VARCHAR) + ' ' + CAST(YEAR(bd.FirstDepositDate) AS VARCHAR) AS FTD_QY ,
CONVERT(VARCHAR(6),bd.FirstDepositDate,112) AS YearMonth, 
CAST(DATEADD(month, DATEDIFF(month, -1, bd.FirstDepositDate), -1) AS DATE) AS month,
CASE
  WHEN bd.FirstDepositAmount >= 1     AND bd.FirstDepositAmount < 100   THEN '$1-$99'
  WHEN bd.FirstDepositAmount >= 100   AND bd.FirstDepositAmount < 200   THEN '$100-$199'
  WHEN bd.FirstDepositAmount >= 200   AND bd.FirstDepositAmount < 500   THEN '$200-$499'
  WHEN bd.FirstDepositAmount >= 500   AND bd.FirstDepositAmount < 1000  THEN '$500-$999'
  WHEN bd.FirstDepositAmount >= 1000  AND bd.FirstDepositAmount < 5000  THEN '$1,000-$4,999'
  WHEN bd.FirstDepositAmount >= 5000                                     THEN '$5,000+'
  WHEN bd.FirstDepositAmount IS NULL                                      THEN 'Unknown'
  ELSE '< $1'
END AS deposit_amount_band,
COUNT(*) AS FA
FROM BI_DB_dbo.BI_DB_First5Actions bd
LEFT JOIN #fakeftd AS f ON f.CID = bd.CID
WHERE bd.FirstDepositDate >= '2020-01-01'  
and f.CID IS NULL
GROUP BY bd.FirstAction_Detailed,
         NewMarketingRegion, 
		 Country,
         'Q' + CAST(DATEPART(QUARTER, bd.FirstDepositDate) AS VARCHAR) + ' ' + CAST(YEAR(bd.FirstDepositDate) AS VARCHAR),
		 CAST(DATEADD(month, DATEDIFF(month, -1, bd.FirstDepositDate), -1) AS DATE),
         CONVERT(VARCHAR(6),bd.FirstDepositDate,112),
CASE
  WHEN bd.FirstDepositAmount >= 1     AND bd.FirstDepositAmount < 100   THEN '$1-$99'
  WHEN bd.FirstDepositAmount >= 100   AND bd.FirstDepositAmount < 200   THEN '$100-$199'
  WHEN bd.FirstDepositAmount >= 200   AND bd.FirstDepositAmount < 500   THEN '$200-$499'
  WHEN bd.FirstDepositAmount >= 500   AND bd.FirstDepositAmount < 1000  THEN '$500-$999'
  WHEN bd.FirstDepositAmount >= 1000  AND bd.FirstDepositAmount < 5000  THEN '$1,000-$4,999'
  WHEN bd.FirstDepositAmount >= 5000                                     THEN '$5,000+'
  WHEN bd.FirstDepositAmount IS NULL                                      THEN 'Unknown'
  ELSE '< $1'
END