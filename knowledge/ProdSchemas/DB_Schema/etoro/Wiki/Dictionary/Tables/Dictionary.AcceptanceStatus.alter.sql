-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AcceptanceStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AcceptanceStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_acceptancestatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_acceptancestatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_acceptancestatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 4 customer acceptance states — Pending, Accepted, Rejected, and Follow Up — used during the customer onboarding and compliance review process. Source: etoro.Dictionary.AcceptanceStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AcceptanceStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_acceptancestatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AcceptanceStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_acceptancestatus ALTER COLUMN AcceptanceStatusID COMMENT 'Primary key identifying the acceptance state. 0=Pending, 1=Accepted, 2=Rejected, 3=Follow Up. Stored in BackOffice.Customer.AcceptanceStatusID and History.BackOfficeCustomer. Set by BackOffice.CustomerAcceptance, read by BackOffice.GetCustomerByCID. (Tier 1 - upstream wiki, etoro.Dictionary.AcceptanceStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_acceptancestatus ALTER COLUMN Name COMMENT 'Human-readable acceptance state name. Unique constraint enforced (UK_DAS_Name). Used in JOIN queries to resolve IDs to display names in compliance reports and BackOffice views (BackOffice.CustomerSafty). (Tier 1 - upstream wiki, etoro.Dictionary.AcceptanceStatus)';

