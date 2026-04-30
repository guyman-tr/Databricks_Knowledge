-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PrivacyPolicy
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyPolicy.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_privacypolicy
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_privacypolicy (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicy SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 2 customer privacy policies — "Share All" (default, public profile) and "Don''t Share" (private profile) — controlling data visibility across the eToro social trading platform. Source: etoro.Dictionary.PrivacyPolicy on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyPolicy.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicy SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PrivacyPolicy',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicy ALTER COLUMN PrivacyPolicyID COMMENT 'Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. 1=Share All, 2=Don''t Share. Stored in Customer.CustomerStatic and referenced by 20+ procedures across Customer, BackOffice, SalesForce, STS, and GDPR schemas. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyPolicy)';
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicy ALTER COLUMN PrivacyName COMMENT 'Human-readable policy label. "Share All" or "Don''t Share". Displayed in user settings, BackOffice customer cards, and privacy configuration screens. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyPolicy)';
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicy ALTER COLUMN IsDefault COMMENT 'Indicates which policy is assigned to new accounts by default. 1=default (Share All), 0=not default (Don''t Share). Used by registration procedures to set the initial privacy policy. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyPolicy)';

