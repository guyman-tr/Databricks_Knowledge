-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.CreditAccountMapping
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.CreditAccountMapping.md
-- Layer: bronze
-- UC Target: main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping
-- =============================================================================

-- ---- UC Target: main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping (business_group=experience) ----
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping SET TBLPROPERTIES (
    'comment' = 'Deduplication and ID-generation table that maps external account/transaction identifiers to internal CreditIDs, preventing duplicate credit processing and serving as the identity source for Credit records. Source: fiktivo.AffiliateCommission.CreditAccountMapping on the fiktivo production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.CreditAccountMapping.md).'
);

ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'CreditAccountMapping',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping ALTER COLUMN AccountTypeID COMMENT 'Type of account originating the transaction. Value 1 observed for standard deposits. Part of composite PK for deduplication. Identifies which payment system or account type generated the credit. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditAccountMapping)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping ALTER COLUMN TransactionID COMMENT 'Unique transaction identifier from the payment system. Combined with AccountTypeID and AccountID to form the dedup key. String type allows non-numeric IDs from various payment providers. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditAccountMapping)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping ALTER COLUMN AccountID COMMENT 'Account identifier from the payment system. Typically matches the CID (customer ID) but stored as varchar to accommodate different account numbering systems. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditAccountMapping)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping ALTER COLUMN DateCreated COMMENT 'Timestamp of the credit event. Part of composite PK - allows the same TransactionID to appear on different dates (though unlikely). Uses datetime2 for sub-millisecond precision from source systems. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditAccountMapping)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping ALTER COLUMN CreditInternalID COMMENT 'Auto-incrementing internal ID that becomes Credit.CreditID. Generated on successful insert. Retrieved via SCOPE_IDENTITY() by InsertCredit. NC index supports direct lookup by CreditInternalID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditAccountMapping)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
