SELECT
	CONVERT (VARCHAR(6), bddfrga.Date, 112) AS YearMonth
  , bddfrga.IsCopy
  , bddfrga.IsSettled
  , bddfrga.IsFuture
  , bddfrga.IsLeveraged
  , bddfrga.IsBuy
  , bddfrga.IsCopyFund
  , bddfrga.IsSQF
  , di.InstrumentType
  , sum(bddfrga.UnrealizedPnLChange) as UnrealizedPnLChange
  , sum(bddfrga.NetProfit		   ) as NetProfit
  , sum(bddfrga.UnrealizedPnLChange) + sum(bddfrga.NetProfit) AS TotalPnLPeriod
FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL bddfrga
	LEFT JOIN (SELECT DISTINCT InstrumentTypeID, InstrumentType from DWH_dbo.Dim_Instrument) di
		ON bddfrga.InstrumentTypeID = di.InstrumentTypeID
WHERE bddfrga.DateID BETWEEN 20250101 AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) 
GROUP BY 
	CONVERT (VARCHAR(6), bddfrga.Date, 112) 
  , bddfrga.IsCopy
  , bddfrga.IsSettled
  , bddfrga.IsFuture
  , bddfrga.IsLeveraged
  , bddfrga.IsBuy
  , bddfrga.IsCopyFund
  , bddfrga.IsSQF
  , di.InstrumentType