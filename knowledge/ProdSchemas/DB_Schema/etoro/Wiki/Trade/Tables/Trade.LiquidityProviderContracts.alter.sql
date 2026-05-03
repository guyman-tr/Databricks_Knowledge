-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.LiquidityProviderContracts
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderContracts.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_trade_liquidityprovidercontracts
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_trade_liquidityprovidercontracts (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts SET TBLPROPERTIES (
    'comment' = 'Mapping table that links instruments to liquidity provider types with exchange-specific ticker symbols and validity windows for price feeds and hedging. Source: etoro.Trade.LiquidityProviderContracts on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderContracts.md).'
);

ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'LiquidityProviderContracts',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN ContractID COMMENT 'Surrogate key. Unique per row. Used by Trade.TradonomiToLiquidityProviderContracts as LiquidityProviderContractID. Internal.Newcurrency and Stocks.AddNewStock use IDENTITY_INSERT when copying from source instrument. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN LiquidityProviderID COMMENT 'References Trade.LiquidityProviderType.LiquidityProviderTypeID (FK_LiquidityProviderContracts_LiquidityProviderType). Despite the name, stores provider TYPE not provider instance. Internal.Newcurrency comment: "[LiquidityProviderID] is actually from Trade.LiquidityProviderType." Hedge.GetHedgeSupportedInstruments joins HA.LiquidityProviderTypeID = LPC.LiquidityProviderID. Values: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 5=XIGNITE, 8=BitStamp (Trade.LiquidityProviderType). (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN InstrumentID COMMENT 'The eToro instrument (Trade.Instrument). FK to Trade.Instrument. Each row maps one instrument to one provider type. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN FromDate COMMENT 'Start of validity window. Contract is active when query date is >= FromDate. Used in Trade.GetAvailableLiquidityProviderContracts and Price.SwapContracts for overlap checks. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN ToDate COMMENT 'End of validity window. Contract is active when query date is <= ToDate. Price.SwapContracts reads ToDate for rollover logic. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN Ticker COMMENT 'Provider-specific ticker symbol (e.g., EUR/USD, EURUSD). Price.GetTickerInfo and Hedge.GetLiquidityProviderContracts return it for price/hedge resolution. Internal.Newcurrency can UPDATE Ticker from XML input. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN ExchangeID COMMENT 'FK to Price.Exchange. Default 1. Identifies which exchange context this ticker applies to. Used when same instrument trades on multiple exchanges (e.g., stocks). (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN RateConversionFactor COMMENT 'Multiplier to convert provider quote units to eToro units. Default 1. Used when provider uses different scale (e.g., pip vs point). (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN DbLoginName COMMENT 'Computed: current SQL login. Audit/debug only; not in PK or business logic. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN AppLoginName COMMENT 'Computed: application context. Audit/debug only. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN SysStartTime COMMENT 'System-versioning valid-from. GENERATED ALWAYS AS ROW START. History.LiquidityProviderContracts stores prior versions. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
ALTER TABLE main.general.bronze_etoro_trade_liquidityprovidercontracts ALTER COLUMN SysEndTime COMMENT 'System-versioning valid-to. GENERATED ALWAYS AS ROW END. Current rows have max value. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderContracts)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
