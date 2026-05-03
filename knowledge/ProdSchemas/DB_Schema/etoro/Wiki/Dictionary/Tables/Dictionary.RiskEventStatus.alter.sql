-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RiskEventStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskEventStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_riskeventstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_riskeventstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_riskeventstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 3 customer risk event lifecycle states - On, InProcess, and Off - with an IsActive flag controlling whether the risk event is currently active. Source: etoro.Dictionary.RiskEventStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RiskEventStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_riskeventstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RiskEventStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_riskeventstatus ALTER COLUMN RiskEventStatusID COMMENT 'Primary key. 1=On, 2=InProcess, 3=Off. Referenced by BackOffice.CustomerRisk and History.CustomerRisk. (Tier 1 - upstream wiki, etoro.Dictionary.RiskEventStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskeventstatus ALTER COLUMN Name COMMENT 'Human-readable status label. Displayed in BackOffice risk management screens and customer risk history. (Tier 1 - upstream wiki, etoro.Dictionary.RiskEventStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_riskeventstatus ALTER COLUMN IsActive COMMENT 'Controls whether this status represents an active risk. 1=risk is active (On, InProcess), 0=risk is resolved (Off). Used for filtering in risk queries and account freezing logic. (Tier 1 - upstream wiki, etoro.Dictionary.RiskEventStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
