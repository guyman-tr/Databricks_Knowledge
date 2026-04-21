-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Instrument_Snapshot_Enriched
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_dim_instrument_enriched
-- Col comments: 48 added, 0 preserved (existing), 2 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_dim_instrument_enriched (
  InstrumentID COMMENT 'Direct pass-through from etig.InstrumentID. (T1 — Function_Instrument_Snapshot_Enriched)',
  InstrumentTypeID COMMENT 'Direct pass-through from isn.InstrumentTypeID. (T1 — Function_Instrument_Snapshot_Enriched)',
  InstrumentType COMMENT 'Direct pass-through from isn.InstrumentType. (T1 — Function_Instrument_Snapshot_Enriched)',
  Name COMMENT 'Direct pass-through from isn.Name. (T1 — Function_Instrument_Snapshot_Enriched)',
  DWHInstrumentID COMMENT 'Direct pass-through from isn.DWHInstrumentID. (T1 — Function_Instrument_Snapshot_Enriched)',
  StatusID COMMENT 'Direct pass-through from isn.StatusID. (T1 — Function_Instrument_Snapshot_Enriched)',
  BuyCurrencyID COMMENT 'Direct pass-through from isn.BuyCurrencyID. (T1 — Function_Instrument_Snapshot_Enriched)',
  SellCurrencyID COMMENT 'Direct pass-through from isn.SellCurrencyID. (T1 — Function_Instrument_Snapshot_Enriched)',
  BuyCurrency COMMENT 'Direct pass-through from isn.BuyCurrency. (T1 — Function_Instrument_Snapshot_Enriched)',
  SellCurrency COMMENT 'Direct pass-through from isn.SellCurrency. (T1 — Function_Instrument_Snapshot_Enriched)',
  TradeRange COMMENT 'Direct pass-through from isn.TradeRange. (T1 — Function_Instrument_Snapshot_Enriched)',
  DollarRatio COMMENT 'Direct pass-through from isn.DollarRatio. (T1 — Function_Instrument_Snapshot_Enriched)',
  PipDifferenceThreshold COMMENT 'Direct pass-through from isn.PipDifferenceThreshold. (T1 — Function_Instrument_Snapshot_Enriched)',
  IsMajorID COMMENT 'Direct pass-through from isn.IsMajorID. (T1 — Function_Instrument_Snapshot_Enriched)',
  IsMajor COMMENT 'Direct pass-through from isn.IsMajor. (T1 — Function_Instrument_Snapshot_Enriched)',
  UpdateDate COMMENT 'Direct pass-through from isn.UpdateDate. (T1 — Function_Instrument_Snapshot_Enriched)',
  InsertDate COMMENT 'Direct pass-through from isn.InsertDate. (T1 — Function_Instrument_Snapshot_Enriched)',
  InstrumentDisplayName COMMENT 'Direct pass-through from isn.InstrumentDisplayName. (T1 — Function_Instrument_Snapshot_Enriched)',
  Industry COMMENT 'Direct pass-through from isn.Industry. (T1 — Function_Instrument_Snapshot_Enriched)',
  CompanyInfo COMMENT 'Direct pass-through from isn.CompanyInfo. (T1 — Function_Instrument_Snapshot_Enriched)',
  Exchange COMMENT 'Direct pass-through from isn.Exchange. (T1 — Function_Instrument_Snapshot_Enriched)',
  ISINCode COMMENT 'Direct pass-through from isn.ISINCode. (T1 — Function_Instrument_Snapshot_Enriched)',
  ISINCountryCode COMMENT 'Direct pass-through from isn.ISINCountryCode. (T1 — Function_Instrument_Snapshot_Enriched)',
  Tradable COMMENT 'Direct pass-through from isn.Tradable. (T1 — Function_Instrument_Snapshot_Enriched)',
  Symbol COMMENT 'Direct pass-through from isn.Symbol. (T1 — Function_Instrument_Snapshot_Enriched)',
  ReceivedOnPriceServer COMMENT 'Direct pass-through from isn.ReceivedOnPriceServer. (T1 — Function_Instrument_Snapshot_Enriched)',
  BonusCreditUsePercent COMMENT 'Direct pass-through from isn.BonusCreditUsePercent. (T1 — Function_Instrument_Snapshot_Enriched)',
  SymbolFull COMMENT 'Direct pass-through from isn.SymbolFull. (T1 — Function_Instrument_Snapshot_Enriched)',
  CUSIP COMMENT 'Direct pass-through from isn.CUSIP. (T1 — Function_Instrument_Snapshot_Enriched)',
  Precision COMMENT 'Direct pass-through from isn.Precision. (T1 — Function_Instrument_Snapshot_Enriched)',
  AllowBuy COMMENT 'Direct pass-through from isn.AllowBuy. (T1 — Function_Instrument_Snapshot_Enriched)',
  AllowSell COMMENT 'Direct pass-through from isn.AllowSell. (T1 — Function_Instrument_Snapshot_Enriched)',
  AssetClass COMMENT 'Direct pass-through from isn.AssetClass. (T1 — Function_Instrument_Snapshot_Enriched)',
  IndustryGroup COMMENT 'Direct pass-through from isn.IndustryGroup. (T1 — Function_Instrument_Snapshot_Enriched)',
  ADV_Last3Months COMMENT 'Direct pass-through from isn.ADV_Last3Months. (T1 — Function_Instrument_Snapshot_Enriched)',
  MKTcap COMMENT 'Direct pass-through from isn.MKTcap. (T1 — Function_Instrument_Snapshot_Enriched)',
  SharesOutStanding COMMENT 'Direct pass-through from isn.SharesOutStanding. (T1 — Function_Instrument_Snapshot_Enriched)',
  VisibleInternallyOnly COMMENT 'Direct pass-through from isn.VisibleInternallyOnly. (T1 — Function_Instrument_Snapshot_Enriched)',
  PlatformSector COMMENT 'Direct pass-through from isn.PlatformSector. (T1 — Function_Instrument_Snapshot_Enriched)',
  PlatformIndustry COMMENT 'Direct pass-through from isn.PlatformIndustry. (T1 — Function_Instrument_Snapshot_Enriched)',
  IsFuture COMMENT 'Direct pass-through from isn.IsFuture. (T1 — Function_Instrument_Snapshot_Enriched)',
  Multiplier COMMENT 'Direct pass-through from isn.Multiplier. (T1 — Function_Instrument_Snapshot_Enriched)',
  ProviderID COMMENT 'Direct pass-through from isn.ProviderID. (T1 — Function_Instrument_Snapshot_Enriched)',
  ProviderMarginPerLot COMMENT 'Direct pass-through from isn.ProviderMarginPerLot. (T1 — Function_Instrument_Snapshot_Enriched)',
  eToroMarginPerLot COMMENT 'Direct pass-through from isn.eToroMarginPerLot. (T1 — Function_Instrument_Snapshot_Enriched)',
  SettlementTime COMMENT 'Direct pass-through from isn.SettlementTime. (T1 — Function_Instrument_Snapshot_Enriched)',
  OperationMode,
  Tradeable,
  IsSQF COMMENT 'CASE WHEN adj.InstrumentID IS NOT NULL THEN 1 ELSE 0 END WHERE GroupID = 59, joined on dis.DateID >= adj.DateID (adj carries @dateInt as DateID). Source: DWH_staging.etoro_Trade_InstrumentGroups. (T2 — Function_Instrument_Snapshot_Enriched)',
  Is_245_Instrument COMMENT 'CASE WHEN COALESCE(eht.InstrumentID, rthi.InstrumentID) IS NOT NULL THEN 1 ELSE 0 END — eht = rth_instruments_regular (Nasdaq/NYSE + ISIN/CUSIP match to RTH base); rthi = base RTH tradable set (Exchange = ''Regular Trading Hours - RTH'', Tradable = 1, CompanyInfo NOT LIKE ''%Dormant%''). Source: Dim_Instrument (RTH CTEs). (T2 — Function_Instrument_Snapshot_Enriched)'
)
COMMENT 'BI_DB_dbo.Function_Instrument_Snapshot_Enriched > dim instrument and dim instrument snapshot are not sufficient for rapid changes which are sometimes coming from Google Sheets etc.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Instrument_Snapshot_Enriched > dim instrument and dim instrument snapshot are not sufficient for rapid changes which are sometimes coming from Google Sheets etc.')
WITH SCHEMA COMPENSATION
AS WITH rth_instruments AS (
  SELECT 
    imd.InstrumentID, 
    imd.Symbol, 
    imd.ISINCode
  FROM main.trading.bronze_etoro_trade_instrumentmetadata imd
  JOIN main.trading.bronze_etoro_trade_providertoinstrument pti 
    ON imd.InstrumentID = pti.InstrumentID
  WHERE ExchangeID = 33 -- RTH
    AND Tradable = 1
    AND VisibleInternallyOnly = 0
), 
instruments_245 AS (
  SELECT DISTINCT imd.InstrumentID
  FROM main.trading.bronze_etoro_trade_instrumentmetadata imd
  JOIN main.trading.bronze_etoro_trade_providertoinstrument pti 
    ON imd.InstrumentID = pti.InstrumentID
  JOIN rth_instruments rth 
    ON rth.ISINCode = imd.ISINCode
  WHERE imd.Tradable = 1
    AND pti.VisibleInternallyOnly = 0
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
JOIN main.trading.bronze_etoro_trade_instrumentmetadata dd
  ON cc.InstrumentID = dd.InstrumentID
LEFT JOIN main.trading.bronze_etoro_trade_instrumentgroups etig
  ON cc.InstrumentID = etig.InstrumentID
  AND etig.GroupID = 59
LEFT JOIN instruments_245 i245
  ON cc.InstrumentID = i245.InstrumentID

;
