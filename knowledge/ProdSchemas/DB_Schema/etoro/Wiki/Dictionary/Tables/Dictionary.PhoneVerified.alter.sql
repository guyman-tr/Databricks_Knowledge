-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PhoneVerified
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerified.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_phoneverified
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_phoneverified (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverified SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 6 phone verification states — from NotVerified through AutomaticallyVerified, ManuallyVerified, Initiated, Rejected, and AbuseFlag — tracking customer phone number verification lifecycle. Source: etoro.Dictionary.PhoneVerified on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneVerified.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_phoneverified SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PhoneVerified',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverified ALTER COLUMN PhoneVerifiedID COMMENT 'Primary key identifying the phone verification state. 0=NotVerified, 1=AutomaticallyVerified, 2=ManuallyVerified, 3=Initiated, 4=Rejected, 5=AbuseFlag. Stored in BackOffice.Customer and History.BackOfficeCustomer. Referenced by 20+ procedures across BackOffice, Customer, SalesForce, and dbo schemas. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerified)';
ALTER TABLE main.general.bronze_etoro_dictionary_phoneverified ALTER COLUMN PhoneVerifiedName COMMENT 'Human-readable verification state label. Note: "ManualyVerified" contains a typo (single ''l'') preserved from the original data. Displayed in customer cards, verification reports, and compliance dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneVerified)';

