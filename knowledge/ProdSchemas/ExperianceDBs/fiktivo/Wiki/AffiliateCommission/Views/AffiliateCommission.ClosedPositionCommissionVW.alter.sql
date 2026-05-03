-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.ClosedPositionCommissionVW
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw
--   main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw SET TBLPROPERTIES (
    'comment' = 'Commission reporting view joining ClosedPositionCommission with ClosedPosition and PaymentHistory to provide commission records with computed UpdateDate reflecting the later of commission calculation or payment date. Source: fiktivo.AffiliateCommission.ClosedPositionCommissionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'ClosedPositionCommissionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw ALTER COLUMN ClosedPositionID COMMENT 'From ClosedPosition. Position identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw ALTER COLUMN AffiliateID COMMENT 'From ClosedPositionCommission. Earning affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw ALTER COLUMN Commission COMMENT 'From ClosedPositionCommission. Commission amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw ALTER COLUMN Tier COMMENT 'From ClosedPositionCommission. Commission tier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw ALTER COLUMN Paid COMMENT 'From ClosedPositionCommission. Payment status. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw ALTER COLUMN PaymentID COMMENT 'From ClosedPositionCommission. Payment batch. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(PaymentDate, CommissionDate) when paid; CommissionDate when unpaid. For CDC watermarks. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission SET TBLPROPERTIES (
    'comment' = 'Commission reporting view joining ClosedPositionCommission with ClosedPosition and PaymentHistory to provide commission records with computed UpdateDate reflecting the later of commission calculation or payment date. Source: fiktivo.AffiliateCommission.ClosedPositionCommissionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'ClosedPositionCommissionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission ALTER COLUMN ClosedPositionID COMMENT 'From ClosedPosition. Position identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission ALTER COLUMN AffiliateID COMMENT 'From ClosedPositionCommission. Earning affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission ALTER COLUMN Commission COMMENT 'From ClosedPositionCommission. Commission amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission ALTER COLUMN Tier COMMENT 'From ClosedPositionCommission. Commission tier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission ALTER COLUMN Paid COMMENT 'From ClosedPositionCommission. Payment status. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission ALTER COLUMN PaymentID COMMENT 'From ClosedPositionCommission. Payment batch. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(PaymentDate, CommissionDate) when paid; CommissionDate when unpaid. For CDC watermarks. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionCommissionVW)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
