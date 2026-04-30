-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.RegistrationCommissionVW
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationCommissionVW.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission
--   main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission SET TBLPROPERTIES (
    'comment' = 'Commission reporting view joining RegistrationCommission with Registration and PaymentHistory, providing registration commission records with payment-aware UpdateDate for BI incremental loading. Source: fiktivo.AffiliateCommission.RegistrationCommissionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationCommissionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'RegistrationCommissionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission ALTER COLUMN RegistrationID COMMENT 'From Registration. Registration identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission ALTER COLUMN AffiliateID COMMENT 'From RegistrationCommission. Earning affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission ALTER COLUMN Commission COMMENT 'From RegistrationCommission. Commission amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission ALTER COLUMN Tier COMMENT 'From RegistrationCommission. Commission tier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission ALTER COLUMN Paid COMMENT 'From RegistrationCommission. Payment status. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission ALTER COLUMN PaymentID COMMENT 'From RegistrationCommission. Payment batch. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(PaymentDate, RegistrationDate) when paid. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw SET TBLPROPERTIES (
    'comment' = 'Commission reporting view joining RegistrationCommission with Registration and PaymentHistory, providing registration commission records with payment-aware UpdateDate for BI incremental loading. Source: fiktivo.AffiliateCommission.RegistrationCommissionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationCommissionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'RegistrationCommissionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw ALTER COLUMN RegistrationID COMMENT 'From Registration. Registration identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw ALTER COLUMN AffiliateID COMMENT 'From RegistrationCommission. Earning affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw ALTER COLUMN Commission COMMENT 'From RegistrationCommission. Commission amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw ALTER COLUMN Tier COMMENT 'From RegistrationCommission. Commission tier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw ALTER COLUMN Paid COMMENT 'From RegistrationCommission. Payment status. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw ALTER COLUMN PaymentID COMMENT 'From RegistrationCommission. Payment batch. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(PaymentDate, RegistrationDate) when paid. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationCommissionVW)';

