-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.CreditCommissionVW
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission
--   main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission SET TBLPROPERTIES (
    'comment' = 'Commission reporting view joining CreditCommission with Credit and PaymentHistory, providing credit commission records with payment-aware UpdateDate for BI incremental loading. Source: fiktivo.AffiliateCommission.CreditCommissionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'CreditCommissionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN CreditID COMMENT 'From Credit. Credit event identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN AffiliateID COMMENT 'From CreditCommission. Earning affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN Commission COMMENT 'From CreditCommission. Commission amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN Tier COMMENT 'From CreditCommission. Commission tier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN Paid COMMENT 'From CreditCommission. Payment status. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN PaymentID COMMENT 'From CreditCommission. Payment batch. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN AffiliateTypeID COMMENT 'From CreditCommission. Affiliate type classification (PART-2448). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(PaymentDate, CreditDate) when paid. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw SET TBLPROPERTIES (
    'comment' = 'Commission reporting view joining CreditCommission with Credit and PaymentHistory, providing credit commission records with payment-aware UpdateDate for BI incremental loading. Source: fiktivo.AffiliateCommission.CreditCommissionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'CreditCommissionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN CreditID COMMENT 'From Credit. Credit event identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN AffiliateID COMMENT 'From CreditCommission. Earning affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN Commission COMMENT 'From CreditCommission. Commission amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN Tier COMMENT 'From CreditCommission. Commission tier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN Paid COMMENT 'From CreditCommission. Payment status. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN PaymentID COMMENT 'From CreditCommission. Payment batch. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN AffiliateTypeID COMMENT 'From CreditCommission. Affiliate type classification (PART-2448). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(PaymentDate, CreditDate) when paid. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditCommissionVW)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
