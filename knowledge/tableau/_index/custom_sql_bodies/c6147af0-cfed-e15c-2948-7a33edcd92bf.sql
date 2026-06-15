SELECT
	CONVERT (VARCHAR(6), bddfrga.Date, 112) AS YearMonth
  , bddfrga.IsBuy
  , bddfrga.IsFuture
  , bddfrga.IsCopyFund
  , CASE WHEN ISNULL(bddfrga.IsClosedToIBAN,0) = 1 OR ISNULL(bddfrga.IsOpenedFromIBAN,0) = 1 THEN 1 ELSE 0 END AS IsIBANTrade
  , bddfrga.IsRecurring
  , bddfrga.IsAirDrop
  , ISNULL(bddfrga.IsSQF,0) AS IsSQF
  , di.InstrumentType
  , bddfrga.IsLeverage
  , sum(bddfrga.VolumeOpen) VolumeOpen
  , sum(bddfrga.VolumeClose) VolumeClose
  , sum(bddfrga.VolumeOpen) + sum(bddfrga.VolumeClose) AS TotalVolume
  , sum(bddfrga.InvestedAmountOpen) InvestedAmountOpen
  , sum(bddfrga.InvestedAmountClosed) InvestedAmountClosed
  , sum(bddfrga.NetInvestedAmount)  NetInvestedAmount
FROM BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts bddfrga
	LEFT JOIN (SELECT DISTINCT InstrumentTypeID, InstrumentType from DWH_dbo.Dim_Instrument) di
		ON bddfrga.InstrumentTypeID = di.InstrumentTypeID
WHERE bddfrga.DateID BETWEEN 20250101 AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) 
GROUP BY 
	CONVERT (VARCHAR(6), bddfrga.Date, 112) 
  , bddfrga.IsBuy
  , bddfrga.IsFuture
  , bddfrga.IsCopyFund
  , CASE WHEN ISNULL(bddfrga.IsClosedToIBAN,0) = 1 OR ISNULL(bddfrga.IsOpenedFromIBAN,0) = 1 THEN 1 ELSE 0 END 
  , bddfrga.IsRecurring
  , bddfrga.IsAirDrop
  , ISNULL(bddfrga.IsSQF,0)
  , di.InstrumentType
  , bddfrga.IsLeverage