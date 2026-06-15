SELECT <[Parameters].[Parameter 1]> AS 'Settlement Date' 
, COALESCE(iu.InstrumentID, du.InstrumentID) AS InstrumentID
, COALESCE(iu.InstrumentDisplayName, du.InstrumentDisplayName) AS InstrumentDisplayName
, COALESCE(iu.ISINCode, du.ISINCode) AS ISINCode
, iu.Exchange
, ISNULL(iu.EOD_Units_Rounded, 0) AS 'Enhanced ISEM Report Units'
, ISNULL(du.eToro_Units, 0) AS 'Existing Internal Dealing Report Units'
, (CASE WHEN ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0) < 0 THEN ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0) ELSE '' END) AS 'Unit Shortfall'
, (CASE WHEN ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0) < 0 THEN ABS(ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0)) * du.AVG_Bid * AVG_FX_Rate ELSE '' END) 
AS 'Estimated Value of Shortfall'
, (CASE WHEN ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0) > 0 THEN ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0) ELSE '' END) AS 'Unit Surplus'
, (CASE WHEN ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0) > 0 THEN ABS(ISNULL(du.eToro_Units, 0) - ISNULL(iu.EOD_Units_Rounded, 0)) * du.AVG_Bid * AVG_FX_Rate ELSE '' END) 
AS 'Estimated Value of Surplus'
FROM 
(SELECT fs.InstrumentID
, fs.InstrumentDisplayName
, fs.ISINCode
, fs.Exchange
, SUM(fs.EOD_Units) AS EOD_Units
, CEILING(SUM(fs.EOD_Units)) AS EOD_Units_Rounded
from BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 fs

JOIN 

(SELECT InstrumentID
,SettlementDate
,MAX(Date) AS MaxTradeDate
from BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025
WHERE HedgeServerID = 126 
AND SettlementDate = <[Parameters].[Parameter 1]>
AND IsSettled =1 
AND IsCreditReportValidCB = 1 
AND IsTradableAtQueryDate = 1
AND HedgeServerID = 126
 --AND EOD_Units > 0
GROUP BY InstrumentID
,SettlementDate) mx

ON fs.InstrumentID = mx.InstrumentID


where fs.SettlementDate = <[Parameters].[Parameter 1]>
AND fs.Date = mx.MaxTradeDate
AND fs.IsSettled =1 
AND fs.IsCreditReportValidCB = 1 
AND fs.IsTradableAtQueryDate = 1
AND fs.HedgeServerID = 126
GROUP BY fs.InstrumentID
, fs.InstrumentDisplayName
, fs.ISINCode
, fs.Exchange)
iu

FULL OUTER JOIN 

(SELECT die.Date
			 ,die.InstrumentID
			 ,die.InstrumentDisplayName
			 ,die.ISINCode
			 ,die.HedgeServerID
			 ,die.ClientAccountID
			 , AVG(fcpws.Bid) AS AVG_Bid
			 , AVG(COALESCE(FX_Rate, IB_Rate)) AS AVG_FX_Rate
			 ,SUM(die.eToro_Units) AS eToro_Units
FROM [Dealing_dbo].[Dealing_IBRecon_EODHoldings] die
LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit fcpws
ON die.InstrumentID = fcpws.InstrumentID AND die.Date = fcpws.OccurredDate 
WHERE die.HedgeServerID = 126 
AND die.Date = <[Parameters].[Parameter 1]>
GROUP BY die.Date
			 ,die.InstrumentID
			 ,die.InstrumentDisplayName
			 ,die.ISINCode
			 ,die.HedgeServerID
			 ,die.ClientAccountID)
du

ON iu.InstrumentID = du.InstrumentID