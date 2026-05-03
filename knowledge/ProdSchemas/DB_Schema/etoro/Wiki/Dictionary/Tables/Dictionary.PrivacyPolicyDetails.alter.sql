-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PrivacyPolicyDetails
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyPolicyDetails.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_privacypolicydetails
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_privacypolicydetails (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicydetails SET TBLPROPERTIES (
    'comment' = 'Junction table mapping privacy policies to specific privacy-sensitive events and data recipients - controlling granular per-event data sharing on the eToro social trading platform. Source: etoro.Dictionary.PrivacyPolicyDetails on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PrivacyPolicyDetails.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicydetails SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PrivacyPolicyDetails',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicydetails ALTER COLUMN ID COMMENT 'Auto-incrementing surrogate primary key. IDENTITY NOT FOR REPLICATION. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyPolicyDetails)';
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicydetails ALTER COLUMN PrivacyPolicyID COMMENT 'FK -> Dictionary.PrivacyPolicy.PrivacyPolicyID. Identifies which privacy policy this grant belongs to. 1=Share All, 2=Don''t Share. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyPolicyDetails)';
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicydetails ALTER COLUMN PrivacyEventID COMMENT 'FK -> Dictionary.PrivacyEvents.PrivacyEventID. Identifies the privacy-sensitive event being controlled. Currently only 1=Championship. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyPolicyDetails)';
ALTER TABLE main.general.bronze_etoro_dictionary_privacypolicydetails ALTER COLUMN PrivacyRecipientID COMMENT 'FK -> Dictionary.PrivacyRecipients.PrivacyRecipientID. Identifies who receives the data. 1=Community, 2=Facebook, 3=Twitter, etc. (Tier 1 - upstream wiki, etoro.Dictionary.PrivacyPolicyDetails)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
