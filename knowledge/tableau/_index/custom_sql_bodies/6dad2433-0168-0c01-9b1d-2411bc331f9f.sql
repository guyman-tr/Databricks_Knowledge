SELECT
	CONVERT (VARCHAR(6), bddfrga.Date, 112) AS YearMonth
  , bddfrga.MIMOAction
  , bddfrga.IsPlatformFTD
  , bddfrga.IsInternalTransfer
  , bddfrga.IsRedeem
  , bddfrga.IsTradeFromIBAN
  , bddfrga.MIMOPlatform
  , bddfrga.IsGlobalFTD
  , bddfrga.IsCryptoToFiat
  , bddfrga.IsRecurring
  , bddfrga.IsIBANQuickTransfer
  , bddfrga.Currency
  , dft.Name AS MOP
  , sum(bddfrga.AmountUSD) AS AmountUSD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms bddfrga
	LEFT JOIN DWH_dbo.Dim_FundingType dft
		ON bddfrga.FundingTypeID = dft.FundingTypeID
WHERE bddfrga.DateID BETWEEN 20250101 AND CAST(FORMAT(CAST(getdate() AS DATE),'yyyyMMdd') as INT) 
GROUP BY 
	CONVERT (VARCHAR(6), bddfrga.Date, 112) 
  , bddfrga.MIMOAction
  , bddfrga.IsPlatformFTD
  , bddfrga.IsInternalTransfer
  , bddfrga.IsRedeem
  , bddfrga.IsTradeFromIBAN
  , bddfrga.MIMOPlatform
  , bddfrga.IsGlobalFTD
  , bddfrga.IsCryptoToFiat
  , bddfrga.IsRecurring
  , bddfrga.IsIBANQuickTransfer
  , bddfrga.Currency
  , dft.Name