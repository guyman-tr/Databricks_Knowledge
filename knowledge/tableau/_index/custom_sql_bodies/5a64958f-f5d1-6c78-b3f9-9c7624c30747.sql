SELECT Distinct
isnull(x.DateID,z.DateID) as DateID,
			isnull(x.Date,z.Date) AS Date,
			isnull(x.InstrumentID,z.InstrumentID) AS InstrumentID,
			isnull(x.InstrumentName,z.InstrumentName) AS InstrumentName,
			isnull(x.InstrumentDisplayName,x.InstrumentDisplayName) AS InstrumentDisplayName,
			isnull(x.ISINCode,z.ISINCode) ISINCode,
			isnull(x.CUSIP,z.CUSIP) CUSIP,
			isnull(x.HedgeServerID,z.HedgeServerID) HedgeServerID,
			isnull(x.Exchange,z.Exchange) AS Exchange,
			isnull(x.LiquidityAccountID,z.LiquidityAccountID) AS LiquidityAccountID,
			isnull(x.LiquidityAccountName,z.LiquidityAccountName) AS LiquidityAccountName,
			isnull(x.LiquidityProviderName,z.LiquidityProviderName) AS LiquidityProviderName,
			isnull(x.Provider,z.Provider) AS Provider,
			isnull(x.SellCurrency,z.SellCurrency) AS SellCurrency,
			isnull(x.IsRelevantForRecon,z.IsRelevantForRecon) AS IsRelevantForRecon,
			isnull(x.USD_ConversionRate,z.USD_ConversionRate) AS USD_ConversionRate,
			isnull(x.EOD_PriceUSD_Spreaded,z.EOD_PriceUSD_Spreaded) AS EOD_PriceUSD_Spreaded,
			isnull(x.EOD_PriceUSD_Unspreaded,z.EOD_PriceUSD_Unspreaded) AS EOD_PriceUSD_Unspreaded,
			isnull(x.EOD_OrigCurr_BidSpreaded,z.EOD_OrigCurr_BidSpreaded) AS EOD_OrigCurr_BidSpreaded,
			isnull(x.EOD_OrigCurr_BidUnspreaded,z.EOD_OrigCurr_BidUnspreaded) AS EOD_OrigCurr_BidUnspreaded
			, z.eToro_Units_Plus1h
			,z.eToro_Units
			,z.eToroUSDByPriceUnspreaded
			,z.eToroUSDPlus1hByPriceUnspreaded
			,TP_UnitsIsValidCustomerReal
			,TP_UnitsIsValidCustomerCFD
			,TP_UnitsIsCreditReportValidReal
			,TP_UnitsIsCreditReportValidCFD
			,TP_EquityUSDIsValidCustomerReal
			,TP_EquityUSDIsValidCustomerCFD
			,isnull(TP_EquityUSDIsCreditReportValidReal,0) + isnull(x.TotalStockMarginLoanIsCreditReportValid,0) AS TP_EquityUSDIsCreditReportValidReal
			,TP_EquityUSDIsCreditReportValidCFD
			,TP_UnitsTotal
			,TP_EquityUSDTotal
			,TotalStockMarginLoanIsCreditReportValid
FROM (

SELECT o.DateID
      ,o.Date
      ,o.InstrumentID
      ,o.InstrumentName
	  ,o.InstrumentDisplayName
      ,o.ISINCode
      ,o.CUSIP
      ,SUM(EOD_Units)TP_UnitsTotal
      ,SUM(CASE WHEN IsValidCustomer =1 AND IsSettled =1 THEN EOD_Units ELSE 0 END ) TP_UnitsIsValidCustomerReal
	  ,SUM(CASE WHEN IsValidCustomer =1 AND IsSettled =0 THEN EOD_Units ELSE 0 END ) TP_UnitsIsValidCustomerCFD
      ,SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Units ELSE 0 END ) TP_UnitsIsCreditReportValidReal
	  ,SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =0 THEN  EOD_Units ELSE 0 END ) TP_UnitsIsCreditReportValidCFD
	  ,SUM(EOD_Equity_USD)TP_EquityUSDTotal
      ,SUM(CASE WHEN IsValidCustomer =1 AND IsSettled =1 THEN EOD_Equity_USD ELSE 0 END ) TP_EquityUSDIsValidCustomerReal
	  ,SUM(CASE WHEN IsValidCustomer =1 AND IsSettled =0 THEN EOD_Equity_USD ELSE 0 END ) TP_EquityUSDIsValidCustomerCFD
      ,SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Equity_USD ELSE 0 END ) TP_EquityUSDIsCreditReportValidReal
	  ,SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =0 THEN  EOD_Equity_USD ELSE 0 END ) TP_EquityUSDIsCreditReportValidCFD
      ,o.HedgeServerID 
      --,o.Provider 
      ,o.Exchange
	  ,o.LiquidityAccountID
	  ,o.LiquidityAccountName
	  ,o.LiquidityProviderName
	  ,o.Provider
	  ,sum(CASE when o.IsCreditReportValidCB = 1 THEN  o.TotalStockMarginLoan ELSE 0 END ) AS TotalStockMarginLoanIsCreditReportValid
	   ,di.SellCurrency,
	   CASE WHEN o.Provider NOT IN ('Saxo','Apex', 'BNYMellon','IB') AND SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Units ELSE 0 END ) =0 THEN 0
	        WHEN o.Provider = 'Apex' AND o.HedgeServerID =11 AND SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Units ELSE 0 END ) =0 THEN 0
			WHEN o.Provider = 'Saxo' AND o.HedgeServerID =122 AND SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Units ELSE 0 END ) =0 THEN 0
			WHEN o.Provider = 'BNYMellon' AND o.HedgeServerID IN (129,224) AND SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Units ELSE 0 END ) =0 THEN 0
			WHEN o.Provider = 'IB' AND o.HedgeServerID =121 AND SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Units ELSE 0 END ) =0 THEN 0
			WHEN ISNULL(o.Provider,'NA') = 'NA' AND SUM(CASE WHEN IsCreditReportValidCB =1 AND IsSettled =1 THEN  EOD_Units ELSE 0 END ) = 0 THEN 0 
			ELSE 1 
			END IsRelevantForRecon 
		, o.USD_ConversionRate,o.EOD_PriceUSD_Spreaded, o.EOD_PriceUSD_Unspreaded, o.EOD_OrigCurr_BidSpreaded, o.EOD_OrigCurr_BidUnspreaded

