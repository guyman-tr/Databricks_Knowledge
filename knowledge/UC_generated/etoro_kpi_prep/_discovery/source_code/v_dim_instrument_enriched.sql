-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_dim_instrument_enriched
-- Captured: 2026-05-19T12:12:40Z
-- ==========================================================================

WITH rth_instruments AS (
  SELECT 
    imd.InstrumentID, 
    imd.Symbol, 
    imd.ISINCode
  FROM main.trading.bronze_etoro_trade_instrumentmetadata_daily imd
  JOIN main.trading.bronze_etoro_trade_providertoinstrument pti 
    ON imd.InstrumentID = pti.InstrumentID
  WHERE ExchangeID = 33 -- RTH
    AND Tradable = TRUE
    AND VisibleInternallyOnly = FALSE
), 
instruments_245 AS (
  SELECT DISTINCT imd.InstrumentID
  FROM main.trading.bronze_etoro_trade_instrumentmetadata_daily imd
  JOIN main.trading.bronze_etoro_trade_providertoinstrument pti 
    ON imd.InstrumentID = pti.InstrumentID
  JOIN rth_instruments rth 
    ON rth.ISINCode = imd.ISINCode
  WHERE imd.Tradable = TRUE
    AND pti.VisibleInternallyOnly = FALSE
    AND imd.ExchangeID IN (4, 5)
)
SELECT
  cc.InstrumentID,
  cc.InstrumentTypeID,
  cc.InstrumentType,
  cc.Name,
  cc.DWHInstrumentID,
  cc.StatusID,
  cc.BuyCurrencyID,
  cc.SellCurrencyID,
  cc.BuyCurrency,
  cc.SellCurrency,
  cc.TradeRange,
  cc.DollarRatio,
  cc.PipDifferenceThreshold,
  cc.IsMajorID,
  cc.IsMajor,
  cc.UpdateDate,
  cc.InsertDate,
  cc.InstrumentDisplayName,
  cc.Industry,
  cc.CompanyInfo,
  cc.Exchange,
  cc.ISINCode,
  cc.ISINCountryCode,
  cc.Tradable,
  cc.Symbol,
  cc.ReceivedOnPriceServer,
  cc.BonusCreditUsePercent,
  cc.SymbolFull,
  cc.CUSIP,
  cc.Precision,
  cc.AllowBuy,
  cc.AllowSell,
  cc.AssetClass,
  cc.IndustryGroup,
  cc.ADV_Last3Months,
  cc.MKTcap,
  cc.SharesOutStanding,
  cc.VisibleInternallyOnly,
  cc.PlatformSector,
  cc.PlatformIndustry,
  cc.IsFuture,
  cc.Multiplier,
  cc.ProviderID,
  cc.ProviderMarginPerLot,
  cc.eToroMarginPerLot,
  cc.SettlementTime,
  cc.OperationMode,
  CASE
    WHEN cc.VisibleInternallyOnly = 0
      AND cc.Tradable = 1
      AND dd.InstrumentVisible = 1
    THEN 1
    ELSE 0
  END AS Tradeable,
  CASE 
    WHEN etig.InstrumentID IS NOT NULL THEN 1 
    ELSE 0 
  END AS IsSQF,
  CASE 
    WHEN i245.InstrumentID IS NOT NULL THEN 1 
    ELSE 0 
  END AS Is_245_Instrument
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument cc
JOIN main.trading.bronze_etoro_trade_instrumentmetadata_daily dd
  ON cc.InstrumentID = dd.InstrumentID
LEFT JOIN main.trading.bronze_etoro_trade_instrumentgroups etig
  ON cc.InstrumentID = etig.InstrumentID
  AND etig.GroupID = 59
LEFT JOIN instruments_245 i245
  ON cc.InstrumentID = i245.InstrumentID
