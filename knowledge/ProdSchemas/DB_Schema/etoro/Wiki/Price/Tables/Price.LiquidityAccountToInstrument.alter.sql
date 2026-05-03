-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Price.LiquidityAccountToInstrument
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument SET TBLPROPERTIES (
    'comment' = 'Many-to-many junction table mapping which liquidity accounts service which instruments - 13,901 rows linking 27 liquidity accounts to 6,339 instruments, forming the core of the pricing feed routing configuration that determines which price sources are eligible for each instrument. Source: etoro.Price.LiquidityAccountToInstrument on the etoro production database, ingested via the Generic Pipeline (Override strategy, 30-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.LiquidityAccountToInstrument.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Price',
    'source_table' = 'LiquidityAccountToInstrument',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '30'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument ALTER COLUMN LiquidityAccountID COMMENT 'Liquidity account identifier. Part of the composite PK (primary sort key). FK to Trade.LiquidityAccounts. Represents a price feed connection (e.g., a specific Bloomberg feed, FIX session, or internal price source). Clustered PK sorts by account first, enabling fast "all instruments for this account" lookups. (Tier 1 - upstream wiki, etoro.Price.LiquidityAccountToInstrument)';
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. Part of the composite PK. FK to Trade.Instrument. NC index on InstrumentID alone enables fast reverse lookup: "all eligible accounts for this instrument." (Tier 1 - upstream wiki, etoro.Price.LiquidityAccountToInstrument)';
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument ALTER COLUMN DbLoginName COMMENT 'Computed: SQL Server login of last row modifier. Auto-set by SQL Server on every DML. Used for DB-level audit tracking. (Tier 1 - upstream wiki, etoro.Price.LiquidityAccountToInstrument)';
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument ALTER COLUMN AppLoginName COMMENT 'Computed: application identity from context_info(). Populated when the calling service sets context_info before DML. NULL when not set. (Tier 1 - upstream wiki, etoro.Price.LiquidityAccountToInstrument)';
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument ALTER COLUMN SysStartTime COMMENT 'Temporal row validity start. Auto-managed by SQL Server system versioning. Enables point-in-time configuration queries. (Tier 1 - upstream wiki, etoro.Price.LiquidityAccountToInstrument)';
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument ALTER COLUMN SysEndTime COMMENT 'Temporal row validity end. Historical versions in History.LiquidityAccountToInstrument. (Tier 1 - upstream wiki, etoro.Price.LiquidityAccountToInstrument)';
ALTER TABLE main.bi_db.bronze_etoro_price_liquidityaccounttoinstrument ALTER COLUMN HostName COMMENT 'Computed: DB server hostname that processed the last DML on this row. Unusual column - captures the server host rather than user. Relevant in distributed/replicated environments to trace which server wrote a given mapping. (Tier 1 - upstream wiki, etoro.Price.LiquidityAccountToInstrument)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
