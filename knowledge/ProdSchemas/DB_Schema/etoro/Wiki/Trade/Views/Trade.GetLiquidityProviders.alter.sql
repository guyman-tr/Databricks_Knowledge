-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.GetLiquidityProviders
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.GetLiquidityProviders.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_trade_getliquidityproviders
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_trade_getliquidityproviders (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders SET TBLPROPERTIES (
    'comment' = 'Joins liquidity provider instances with their type definitions to expose provider names, settings XML, and pluggable configurations for hedging and price feeds. Source: etoro.Trade.GetLiquidityProviders on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.GetLiquidityProviders.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'GetLiquidityProviders',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders ALTER COLUMN LiquidityProviderID COMMENT 'PK from Trade.LiquidityProviders. Unique identifier for provider instance. (Tier 1 - upstream wiki, etoro.Trade.GetLiquidityProviders)';
ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders ALTER COLUMN LiquidityProviderName COMMENT 'Instance name (e.g., FXCM Real, FD RealStream Production REAL 208.100.16.161). From TLP. (Tier 1 - upstream wiki, etoro.Trade.GetLiquidityProviders)';
ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders ALTER COLUMN LiquidityProviderSettingsXML COMMENT 'Instance-specific XML settings. Can override type-level TypeSettingsXML. From TLP. (Tier 1 - upstream wiki, etoro.Trade.GetLiquidityProviders)';
ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders ALTER COLUMN LiquidityProviderTypeID COMMENT 'FK to Trade.LiquidityProviderType. Provider type: 0=eToro, 1=BMFN, 2=FXCM, 3=FD. From TLP. (Tier 1 - upstream wiki, etoro.Trade.GetLiquidityProviders)';
ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders ALTER COLUMN Name COMMENT 'Provider type name (e.g., FXCM, BMFN) from Trade.LiquidityProviderType. From TLPT. (Tier 1 - upstream wiki, etoro.Trade.GetLiquidityProviders)';
ALTER TABLE main.bi_db.bronze_etoro_trade_getliquidityproviders ALTER COLUMN TypeSettingsXML COMMENT 'Type-level pluggable configuration: assembly/class for price, PCS, execution, hedging. From TLPT. (Tier 1 - upstream wiki, etoro.Trade.GetLiquidityProviders)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
