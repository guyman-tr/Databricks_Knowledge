-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_FirstPositions_Commissions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions_Commissions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions SET TBLPROPERTIES (
    'comment' = 'Stores tier-based affiliate commission records from first-position events, with an explicit FK to tblaff_FirstPositions ensuring referential integrity. Source: fiktivo.dbo.tblaff_FirstPositions_Commissions on the fiktivo production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions_Commissions.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_FirstPositions_Commissions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN ID COMMENT 'Auto-incrementing primary key. NOT FOR REPLICATION. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN FirstPositionID COMMENT 'References tblaff_FirstPositions.FirstPositionID via explicit FK (FK__FirstPosition_FirstPositionID). The customer''s first trading position event. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN AffiliateID COMMENT 'The affiliate receiving this commission. Maps to tblaff_Affiliates. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN Commission COMMENT 'Commission amount for this tier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN Tier COMMENT 'Commission tier level: 1-5. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN Paid COMMENT 'Payment status: 0 = unpaid, 1 = paid. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN PaymentID COMMENT 'References tblaff_PaymentHistory.PaymentID when paid. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions ALTER COLUMN SubAffiliateID COMMENT 'Sub-affiliate tracking tag. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions_Commissions)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
