-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.InstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_instrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_instrumentconfiguration (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'Per-instrument hedge execution parameter table storing order size thresholds, circuit breaker limits, and HBC deal size guards that the hedge engine applies when routing and validating hedge orders for each instrument. Source: etoro.Hedge.InstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentConfiguration.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'InstrumentConfiguration',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'Primary key and FK to Trade.Instrument(InstrumentID). One row per instrument. All 10,468 instruments have exactly one configuration row. Futures instruments appear in the 200,000+ range; standard equities in 1-100,749. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN MinOrderSizeForExecutionInEToroUnits COMMENT 'Minimum hedge order size before execution is attempted. Orders below this value are skipped. 0 = no minimum (5,039 instruments). Non-zero values range up to 83,334 units; average ~42 for equities, ~2 for futures. Read by GetInstrumentMinOrderSizeForHBC. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN HBCDealSizeThresholdAlertInEToroUnits COMMENT 'HBC (Hedge Bot Controller) warning threshold in eToro units. Orders at or above this size trigger an alert log entry but still execute. Most equity instruments set to 2,000,000. Range 0-20,000,000 in data. Read by GetInstrumentConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN HBCMaxDealSizeThresholdRejectInEToroUnits COMMENT 'HBC hard rejection threshold in eToro units. Orders at or above this size are refused outright - no execution occurs. Typically equal to or higher than the alert threshold. Range 0-9,999,999 in data. Read by GetInstrumentConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN ManualMaxDealSizeInEToroUnits COMMENT 'Maximum deal size permitted via the manual order execution path (distinct from automated HBC path). No NULL values in data (0 null rows). Most instruments set to 200,000. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN SpreadReturnFactor COMMENT 'Multiplier applied to spread calculations. DEFAULT 1; all 10,468 rows have value 1.0000 - this column is currently uniform and appears reserved for future per-instrument spread adjustment. Read by GetAllInstrumentConfigurations. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN CircuitBreakerLimit COMMENT 'Hard cumulative exposure limit. When reached, the circuit breaker halts hedge execution for this instrument. NULL=not configured (5,441 rows); 0=disabled (4,954 rows); 100,000=active (73 rows). Read by GetCircuitBreakerInstrumentThresholds. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN CircuitBreakerWarningLimit COMMENT 'Soft cumulative exposure limit. When reached, generates a warning before the hard limit triggers. Typically equal to or less than CircuitBreakerLimit. NULL or 0 when circuit breaker not configured. Read by GetCircuitBreakerInstrumentThresholds. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML via suser_name(). (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. Managed by SQL Server SYSTEM_VERSIONING. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for all current rows. Historical versions in History.HedgeInstrumentConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN RestrictManualActions COMMENT 'Flag to restrict manual hedge actions for this instrument. DEFAULT 0; all 10,468 rows have value 0 - this column is currently uniform and appears reserved for future per-instrument manual action restriction. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentconfiguration ALTER COLUMN LotSizeForView COMMENT 'Lot size normalization factor for display/reporting purposes. DEFAULT 1; all 10,468 rows have value 1.0000 - currently uniform across all instruments. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentConfiguration)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
