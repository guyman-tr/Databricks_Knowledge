-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.HedgeServerToLiquidityAccount
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount SET TBLPROPERTIES (
    'comment' = 'Mapping table assigning liquidity accounts to hedge servers, defining which account a hedge server uses for execution and optionally a separate account for alternative rates/pricing. Source: etoro.Hedge.HedgeServerToLiquidityAccount on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'HedgeServerToLiquidityAccount',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount ALTER COLUMN HedgeServerID COMMENT 'FK to Trade.HedgeServer(HedgeServerID). The hedge server that owns this liquidity account. Non-unique (a server can have multiple account rows, e.g., HedgeServerID=8 has 2 accounts). Indexed via IXHedgeServerID for per-server account lookups. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount ALTER COLUMN LiquidityAccountID COMMENT 'PK and FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity account assigned to the hedge server. Each account belongs to exactly one server (PK enforces this). (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount ALTER COLUMN AltRatesLiquidityAccountID COMMENT 'FK to Trade.LiquidityAccounts(LiquidityAccountID). Optional second account used for alternative rate/price discovery. Currently NULL for all 11 rows - feature defined but not yet configured. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerToLiquidityAccount)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.HedgeServerToLiquidityAccount. (Tier 1 - upstream wiki, etoro.Hedge.HedgeServerToLiquidityAccount)';

