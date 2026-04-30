-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.InstrumentGroupsMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping SET TBLPROPERTIES (
    'comment' = 'Junction table that assigns individual instruments to instrument groups, enabling the hedge engine to apply group-level execution routing rules to all member instruments simultaneously. Source: etoro.Hedge.InstrumentGroupsMapping on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.InstrumentGroupsMapping.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'InstrumentGroupsMapping',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping ALTER COLUMN InstrumentID COMMENT 'The instrument being assigned to a group. References Trade.Instrument(InstrumentID). Part of the composite PK. Futures instruments appear in the 200000+ ID range. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroupsMapping)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping ALTER COLUMN GroupID COMMENT 'The group this instrument belongs to. Explicit FK to Hedge.InstrumentGroups(GroupID). Part of the composite PK. Values correspond to the 6 defined groups: 1=Futures, 100=Virtu US, 101=Virtu EU, 102=Virtu APAC, 201=OMS-Virtu EU, 202=OMS-Virtu US. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroupsMapping)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping ALTER COLUMN DbLoginName COMMENT 'Computed audit column. SQL Server login executing the DML. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroupsMapping)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping ALTER COLUMN AppLoginName COMMENT 'Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroupsMapping)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping ALTER COLUMN SysStartTime COMMENT 'Temporal period start. UTC timestamp when this row version became active. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroupsMapping)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping ALTER COLUMN SysEndTime COMMENT 'Temporal period end. 9999-12-31 for current rows. History in History.InstrumentGroupsMapping. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroupsMapping)';
ALTER TABLE main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping ALTER COLUMN IsActive COMMENT 'Whether this group membership is currently enforced. 1=active (instrument is in the group, routing rules apply), 0=inactive (instrument removed from group, rules no longer apply). Indexed for efficient WHERE IsActive=1 filtering. DEFAULT 1. (Tier 1 - upstream wiki, etoro.Hedge.InstrumentGroupsMapping)';

