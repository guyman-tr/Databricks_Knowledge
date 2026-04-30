-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.CEP_LOG_CompoundProperties
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_CompoundProperties.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_cep_log_compoundproperties
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_cep_log_compoundproperties (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundproperties SET TBLPROPERTIES (
    'comment' = 'Trigger-based audit log capturing previous versions of CEP compound property definitions whenever they are updated or deleted; records the name and validity period of each changed compound property. Source: etoro.History.CEP_LOG_CompoundProperties on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.CEP_LOG_CompoundProperties.md).'
);

ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundproperties SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'CEP_LOG_CompoundProperties',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundproperties ALTER COLUMN CompoundPropertyID COMMENT 'Identifies the compound property that was changed. PK in CEP.CompoundProperties. Part of composite PK here. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundproperties ALTER COLUMN Name COMMENT 'The name of the compound property as it existed before this change. A compound property groups conditions into a reusable logical expression (e.g., "HighRiskInstrument", "LargeBuyPosition"). (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundproperties ALTER COLUMN ValidFrom COMMENT 'Timestamp when this version of the compound property became active. Copied from the parent row''s ValidFrom column. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundProperties)';
ALTER TABLE main.general.bronze_etoro_history_cep_log_compoundproperties ALTER COLUMN ValidTo COMMENT 'Timestamp when this version was superseded (when the UPDATE or DELETE triggered). Defaults to getutcdate() at INSERT time. Part of composite PK. (Tier 1 - upstream wiki, etoro.History.CEP_LOG_CompoundProperties)';

