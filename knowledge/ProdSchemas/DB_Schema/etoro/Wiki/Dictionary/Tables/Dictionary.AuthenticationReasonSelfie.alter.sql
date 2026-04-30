-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AuthenticationReasonSelfie
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuthenticationReasonSelfie.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_authenticationreasonselfie
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_authenticationreasonselfie (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonselfie SET TBLPROPERTIES (
    'comment' = 'Lookup table for selfie-specific document authentication reasons during biometric verification. Exists in SSDT but not deployed to the live database — likely replaced by the unified Dictionary.AuthenticationReason table. Source: etoro.Dictionary.AuthenticationReasonSelfie on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuthenticationReasonSelfie.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonselfie SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AuthenticationReasonSelfie',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonselfie ALTER COLUMN ReasonID COMMENT 'Primary key for selfie-specific authentication reason. Same structure as Dictionary.AuthenticationReason.ReasonID. Table not deployed — selfie reasons consolidated into the main AuthenticationReason table (IDs 47-52, 103-106). (Tier 1 - upstream wiki, etoro.Dictionary.AuthenticationReasonSelfie)';
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreasonselfie ALTER COLUMN Reason COMMENT 'Human-readable selfie authentication reason. Same structure as Dictionary.AuthenticationReason.Reason. (Tier 1 - upstream wiki, etoro.Dictionary.AuthenticationReasonSelfie)';

