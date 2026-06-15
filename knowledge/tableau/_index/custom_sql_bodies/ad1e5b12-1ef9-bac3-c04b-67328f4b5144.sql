SELECT a.*,  b.USD_CR, di.SellCurrency, a.AmountInUnitsDecimal * c.Bid * b.USD_CR AS NOP_Computed, c.Bid AS RateBid  , c.Bid * b.USD_CR AS EOD_RateInUSD
FROM
(
select ia.* 
    , di.ISINCode
    , di.InstrumentDisplayName
	, CASE WHEN HedgeServerID in (20 , 25, 5000) THEN 'Unknown'
			WHEN HedgeServerID = 24 THEN 'FXCM'
			WHEN HedgeServerID = 101 THEN 'IG'
			WHEN HedgeServerID = 102 THEN 'Apex'
			WHEN HedgeServerID = 110 THEN 'BNYMellon'
			WHEN HedgeServerID = 111 THEN 'IG'
			WHEN HedgeServerID = 112 THEN 'Apex'
			WHEN HedgeServerID = 120 THEN 'IB'
			WHEN HedgeServerID = 121 THEN 'IB'
			WHEN HedgeServerID = 122 THEN 'Saxo'
			WHEN HedgeServerID = 123 THEN 'IG'
			WHEN HedgeServerID = 124 THEN 'BNYMellon'
			WHEN HedgeServerID = 125 THEN 'Saxo'
			WHEN HedgeServerID = 128 THEN 'Saxo'
			WHEN HedgeServerID = 126 THEN 'IB'
			WHEN HedgeServerID = 7 THEN 'IG'
			WHEN HedgeServerID = 9 THEN 'Apex'
			WHEN HedgeServerID = 3 THEN 'Apex'
			WHEN HedgeServerID = 225 THEN 'Saxo'
			WHEN HedgeServerID = 2 THEN 'JPM'
			WHEN HedgeServerID = 130 THEN 'BNYMellon'
			WHEN HedgeServerID = 129 THEN 'VisionTraffix'
			WHEN HedgeServerID = 11 THEN 'Apex'
		ELSE 'Unknown' END AS LiquidityProvider
from 
[BI_DB_dbo].[BI_DB_PositionPnL_EU_Custody_Instrument_Agg] ia
    join DWH_dbo.Dim_Instrument di
    on ia.InstrumentID = di.InstrumentID
where DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
) a
JOIN 
(
SELECT DISTINCT
	bdppl.InstrumentID
  , Max(bdppl.USD_CR)USD_CR
FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
	JOIN DWH_dbo.Dim_Instrument di
		ON bdppl.InstrumentID = di.InstrumentID AND di.InstrumentTypeID IN (5,6)
WHERE bdppl.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
AND bdppl.IsSettled = 1
GROUP BY bdppl.InstrumentID
) b
ON a.InstrumentID = b.InstrumentID
JOIN 
DWH_dbo.Dim_Instrument di
	ON a.InstrumentID = di.InstrumentID
JOIN 
(
	SELECT ps.InstrumentID, ps.Bid
	FROM DWH_dbo.Fact_CurrencyPriceWithSplit ps
	WHERE
	ps.OccurredDateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
) c
ON a.InstrumentID = c.InstrumentID