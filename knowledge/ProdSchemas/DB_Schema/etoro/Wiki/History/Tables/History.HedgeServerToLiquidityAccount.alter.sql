-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.HedgeServerToLiquidityAccount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount SET TBLPROPERTIES (
    'comment' = 'SQL Server system-versioned temporal history table for Hedge.HedgeServerToLiquidityAccount, recording every change to the mapping between hedge servers and their assigned liquidity provider accounts. Source: etoro.History.HedgeServerToLiquidityAccount on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.HedgeServerToLiquidityAccount.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'HedgeServerToLiquidityAccount',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount ALTER COLUMN HedgeServerID COMMENT 'The hedging engine server instance. FK to Trade.HedgeServer(HedgeServerID). One server can have multiple liquidity accounts. NONCLUSTERED index on source for fast lookup of all accounts per server. 12 distinct servers in history. (Tier 1 - upstream wiki, etoro.History.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount ALTER COLUMN LiquidityAccountID COMMENT 'The external liquidity provider account used for hedge execution. FK to Trade.LiquidityAccounts(LiquidityAccountID). PK in source - each liquidity account belongs to exactly one hedge server. Used by History.HedgeFailInfo to resolve the account when recording failures. (Tier 1 - upstream wiki, etoro.History.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount ALTER COLUMN AltRatesLiquidityAccountID COMMENT 'Optional alternative liquidity account used for rate/price data (distinct from execution). FK to Trade.LiquidityAccounts(LiquidityAccountID). NULL in all 42 observed history rows - reserved for multi-rate scenarios. (Tier 1 - upstream wiki, etoro.History.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount ALTER COLUMN DbLoginName COMMENT 'SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Observed values: domain accounts ("TRAD\dotanva", "TRAD\Noah", "TRAD\ranlev", "TRAD\rivkaya") and "DevTradingSTG" for direct SQL. (Tier 1 - upstream wiki, etoro.History.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount ALTER COLUMN AppLoginName COMMENT 'Application context from context_info() at time of change. Format: "username;ConfigurationManager\0\0..." with null-byte padding (context_info written as Unicode from a .NET application). The tool name after the semicolon is "ConfigurationManager". (Tier 1 - upstream wiki, etoro.History.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this server-to-account mapping version became active. Source DEFAULT=getutcdate(). For INSERT-trigger-captured rows, equals SysEndTime. Earliest observed: 2021-09-13. (Tier 1 - upstream wiki, etoro.History.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this mapping version was superseded. CLUSTERED index leading column. Source DEFAULT=''9999-12-31''. Latest observed: 2026-02-25. (Tier 1 - upstream wiki, etoro.History.HedgeServerToLiquidityAccount)';

