-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Customer.TncSignature
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.TncSignature.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_customer_tncsignature
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_customer_tncsignature (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature SET TBLPROPERTIES (
    'comment' = 'Records each instance of a user signing/accepting Terms and Conditions, including the method of consent and document version. Source: UserApiDB.Customer.TncSignature on the UserApiDB production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.TncSignature.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'TncSignature',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature ALTER COLUMN SignID COMMENT 'Surrogate PK (NONCLUSTERED). Auto-incrementing signature record identifier. (Tier 1 - upstream wiki, UserApiDB.Customer.TncSignature)';
ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature ALTER COLUMN GCID COMMENT 'Part of clustered index. Global Customer ID. Multiple signatures per user expected. (Tier 1 - upstream wiki, UserApiDB.Customer.TncSignature)';
ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature ALTER COLUMN SignDate COMMENT 'Part of clustered index (DESC). When the user accepted the TnC. (Tier 1 - upstream wiki, UserApiDB.Customer.TncSignature)';
ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature ALTER COLUMN DocumentID COMMENT 'TnC document version identifier. Tracks which version of the terms was accepted. (Tier 1 - upstream wiki, UserApiDB.Customer.TncSignature)';
ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature ALTER COLUMN ReasonID COMMENT 'FK to Dictionary.SignTncReason. Consent method: 0=By User (explicit), 1=DeepLink, 2=Negative Consent. Default: 0. See Sign TnC Reason. (Tier 1 - upstream wiki, UserApiDB.Customer.TncSignature)';
ALTER TABLE main.compliance.bronze_userapidb_customer_tncsignature ALTER COLUMN IsImplicit COMMENT 'Whether this was an implicit acceptance (e.g., continuing to use the platform after notification) vs explicit action. (Tier 1 - upstream wiki, UserApiDB.Customer.TncSignature)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
