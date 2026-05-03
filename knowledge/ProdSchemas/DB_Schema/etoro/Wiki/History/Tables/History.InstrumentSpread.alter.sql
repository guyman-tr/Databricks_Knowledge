-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.InstrumentSpread
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentSpread.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_history_instrumentspread
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_history_instrumentspread (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread SET TBLPROPERTIES (
    'comment' = 'Temporal history table capturing all changes to per-instrument spread configuration, preserving the complete audit trail of bid/ask spread offsets and market spread thresholds applied to each instrument on each price feed. Source: etoro.History.InstrumentSpread on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentSpread.md).'
);

ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'InstrumentSpread',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN InstrumentID COMMENT 'The trading instrument this spread configuration applies to. Part of composite PK (InstrumentID, FeedID) in the live table. FK to Trade.Instrument(InstrumentID). (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN SpreadTypeID COMMENT 'Spread unit type: 1=SpreadInPips (spread values are pip offsets), 2=PrecentageSpread (spread values are percentages from reference price). FK to Dictionary.SpreadType. Live data shows SpreadTypeID=1 exclusively. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN Bid COMMENT 'Bid price offset applied to the raw market bid. Negative values widen the sell spread (customer gets a worse sell price than market). Example: -2 pips means the customer sell price is 2 pips below market bid. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN Ask COMMENT 'Ask price offset applied to the raw market ask. Positive values widen the buy spread (customer pays more than market ask). Example: +1 pip means the customer buy price is 1 pip above market ask. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN MarketSpreadThreshold COMMENT 'Maximum acceptable raw market spread (ask minus bid from provider). If the provider''s spread exceeds this threshold, the price may be flagged or rejected as abnormal. Unit determined by SpreadThresholdTypeID. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN ReferenceBid COMMENT 'Reference bid price used as baseline for SpreadTypeID=2 (percentage-based) spread calculation. Defaults to 0. Not used when SpreadTypeID=1 (pips). (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN ReferenceAsk COMMENT 'Reference ask price used as baseline for SpreadTypeID=2 (percentage-based) spread calculation. Defaults to 0. Not used when SpreadTypeID=1 (pips). (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN SpreadThresholdTypeID COMMENT 'Unit type for MarketSpreadThreshold: 1=NOP (Number Of Pips), 2=NOE (Number Of Events). FK to Dictionary.SpreadThresholdType. Defaults to 1. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN FeedID COMMENT 'Price feed this spread configuration applies to. Part of composite PK. DEFAULT 1 = primary feed. Same instrument can have different spread configs per feed. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN DbLoginName COMMENT 'SQL Server login that made the change. Computed from suser_name() in live table; stored here statically. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN AppLoginName COMMENT 'Application-level user context at time of change. Computed from context_info() in live table; stored here statically. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this spread configuration became active in Trade.InstrumentSpread. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this spread configuration was superseded. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
ALTER TABLE main.dealing.bronze_etoro_history_instrumentspread ALTER COLUMN HostName COMMENT 'Host machine name at time of change. Computed from host_name() in live table; stored here statically. (Tier 1 - upstream wiki, etoro.History.InstrumentSpread)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
