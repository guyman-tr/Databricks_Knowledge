-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.UserValidationErrors
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.UserValidationErrors.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_apex_uservalidationerrors
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_apex_uservalidationerrors (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_apex_uservalidationerrors SET TBLPROPERTIES (
    'comment' = 'Junction table linking customers to their current set of Apex validation errors, replaced atomically on each state transition to reflect the latest validation failures. Source: USABroker.apex.UserValidationErrors on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.UserValidationErrors.md).'
);

ALTER TABLE main.finance.bronze_usabroker_apex_uservalidationerrors SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'UserValidationErrors',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_apex_uservalidationerrors ALTER COLUMN GCID COMMENT 'Global Customer ID. Part of composite PK. FK to Apex.State(GCID). Multiple error rows per customer are common. (Tier 1 - upstream wiki, USABroker.apex.UserValidationErrors)';
ALTER TABLE main.finance.bronze_usabroker_apex_uservalidationerrors ALTER COLUMN ApexValidationErrorID COMMENT 'The specific validation error. FK to Dictionary.ApexValidationError. 50 possible values covering field errors (4-7), form errors (8-11), compliance blocks (38-39), and CIP failures (43-50). See Apex Validation Error. (Dictionary.ApexValidationError) (Tier 1 - upstream wiki, USABroker.apex.UserValidationErrors)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:47:20 UTC
-- Bronze deploy: USABroker batch 1
-- ====================
