-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.InstrumentGroups
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_instrumentgroups
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_instrumentgroups (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups SET TBLPROPERTIES (
    'comment' = 'Registry of named instrument groups used by the hedge engine to apply routing rules, order type configurations, and execution policies to sets of instruments collectively rather than one by one. Source: etoro.Hedge.InstrumentGroups on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroups.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'InstrumentGroups',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups ALTER COLUMN GroupID COMMENT 'Primary key. Manually assigned integer identifying the instrument group. Numbering convention: 1=instrument-type groups, 100-102=Virtu direct path by region, 201-202=OMS/Virtu path by region. NOT IDENTITY - values are explicitly chosen to encode group category. Referenced by Hedge.InstrumentGroupsMapping and Hedge.OrderTypeConfiguration. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroups)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups ALTER COLUMN GroupName COMMENT 'Human-readable name for the group (e.g., "Futures", "Virtu UnManaged US Flow Direct"). Used in GetInstrumentGroupsMapping output returned to the hedge engine and in admin interfaces. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroups)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups ALTER COLUMN Description COMMENT 'Optional free-text description of the group''s purpose (e.g., "US Names of the Unmanaged Flow into Virtu"). Informational only - not used by any procedure logic. NULL allowed but always populated in practice. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroups)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML via suser_name(). (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroups)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroups)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. Original Futures group created 2024-11-06; Virtu/OMS groups added 2025-09-21. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroups)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroups ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for all currently active rows. History in History.InstrumentGroups. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroups)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
