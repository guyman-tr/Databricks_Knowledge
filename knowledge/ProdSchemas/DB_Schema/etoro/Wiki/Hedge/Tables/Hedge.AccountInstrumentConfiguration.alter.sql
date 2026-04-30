-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.AccountInstrumentConfiguration
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration SET TBLPROPERTIES (
    'comment' = 'Per-account, per-instrument execution configuration table defining limit order price rounding precision and optional execution unit throttling parameters for hedge orders placed through specific accounts. Source: etoro.Hedge.AccountInstrumentConfiguration on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.AccountInstrumentConfiguration.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'AccountInstrumentConfiguration',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN AccountID COMMENT 'The hedge account this configuration applies to. Part of composite PK. Implicit reference to Hedge.Accounts.ID (no FK constraint). Values present: 1, 10 (ZBFX Price2), 308. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN InstrumentID COMMENT 'The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). InstrumentIDs range into the 1,000,000+ range (OMS/platform instruments). (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN MaxExecutionUnitsThreshold COMMENT 'Maximum single hedge order size (in execution units) before band-based sizing logic applies. Currently NULL for all rows - feature designed but not active. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN MaxExecutionUnitsUpperBound COMMENT 'Upper bound of the desired execution size band when MaxExecutionUnitsThreshold is exceeded. Currently NULL. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN MaxExecutionUnitsLowerBound COMMENT 'Lower bound of the desired execution size band when MaxExecutionUnitsThreshold is exceeded. Currently NULL. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN ExecutionUnitsStep COMMENT 'Step granularity for execution unit sizing increments. Currently NULL. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN MaxRequestedPerInterval COMMENT 'Rate limit: maximum number of orders allowed within IntervalPeriodSeconds. Currently NULL for all rows - rate limiting not active. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN IntervalPeriodSeconds COMMENT 'Time window in seconds for the MaxRequestedPerInterval rate limit. Currently NULL. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN LimitRoundPrecision COMMENT 'Number of decimal places for limit order price rounding for this account/instrument pair. -1=no override (use default). Active values: 1, 2, 4. Determines tick-size compliance for limit orders submitted to providers. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.AccountInstrumentConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.AccountInstrumentConfiguration)';

