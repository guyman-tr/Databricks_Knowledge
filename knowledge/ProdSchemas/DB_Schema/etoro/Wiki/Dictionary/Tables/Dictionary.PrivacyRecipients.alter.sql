-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PrivacyRecipients
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyRecipients.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_privacyrecipients
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_privacyrecipients (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_privacyrecipients SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 7 data-sharing recipients (Community, Facebook, Twitter, LinkedIn, Google, Yahoo, Live) for eToro''s granular privacy system. Source: etoro.Dictionary.PrivacyRecipients on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyRecipients.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_privacyrecipients SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PrivacyRecipients',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_privacyrecipients ALTER COLUMN PrivacyRecipientID COMMENT 'Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. Values 1-7 represent the 7 supported sharing recipients. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyRecipients)';
ALTER TABLE main.general.bronze_etoro_dictionary_privacyrecipients ALTER COLUMN PrivacyRecipientName COMMENT 'Human-readable name of the data recipient. Used in UI configuration and privacy settings screens. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyRecipients)';

