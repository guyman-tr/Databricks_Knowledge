-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PhoneTypes
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneTypes.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_phonetypes
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_phonetypes (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_phonetypes SET TBLPROPERTIES (
    'comment' = 'Lookup table defining 15 phone number line types - classifying phone numbers by carrier type (FixedLine, Mobile, VOIP, etc.) for identity verification and fraud prevention. Source: etoro.Dictionary.PhoneTypes on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PhoneTypes.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_phonetypes SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PhoneTypes',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_phonetypes ALTER COLUMN ID COMMENT 'Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. Values 1-15 representing phone line types from verification providers. Referenced in Customer.PhoneVerificationDetails. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneTypes)';
ALTER TABLE main.general.bronze_etoro_dictionary_phonetypes ALTER COLUMN Name COMMENT 'Unique phone type label. Enforced by UNQ_DictionaryPhoneTypes_PhoneType unique constraint. Values: Undetermined, FixedLine, Mobile, PrePaidMobile, TollFree, NonFixedVOIP, Pager, Payphone, Invalid, Restricted, Number, Personal, Voicemail, eToro, Other. (Tier 1 - upstream wiki, etoro.Dictionary.PhoneTypes)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
