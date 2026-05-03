-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.LiquidityAccounts
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityAccounts.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_liquidityaccounts
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_liquidityaccounts (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts SET TBLPROPERTIES (
    'comment' = 'Configuration table for liquidity provider accounts that store credentials, provider linkage, and rate-source mapping used for price feeds and hedge execution. Source: etoro.Trade.LiquidityAccounts on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityAccounts.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'LiquidityAccounts',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN LiquidityAccountID COMMENT 'Primary key. Allocated by Trade.SetNextLiquidityAccountID using gap-fill (lowest missing ID) or MAX+1. Mirrored to Hedge.Accounts.ID. Referenced by Price.InstrumentRateSources, Hedge.ExecutionLog, Hedge.HBCAccountConfiguration. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN LiquidityAccountName COMMENT 'Human-readable account name (e.g., Simulation Non Stocks, ZBFX Price1 Rates). SetNextLiquidityAccountID uses ''{Name} - Obsolete! Use Hedge Account'' for placeholder rows. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN LiquidityProviderID COMMENT 'FK to Trade.LiquidityProviders. Links account to provider instance (e.g., FXCM Real=2, FD=4, ZBFX=69). (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN Username COMMENT 'Login username for the external broker. Empty string for simulation/placeholder accounts. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN Password COMMENT 'Login password for the external broker. Empty for simulation. Audited on INSERT/UPDATE/DELETE. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN SettingsXML COMMENT 'Account-specific XML settings. SetNextLiquidityAccountID inserts ''<settings />'' for placeholder rows. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN IsActive COMMENT '1 = active (account in use), 0 = inactive. Trade.GetLiquidityAccounts filters WHERE IsActive = 1. Default 1. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN LiquidityAccountTypeID COMMENT 'FK to Dictionary.LiquidityAccountType. 0=NONE, 1=Price Account, 2=Execution Account, 3=Price and Execution, 4=OMS IM Pricing. Default 1. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN AccountRateSourceID COMMENT 'FK to Price.AccountRateSource. Maps account to price feed. 0="Do not use!", -1="US". Used for instrument rate source allocation. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). SQL login that last modified the row. Audit context. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context. Often NULL when not set. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN SysStartTime COMMENT 'System-versioning start. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityaccounts ALTER COLUMN SysEndTime COMMENT 'System-versioning end. GENERATED ALWAYS AS ROW END. 9999-12-31 means current. (Tier 1 - upstream wiki, etoro.Trade.LiquidityAccounts)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
