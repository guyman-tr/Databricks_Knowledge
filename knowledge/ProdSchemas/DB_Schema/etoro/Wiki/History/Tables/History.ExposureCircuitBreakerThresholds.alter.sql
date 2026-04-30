-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ExposureCircuitBreakerThresholds
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds SET TBLPROPERTIES (
    'comment' = 'SQL Server system-versioned temporal history table for Hedge.ExposureCircuitBreakerThresholds, recording every change to per-instrument exposure circuit breaker alert and trigger thresholds with precise row-validity timestamps for auditing configuration adjustments. Source: etoro.History.ExposureCircuitBreakerThresholds on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ExposureCircuitBreakerThresholds.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ExposureCircuitBreakerThresholds',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN InstrumentID COMMENT 'Trading instrument identifier. Matches the InstrumentID in the source table Hedge.ExposureCircuitBreakerThresholds PK (InstrumentID, IsOverHedged). Multiple rows with the same InstrumentID+IsOverHedged represent successive threshold configuration versions. Implicit FK to Trade.Instrument - no constraint in this history table per SQL Server temporal history table conventions. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN IsOverHedged COMMENT 'The hedging direction this threshold row governs. 1 = over-hedged direction (circuit breaker for when the instrument has more hedge than needed, excess long exposure), 0 = under-hedged direction (circuit breaker for when the instrument has less hedge than needed, excess short/open exposure). Forms the second component of the source table''s composite PK - each instrument has exactly two threshold rows, one per direction. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN CircuitBreakerAlertThresholdUSD COMMENT 'USD exposure amount at which an alert notification fires. First tier of the two-tier circuit breaker system. When live instrument exposure (over-hedged or under-hedged depending on IsOverHedged) exceeds this amount, the risk/hedging monitoring system generates an alert for operator attention. Always less than CircuitBreakerTriggerThresholdUSD. All values in USD regardless of instrument currency. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN CircuitBreakerTriggerThresholdUSD COMMENT 'USD exposure amount at which the circuit breaker actually trips, potentially halting further hedging or execution for this instrument. Second tier of the two-tier system. Monitor.AlertForDealingMarketDataConfigurationManager validates that this value does not exceed $10,000,000 for tradable, publicly visible instruments (FeedID=1, Tradable=1, VisibleInternallyOnly=0). Exceeding the $10M limit generates a monitoring alert. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN DbLoginName COMMENT 'SQL Server login name (suser_name()) of the database session that made the configuration change captured in this version. Computed column in Hedge.ExposureCircuitBreakerThresholds, materialized into this history table at version creation time. Identifies the operator or service account that changed the threshold. NULL if the session context was not set. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN AppLoginName COMMENT 'Application-level login from SQL Server context_info() at time of change. Computed column in Hedge.ExposureCircuitBreakerThresholds as CONVERT(varchar(500), context_info()). Populated by application services that set context_info before modifying threshold configuration. NULL if the calling application did not set context_info. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this row version became active in Hedge.ExposureCircuitBreakerThresholds. GENERATED ALWAYS AS ROW START in the source table. Records when the threshold configuration was set. Due to the INSERT trigger pattern (Section 2.2), the initial-creation version has SysStartTime very slightly before SysEndTime (milliseconds apart for the trigger-forced no-op update). Subsequent versions have longer validity windows. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_history_exposurecircuitbreakerthresholds ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this row version was superseded by a new threshold configuration. GENERATED ALWAYS AS ROW END in the source table. CLUSTERED index leading column for efficient temporal range scans by time window. SysEndTime close to SysStartTime (milliseconds apart) marks rows created by the INSERT trigger capture pattern. (Tier 1 - upstream wiki, etoro.History.ExposureCircuitBreakerThresholds)';

