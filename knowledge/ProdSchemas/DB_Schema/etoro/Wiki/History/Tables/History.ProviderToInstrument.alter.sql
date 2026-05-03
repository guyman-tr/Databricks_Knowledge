-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ProviderToInstrument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderToInstrument.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_providertoinstrument
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_providertoinstrument (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument SET TBLPROPERTIES (
    'comment' = 'High-volume versioned log of complete provider-instrument trading parameter snapshots, capturing the full configuration state (spreads, fees, lot sizes, limits) each time a provider''s instrument parameters are updated. Source: etoro.History.ProviderToInstrument on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ProviderToInstrument.md).'
);

ALTER TABLE main.general.bronze_etoro_history_providertoinstrument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ProviderToInstrument',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN ProviderToInstrumentVersionID COMMENT 'Auto-incrementing version row ID. Clustered PK. NOT FOR REPLICATION prevents identity gaps on replication targets. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN ValidFrom COMMENT 'Application-set timestamp when this configuration version became active. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN ValidTo COMMENT 'Application-set timestamp when this version was superseded. Sentinel ''3000-01-01'' = currently active. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN ProviderID COMMENT 'Price/execution provider. Part of FK to Trade.ProviderToInstrument. HPVI_PROVIDER index covers (ProviderID, InstrumentID) lookups. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN InstrumentID COMMENT 'Financial instrument. Part of FK to Trade.ProviderToInstrument. HPVI_INSTRUMENT index covers per-instrument queries. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN Precision COMMENT 'Decimal precision of the price for this instrument (number of decimal places). Used to scale PaymentBid/Ask integer values to price units. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN PaymentBid COMMENT 'Bid-side spread adjustment in pip units (scaled by Precision). Typically negative (subtracts from mid-price). PaymentBid = -250 at Precision=3 means bid is 0.250 below mid. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN PaymentAsk COMMENT 'Ask-side spread adjustment in pip units. Typically positive (adds to mid-price). PaymentAsk = 250 at Precision=3 means ask is 0.250 above mid. Total spread = ABS(PaymentBid) + PaymentAsk in pip units. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN PresentationCode COMMENT 'The display code/ticker used to present this instrument to customers (e.g., "AAPL", "EUR/USD"). May differ from internal instrument identifiers. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN StopLossPercentage COMMENT 'Default stop loss percentage offered for this instrument. Represents the maximum allowed stop loss distance as a percentage of position value. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN EndOfWeekFee COMMENT 'Legacy end-of-week fee charged for holding positions over the weekend. Superseded by BuyEOWFee/SellEOWFee for directional differentiation but maintained for compatibility. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN Unit COMMENT 'Base trading unit size. Determines minimum position granularity for customer trades. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN UnitMargin COMMENT 'Margin required per unit of this instrument when traded through this provider. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN Benchmark COMMENT 'Reference benchmark value for this instrument. Nullable - not all instruments have a defined benchmark. Used for performance attribution or spread calculations. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN LiquidityLotSize COMMENT 'Standard lot size used when eToro hedges customer positions in the external liquidity market. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN LiquidityLotCost COMMENT 'Cost of one liquidity lot. Used for calculating hedging costs and P&L impact. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN DisplayOrder COMMENT 'Sort order for presenting this instrument in lists/menus to customers. Lower = appears earlier. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN WeekendPips COMMENT 'Additional pip charge applied to CFD positions held over the weekend. Nullable - not applied to all instruments. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN MinimumSpread COMMENT 'Minimum enforced spread (using the dtPrice user-defined type). Prevents the effective spread from going below this floor regardless of PaymentBid/Ask settings. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN MarketRange COMMENT 'Maximum allowable price movement (in pips) from the quoted price for order acceptance. Orders outside this range are rejected. Nullable - not all instruments have market range limits. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN EtoroHoldingFeeSpreadFactor COMMENT 'Multiplier applied to eToro''s holding/financing fees. DEFAULT 1 = standard rate. Values > 1 increase fees; < 1 reduce them. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN BuyEOWFee COMMENT 'End-of-week fee for long (buy) positions. Directional version of EndOfWeekFee. Nullable for instruments without separate buy/sell fee differentiation. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN SellEOWFee COMMENT 'End-of-week fee for short (sell) positions. Directional counterpart to BuyEOWFee. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN BuyOverNightFee COMMENT 'Overnight (swap/rollover) fee for long positions. Charged daily for leveraged CFD positions held overnight. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN SellOverNightFee COMMENT 'Overnight fee for short positions. Together with BuyOverNightFee forms the complete overnight cost structure. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN MaxStopLossPercentage COMMENT 'Maximum allowed stop loss percentage for this instrument. Upper bound on how far a stop loss can be placed from the entry price. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
ALTER TABLE main.general.bronze_etoro_history_providertoinstrument ALTER COLUMN Enabled COMMENT 'Whether this provider-instrument pair is currently active for trading. 1 = enabled (active), 0 or NULL = disabled. (Tier 1 - upstream wiki, etoro.History.ProviderToInstrument)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
