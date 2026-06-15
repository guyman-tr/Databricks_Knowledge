SELECT
	CONVERT (VARCHAR(6), bddfrga.Date, 112) AS YearMonth
  , bddfrga.IsBuy
  , bddfrga.IsLeveraged
  , bddfrga.IsFuture
  , bddfrga.IsCopyFund
  , CASE WHEN ISNULL(bddfrga.IsClosedToIBAN,0) = 1 OR ISNULL(bddfrga.IsOpenedFromIBAN,0) = 1 THEN 1 ELSE 0 END AS IsIBANTrade
  , bddfrga.IsRecurring
  , bddfrga.IsAirDrop
  , ISNULL(bddfrga.IsSQF,0) AS IsSQF
  , bddfrga.Metric
  , drm.RevenueMetricCategory
  , di.InstrumentType
, IsCopy
  , sum(bddfrga.Amount) AS Amount
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions bddfrga
	JOIN BI_DB_dbo.Dim_Revenue_Metrics drm
		ON bddfrga.Metric = drm.Metric
	LEFT JOIN (SELECT DISTINCT InstrumentTypeID, InstrumentType from DWH_dbo.Dim_Instrument) di
		ON bddfrga.InstrumentTypeID = di.InstrumentTypeID
WHERE bddfrga.DateID BETWEEN 20250101 AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) 
AND drm.IncludedInTotalRevenue = 1
GROUP BY 
	CONVERT (VARCHAR(6), bddfrga.Date, 112) 
  , bddfrga.IsBuy
  , bddfrga.IsLeveraged
  , bddfrga.IsFuture
  , bddfrga.IsCopyFund
  , CASE WHEN ISNULL(bddfrga.IsClosedToIBAN,0) = 1 OR ISNULL(bddfrga.IsOpenedFromIBAN,0) = 1 THEN 1 ELSE 0 END
  , bddfrga.IsRecurring
  , bddfrga.IsAirDrop
  , bddfrga.Metric
  , ISNULL(bddfrga.IsSQF,0) 
	, drm.RevenueMetricCategory
  , di.InstrumentType
, IsCopy