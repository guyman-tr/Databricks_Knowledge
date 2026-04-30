-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_FirstPositions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions SET TBLPROPERTIES (
    'comment' = 'Tracks first trading position events - when affiliate-referred customers open their very first trade, a key conversion milestone for affiliate attribution. Source: fiktivo.dbo.tblaff_FirstPositions on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_FirstPositions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN FirstPositionID COMMENT 'Primary key. Unique identifier for each first position event. NOT FOR REPLICATION. Referenced by tblaff_FirstPositions_Commissions via explicit FK. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN ORDER_DATE COMMENT 'Timestamp when the first position was opened. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN GRAND_TOTAL COMMENT 'Monetary value/size of the first trade. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN AffiliateFirstPositionAccepted COMMENT 'Attribution flag. 1=accepted for commission, 0=not attributed. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN Valid COMMENT 'Validation flag. 1=valid, 0=rejected. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN BannerID COMMENT 'Marketing banner. References dbo.tblaff_Banners [done]. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN DaysToConvert COMMENT 'Days between affiliate click and first position. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN Optional1 COMMENT 'Sub-affiliate tracking parameter. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN Optional2 COMMENT 'Secondary tracking parameter. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN OriginalCID COMMENT 'Original customer ID. Clustered index column - primary lookup pattern for deduplication. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN DownloadID COMMENT 'App download event ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN ProviderID COMMENT 'Currently attributed affiliate provider. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN OriginalProviderID COMMENT 'First affiliate that acquired this customer. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN CountryID COMMENT 'Customer''s country. References dbo.tblaff_Country [done]. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN RealProviderID COMMENT 'Leaf-level provider after IB hierarchy resolution. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN FunnelID COMMENT 'Marketing funnel identifier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN LabelID COMMENT 'Marketing label/campaign identifier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions ALTER COLUMN PlayerLevelID COMMENT 'Customer tier at event time. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_FirstPositions)';

