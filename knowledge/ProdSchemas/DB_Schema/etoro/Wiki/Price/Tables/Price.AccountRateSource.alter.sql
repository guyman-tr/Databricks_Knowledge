-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Price.AccountRateSource
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_price_accountratesource
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_price_accountratesource (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource SET TBLPROPERTIES (
    'comment' = 'Master registry of market data sources and liquidity feed connections used by the eToro pricing engine - each row represents a distinct named provider (Bloomberg, Xignite, ZBFX, Goldman Sachs, etc.) that can supply real-time prices for instruments. Source: etoro.Price.AccountRateSource on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Price/Tables/Price.AccountRateSource.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Price',
    'source_table' = 'AccountRateSource',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource ALTER COLUMN AccountRateSourceID COMMENT 'Primary key. Integer identifier for a price data source. Negative values (-1) are valid special cases. ID 0 = deprecated. IDs 1-6 = simulation feeds. IDs 9001-9006 = FIX protocol connections. IDs 100000+ = large-numbered OMS/institutional feeds. (Tier 1 - upstream wiki, etoro.Price.AccountRateSource)';
ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource ALTER COLUMN Name COMMENT 'Human-readable name of the price source. Used in operations tooling, configuration UIs, and monitoring dashboards. Naming conventions reveal type: "Simulation" = demo feed, "FIX_" prefix = FIX protocol, "Bloomberg" = Bloomberg variants, provider names (ZBFX, Xignite, QuantHouse, etc.) = external vendors. (Tier 1 - upstream wiki, etoro.Price.AccountRateSource)';
ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource ALTER COLUMN DbLoginName COMMENT 'Computed column: captures the SQL Server login name of the user/service account that last modified this row. Set automatically by SQL Server on every DML operation; cannot be overridden by callers. Used for DB-level audit tracking. (Tier 1 - upstream wiki, etoro.Price.AccountRateSource)';
ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource ALTER COLUMN AppLoginName COMMENT 'Computed column: captures the application-level identity via SQL Server context_info(). Populated when the calling application sets context_info before executing DML (e.g., the pricing management service sets its service name). NULL when context_info is not set. Used for app-level audit tracking alongside DbLoginName. (Tier 1 - upstream wiki, etoro.Price.AccountRateSource)';
ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource ALTER COLUMN SysStartTime COMMENT 'Temporal row validity start: timestamp when this version of the row became current. Auto-managed by SQL Server temporal table mechanism. Used with SysEndTime to query point-in-time states of the table via FOR SYSTEM_TIME AS OF. (Tier 1 - upstream wiki, etoro.Price.AccountRateSource)';
ALTER TABLE main.bi_db.bronze_etoro_price_accountratesource ALTER COLUMN SysEndTime COMMENT 'Temporal row validity end: ''9999-12-31...'' = currently active row. When a row is updated, its current version''s SysEndTime is set to now, and a new version starts. Historical versions are in History.AccountRateSource. (Tier 1 - upstream wiki, etoro.Price.AccountRateSource)';

