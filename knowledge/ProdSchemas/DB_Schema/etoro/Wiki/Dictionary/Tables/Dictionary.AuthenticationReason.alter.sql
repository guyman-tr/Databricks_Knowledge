-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AuthenticationReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuthenticationReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_authenticationreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_authenticationreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreason SET TBLPROPERTIES (
    'comment' = 'Comprehensive lookup table of 108 document authentication reasons — covering ID verification outcomes from "Ok" through fraud detection, quality issues, data mismatches, and forgery indicators — used by the KYC document verification pipeline. Source: etoro.Dictionary.AuthenticationReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AuthenticationReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AuthenticationReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreason ALTER COLUMN ReasonID COMMENT 'Primary key identifying the authentication outcome. 0=Ok (success), 1-107=specific failure/information codes. Stored in BackOffice.DocumentAuthenticationReasons per document. Written by BackOffice.SetDocumentAuthenticationReasons. Read by BackOffice.GetDocument and BackOffice.GetAllUserDocuments for compliance display. (Tier 1 - upstream wiki, etoro.Dictionary.AuthenticationReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_authenticationreason ALTER COLUMN Reason COMMENT 'Human-readable description of the authentication outcome. Nullable but all current rows have values. Resolved in queries by BackOffice.GetDocumentReason functions. Displayed to compliance officers in the BackOffice document review interface. (Tier 1 - upstream wiki, etoro.Dictionary.AuthenticationReason)';

