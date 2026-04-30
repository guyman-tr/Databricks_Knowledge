-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.LiquidityProviders
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviders.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_liquidityproviders
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_liquidityproviders (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders SET TBLPROPERTIES (
    'comment' = 'Registry of liquidity provider instances (e.g., FXCM Real, FXCM Demo, FD Production) that pair provider type configurations with instance-specific names and settings, used for hedging, price feeds, and liquidity account routing. Source: etoro.Trade.LiquidityProviders on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviders.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'LiquidityProviders',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN LiquidityProviderID COMMENT 'Primary key. Unique identifier for this provider instance. Allocated by Trade.SetNextLiquidityProviderID using gap-fill (lowest missing ID) or MAX+1. Referenced by Trade.LiquidityAccounts, Trade.LiquidityProviderContracts, Trade.LiquidityProviderInstuments. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN LiquidityProviderName COMMENT 'Human-readable instance name (e.g., FXCM Real, FD RealStream Production REAL 208.100.16.161). SetNextLiquidityProviderID uses ''Obsolete! Use Hedge Account'' for placeholder rows. Used in views and reports. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN LiquidityProviderSettingsXML COMMENT 'Instance-specific XML settings. Can override or extend type-level TypeSettingsXML from Trade.LiquidityProviderType. SetNextLiquidityProviderID inserts ''<settings />'' for placeholder rows. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN LiquidityProviderTypeID COMMENT 'FK to Trade.LiquidityProviderType. Provider type: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 5=XIGNITE, 6=MT_GOX, 7=GFT, 8=BitStamp, 11=IB. (Source: Trade.LiquidityProviderType) (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). SQL login that last modified the row. Audit context. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context from context_info. Often NULL when not set by caller. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN SysStartTime COMMENT 'System-versioning start. When this row became effective. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';
ALTER TABLE main.trading.bronze_etoro_trade_liquidityproviders ALTER COLUMN SysEndTime COMMENT 'System-versioning end. When this row was superseded. GENERATED ALWAYS AS ROW END. 9999-12-31 means current. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviders)';

