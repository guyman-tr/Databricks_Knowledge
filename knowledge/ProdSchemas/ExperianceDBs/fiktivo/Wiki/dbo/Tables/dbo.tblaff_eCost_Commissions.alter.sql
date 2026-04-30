-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_eCost_Commissions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost_Commissions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions SET TBLPROPERTIES (
    'comment' = 'Stores tier-based affiliate commission records from eCost (effective cost/revenue share) events, with trigger-enforced RI linking to tblaff_eCost and tblaff_Affiliates. Source: fiktivo.dbo.tblaff_eCost_Commissions on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost_Commissions.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_eCost_Commissions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN ID COMMENT 'Auto-incrementing primary key. NOT FOR REPLICATION. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN eCostID COMMENT 'References tblaff_eCost.eCostID. Trigger enforces RI. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN AffiliateID COMMENT 'The affiliate receiving this commission. Trigger enforces RI. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN Commission COMMENT 'eCost commission amount for this tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN Tier COMMENT 'Commission tier level: 1-5. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN Paid COMMENT 'Payment status: 0 = unpaid, 1 = paid. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN PaymentID COMMENT 'References tblaff_PaymentHistory.PaymentID when paid. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN SubAffiliateID COMMENT 'Sub-affiliate tracking tag. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions ALTER COLUMN eCost COMMENT 'Platform''s effective cost value for this event. The affiliate''s Commission may be a percentage of this eCost value based on their agreement. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost_Commissions)';

