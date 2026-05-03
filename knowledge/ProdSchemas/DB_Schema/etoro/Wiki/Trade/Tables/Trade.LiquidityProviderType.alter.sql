-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.LiquidityProviderType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_trade_liquidityprovidertype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_trade_liquidityprovidertype (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype SET TBLPROPERTIES (
    'comment' = 'Dictionary table that defines liquidity provider types (e.g., eToro internal, FXCM, BMFN, FD) with pluggable price and execution provider configurations. Source: etoro.Trade.LiquidityProviderType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.LiquidityProviderType.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'LiquidityProviderType',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype ALTER COLUMN LiquidityProviderTypeID COMMENT 'Primary key. Provider type identifier. Value map from live data: 0=eToro, 1=BMFN, 2=FXCM, 3=FD, 4=CNX, 5=XIGNITE, 6=MT_GOX, 7=GFT, 8=BitStamp, 11=IB. Hedge.AddAccountStatus branches on 3 and 11. (Source: Trade.LiquidityProviderType) (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderType)';
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype ALTER COLUMN Name COMMENT 'Human-readable provider type name (e.g., eToro, FXCM, BMFN). Used in views and reports. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderType)';
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype ALTER COLUMN TypeSettingsXML COMMENT 'Pluggable configuration: assembly/class for priceClassInfo, PCSClassInfo, executionClassInfo, HedgingProviderClassInfo. Includes ProviderExecutionSettings (default_lot_size) and OnixsEngineSettings for external providers. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderType)';
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype ALTER COLUMN DbLoginName COMMENT 'Computed: suser_name(). SQL login that last modified the row. Audit context. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderType)';
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype ALTER COLUMN AppLoginName COMMENT 'Computed: CONVERT(varchar(500), context_info()). Application context from context_info. Often NULL when not set by caller. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderType)';
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype ALTER COLUMN SysStartTime COMMENT 'System-versioning start. When this row became effective. GENERATED ALWAYS AS ROW START. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderType)';
ALTER TABLE main.bi_db.bronze_etoro_trade_liquidityprovidertype ALTER COLUMN SysEndTime COMMENT 'System-versioning end. When this row was superseded. GENERATED ALWAYS AS ROW END. 9999-12-31 means current. (Tier 1 - upstream wiki, etoro.Trade.LiquidityProviderType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
