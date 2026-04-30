-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.InterestRateOverride
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_interestrateoverride
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_interestrateoverride (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride SET TBLPROPERTIES (
    'comment' = 'Temporal history table capturing all changes to per-instrument (or per-exchange or per-instrument-type) interest rate overrides, recording the complete audit trail of custom overnight fee rates that supersede the default base rates for specific instruments or categories. Source: etoro.History.InterestRateOverride on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InterestRateOverride.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'InterestRateOverride',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN InterestRateOverrideID COMMENT 'Surrogate PK for the override record. IDENTITY(1,1) in the live table. Uniquely identifies each override rule. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN InstrumentID COMMENT 'Specific instrument this override applies to. NULL = override is not instrument-specific. FK to Trade.Instrument in the live table. When NOT NULL, this is the highest-priority override scope. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN ExchangeID COMMENT 'Specific exchange this override applies to. NULL = not exchange-specific. When InstrumentID is NULL but ExchangeID is NOT NULL, applies to all instruments on that exchange. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type this override applies to. NULL = not type-specific (would be a catch-all). When both InstrumentID and ExchangeID are NULL, applies to all instruments of this type. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN UpdatedByUser COMMENT 'Username of operator or service that set this override. NOT NULL - always attributed to a user or automated process. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN InterestRateBuy COMMENT 'Override market benchmark rate for long buy positions. Replaces the default InterestRate.InterestRateBuy for matched instruments. Negative values mean customer receives overnight credit on long positions. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN InterestRateSell COMMENT 'Override market benchmark rate for short sell positions. Replaces the default rate for matched instruments. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN MarkupBuy COMMENT 'eToro markup applied on top of InterestRateBuy for buy positions in this override. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN MarkupSell COMMENT 'eToro markup applied on top of InterestRateSell for sell positions in this override. Negative values reduce the effective sell rate. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN BeginTime COMMENT 'UTC timestamp when this override became active in Dictionary.InterestRateOverride (non-standard name for SysStartTime). (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN EndTime COMMENT 'UTC timestamp when this override was superseded (non-standard name for SysEndTime). (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN OverNightFeePatternID COMMENT 'Fee pattern for this override: 0=Regular, 1=WithNonLeverageFee, 2=Manual. Nullable - when NULL, inherits pattern from the base InterestRate table. (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';
ALTER TABLE main.bi_db.bronze_etoro_history_interestrateoverride ALTER COLUMN SettlementTypeID COMMENT 'Settlement type this override applies to: 0=CFD, 1=REAL, 2=TRS, etc. DEFAULT 0 = CFD. (Dictionary.SettlementTypes). (Tier 1 - upstream wiki, etoro.History.InterestRateOverride)';

