-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CompoundProperties
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CompoundProperties.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_compoundproperties
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_compoundproperties (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_compoundproperties SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table for CEP.CompoundProperties - automatically captures superseded compound property definitions whenever a property is updated or deleted. Source: etoro.History.CompoundProperties on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CompoundProperties.md).'
);

ALTER TABLE main.general.bronze_etoro_history_compoundproperties SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CompoundProperties',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN CompoundPropertyID COMMENT 'ID of the compound property. Matches CEP.CompoundProperties.CompoundPropertyID (IDENTITY in live table). (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN Name COMMENT 'Name of the compound property definition at this version. (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN ValidFrom COMMENT 'Application-level timestamp when this property version became valid. Updated by trigger on each change. (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN DbLoginName COMMENT 'SQL Server login that made the change. Not a computed column here (stored as nvarchar in history). (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN AppLoginName COMMENT 'Application login from context_info() at change time. (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN SysStartTime COMMENT 'Temporal row start: when this version became current in CEP.CompoundProperties. (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN SysEndTime COMMENT 'Temporal row end: when this version was superseded. Clustered index lead column. (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_compoundproperties ALTER COLUMN HostName COMMENT 'Server hostname at change time. (Tier 1 - upstream wiki, etoro.History.CompoundProperties)';

