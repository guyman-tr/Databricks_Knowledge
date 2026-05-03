-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.DBA.V_NumRows_Sizes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DBA/Views/DBA.V_NumRows_Sizes.md
-- Layer: bronze
-- UC Target: main.config.bronze_userapidb_dba_v_numrows_sizes
-- =============================================================================

-- ---- UC Target: main.config.bronze_userapidb_dba_v_numrows_sizes (business_group=config) ----
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes SET TBLPROPERTIES (
    'comment' = 'DBA monitoring view reporting row counts and storage sizes (in MB) for all tables in the database, sourced from sys.tables, sys.partitions, and sys.allocation_units. Source: UserApiDB.DBA.V_NumRows_Sizes on the UserApiDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/DBA/Views/DBA.V_NumRows_Sizes.md).'
);

ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'DBA',
    'source_table' = 'V_NumRows_Sizes',
    'business_group' = 'config',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes ALTER COLUMN DateID COMMENT 'Snapshot date in YYYYMMDD integer format. Used as partition/filter key when inserted into monitoring tables. (Tier 1 - upstream wiki, UserApiDB.DBA.V_NumRows_Sizes)';
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes ALTER COLUMN ServerName COMMENT 'Current SQL Server instance name from @@SERVERNAME. Identifies the source server in multi-server monitoring aggregations. (Tier 1 - upstream wiki, UserApiDB.DBA.V_NumRows_Sizes)';
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes ALTER COLUMN DBName COMMENT 'Current database name from DB_NAME(). Identifies the source database. (Tier 1 - upstream wiki, UserApiDB.DBA.V_NumRows_Sizes)';
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes ALTER COLUMN SchemaName COMMENT 'Schema name of the table (from sys.schemas via SCHEMA_NAME). (Tier 1 - upstream wiki, UserApiDB.DBA.V_NumRows_Sizes)';
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes ALTER COLUMN TableName COMMENT 'Table name from sys.tables.name. (Tier 1 - upstream wiki, UserApiDB.DBA.V_NumRows_Sizes)';
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes ALTER COLUMN NumRecords COMMENT 'Approximate row count from sys.partitions. Reflects the last statistics update; may be slightly stale. (Tier 1 - upstream wiki, UserApiDB.DBA.V_NumRows_Sizes)';
ALTER TABLE main.config.bronze_userapidb_dba_v_numrows_sizes ALTER COLUMN SizeMB COMMENT 'Allocated storage in megabytes. Calculated as used pages × 8KB / 1024. Includes data and LOB pages. (Tier 1 - upstream wiki, UserApiDB.DBA.V_NumRows_Sizes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
