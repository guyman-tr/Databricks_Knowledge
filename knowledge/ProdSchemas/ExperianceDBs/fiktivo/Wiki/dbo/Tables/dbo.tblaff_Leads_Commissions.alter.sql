-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_Leads_Commissions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions SET TBLPROPERTIES (
    'comment' = 'Stores tier-based affiliate commission records from lead generation events, with trigger-enforced RI and an additional eCost field for effective cost tracking. Source: fiktivo.dbo.tblaff_Leads_Commissions on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_Leads_Commissions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN ID COMMENT 'Auto-incrementing primary key. NOT FOR REPLICATION. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN LeadID COMMENT 'References tblaff_Leads.LeadID. Trigger enforces RI. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN AffiliateID COMMENT 'The affiliate receiving this commission. Trigger enforces RI against tblaff_Affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN Commission COMMENT 'Lead commission amount for this tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN Tier COMMENT 'Commission tier level: 1-5. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN Paid COMMENT 'Payment status: 0 = unpaid, 1 = paid. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN PaymentID COMMENT 'References tblaff_PaymentHistory.PaymentID when paid. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN SubAffiliateID COMMENT 'Sub-affiliate tracking tag. Updatable by UpdateSubAffiliateID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions ALTER COLUMN eCost COMMENT 'Effective cost to the platform for this lead event. Enables ROI calculation: Commission/eCost. NULL when eCost tracking is not configured. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads_Commissions)';

