-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.ExposureCircuitBreakerThresholds
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds SET TBLPROPERTIES (
    'comment' = 'Per-instrument, direction-aware circuit breaker configuration table that defines separate USD-denominated alert and trigger thresholds for over-hedged vs under-hedged exposure states. Source: etoro.Hedge.ExposureCircuitBreakerThresholds on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'ExposureCircuitBreakerThresholds',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN InstrumentID COMMENT 'The instrument this circuit breaker applies to. Part of composite PK. No FK constraint - implicit reference to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN IsOverHedged COMMENT 'Direction flag. 1=over-hedged circuit breaker (excess hedge above required), 0=under-hedged circuit breaker (deficit hedge below required). Together with InstrumentID forms the composite PK, allowing distinct thresholds per direction. (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN CircuitBreakerAlertThresholdUSD COMMENT 'USD exposure amount at which a soft alert is triggered. When the direction-specific exposure exceeds this value, an alert is generated but execution continues. Money type (accurate to $0.0001). (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN CircuitBreakerTriggerThresholdUSD COMMENT 'USD exposure amount at which the circuit breaker trips. When exceeded, hedge execution for this instrument halts. Should be >= CircuitBreakerAlertThresholdUSD. Money type. (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.ExposureCircuitBreakerThresholds. (Tier 1 - upstream wiki, etoro.Hedge.ExposureCircuitBreakerThresholds)';

