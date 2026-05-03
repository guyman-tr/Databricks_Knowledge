-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.InstrumentToFeeConfig
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentToFeeConfig.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_instrumenttofeeconfig
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_instrumenttofeeconfig (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig SET TBLPROPERTIES (
    'comment' = 'Temporal history table capturing all changes to the legacy per-instrument overnight and end-of-week fee configuration, recording the complete audit trail of fee rates charged on leveraged and non-leveraged positions. Source: etoro.History.InstrumentToFeeConfig on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentToFeeConfig.md).'
);

ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'InstrumentToFeeConfig',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN InstrumentID COMMENT 'The trading instrument this fee configuration applies to. PK in the live table (one row per instrument). FK to Trade.Instrument(InstrumentID). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN NonLeveragedSellEndOfWeekFee COMMENT 'End-of-week fee for non-leveraged (real stock) short sell positions. Charged when position is held over the weekend. Rate is a daily/weekly fee amount. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN NonLeveragedBuyEndOfWeekFee COMMENT 'End-of-week fee for non-leveraged (real stock) long buy positions. Typically 0 as customers own the asset outright. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN NonLeveragedBuyOverNightFee COMMENT 'Overnight fee for non-leveraged long buy positions. Typically 0 because the customer owns the real stock outright and incurs no borrowing cost. Live data confirms all sampled rows = 0. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN NonLeveragedSellOverNightFee COMMENT 'Overnight fee for non-leveraged short sell positions. Positive because short selling requires borrowing the stock - customer pays the stock lending fee per night held. Varies by instrument based on borrow cost. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN LeveragedSellEndOfWeekFee COMMENT 'End-of-week fee for leveraged short sell positions. Covers the weekend holding period (3 days) as a single charge. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN LeveragedBuyEndOfWeekFee COMMENT 'End-of-week fee for leveraged long buy positions. Approximately 3x the overnight rate, covering the weekend period. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN LeveragedBuyOverNightFee COMMENT 'Overnight fee for leveraged long buy positions. Small positive rate representing the daily interest cost on the borrowed capital used to lever the position (e.g., 0.035 to 0.126 per night). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN LeveragedSellOverNightFee COMMENT 'Overnight fee for leveraged short sell positions. Higher than buy overnight fee due to additional stock borrowing cost on top of leverage interest. Typically equals NonLeveragedSellOverNightFee in sampled data. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN Occurred COMMENT 'Timestamp when this fee configuration was set or last updated by the user/process. Business-layer timestamp (distinct from BeginTime which is the temporal system timestamp). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN UpdatedByUser COMMENT 'Username of the operator who last updated this fee configuration. Null for automated system updates. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN BeginTime COMMENT 'UTC timestamp when this fee configuration became active in Trade.InstrumentToFeeConfig. Functions as SysStartTime in the temporal pattern (non-standard column name). (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN EndTime COMMENT 'UTC timestamp when this fee configuration was superseded. Functions as SysEndTime. Rows with EndTime = ''9999-12-31'' are active in the live table, not here. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
ALTER TABLE main.general.bronze_etoro_history_instrumenttofeeconfig ALTER COLUMN NonLeveragedBuyCFDOverNightFee COMMENT 'Overnight fee for non-leveraged CFD buy positions (contract for difference, no real stock ownership). Added post-initial-design (DEFAULT 0). Distinguishes CFD buy cost from real stock buy cost before V2 added SettlementTypeID to handle this differentiation. (Tier 1 - upstream wiki, etoro.History.InstrumentToFeeConfig)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