FROM BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 o
JOIN DWH_dbo.Dim_Instrument di   ON di.InstrumentID = o.InstrumentID 

WHERE ClientHoldings ='Client_Holdings'   AND 
o.DateID BETWEEN 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1 1]> AS DATE),'yyyyMMdd') as INT)
and 
CAST(FORMAT(CAST(<[Parameters].[Parameter 2 1]> AS DATE),'yyyyMMdd') as INT)
AND o.Regulation <> 'BVI'
GROUP BY 
       o.DateID
      ,o.Date
      ,o.InstrumentID
      ,o.InstrumentName
      ,o.ISINCode
      ,o.CUSIP
      ,o.HedgeServerID
      ,o.Exchange
	  ,o.InstrumentDisplayName  --26580
	  ,o.LiquidityAccountID
	  ,o.LiquidityAccountName
	  ,o.LiquidityProviderName
	  ,o.Provider
	   ,di.SellCurrency, o.USD_ConversionRate,o.EOD_PriceUSD_Spreaded, o.EOD_PriceUSD_Unspreaded, o.EOD_OrigCurr_BidSpreaded, o.EOD_OrigCurr_BidUnspreaded
	   ) x

FULL OUTER JOIN (
SELECT bdftvp.DateID,
		bdftvp.Date ,
		bdftvp.InstrumentID,
		bdftvp.InstrumentName,
		bdftvp.ISINCode,
		bdftvp.CUSIP,
		bdftvp.HedgeServerID,
		bdftvp.Exchange,
		bdftvp.InstrumentDisplayName,
		bdftvp.LiquidityAccountID, 
		bdftvp.LiquidityAccountName, 
		bdftvp.LiquidityProviderName,
		bdftvp.Provider,
		bdftvp.SellCurrency,
		sum(bdftvp.eToro_Units) eToro_Units,
		sum(bdftvp.eToroUSDAmount) eToroUSDAmount,
		sum(bdftvp.eToroUSDByPriceUnspreaded) eToroUSDByPriceUnspreaded, 
		sum(bdftvp.eToro_Units_Plus1h) eToro_Units_Plus1h, 
		sum(bdftvp.eToroUSDPlus1hByPriceUnspreaded) eToroUSDPlus1hByPriceUnspreaded,
		bdftvp.IsRelevantForRecon, bdftvp.USD_ConversionRate,bdftvp.EOD_PriceUSD_Spreaded, bdftvp.EOD_PriceUSD_Unspreaded, bdftvp.EOD_OrigCurr_BidSpreaded, bdftvp.EOD_OrigCurr_BidUnspreaded
from BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions bdftvp
where bdftvp.DateID BETWEEN 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1 1]> AS DATE),'yyyyMMdd') as INT)
and 
CAST(FORMAT(CAST(<[Parameters].[Parameter 2 1]> AS DATE),'yyyyMMdd') as INT)
group BY bdftvp.DateID,
		bdftvp.Date ,
		bdftvp.InstrumentID,
		bdftvp.InstrumentName,
		bdftvp.ISINCode,
		bdftvp.CUSIP,
		bdftvp.HedgeServerID,
		bdftvp.Exchange,
		bdftvp.InstrumentDisplayName,
		bdftvp.LiquidityAccountID, 
		bdftvp.LiquidityAccountName, 
		bdftvp.LiquidityProviderName,
		bdftvp.Provider,
		bdftvp.SellCurrency,
		bdftvp.IsRelevantForRecon, bdftvp.USD_ConversionRate,bdftvp.EOD_PriceUSD_Spreaded, bdftvp.EOD_PriceUSD_Unspreaded, bdftvp.EOD_OrigCurr_BidSpreaded, bdftvp.EOD_OrigCurr_BidUnspreaded) z on 
		
		
		
		z.DateID = x.DateID AND 
		z.InstrumentID = x.InstrumentID AND
		--z.ISINCode = x.ISINCode AND 
		z.HedgeServerID = x.HedgeServerID --AND
		--z.Provider =x.Provider AND
		--z.SellCurrency = x.SellCurrency