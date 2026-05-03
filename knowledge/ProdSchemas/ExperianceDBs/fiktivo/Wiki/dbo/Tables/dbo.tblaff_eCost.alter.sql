-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_eCost
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_ecost (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost SET TBLPROPERTIES (
    'comment' = 'Tracks individual marketing expense (eCost) events attributed to the affiliate program, recording granular expense line items linked to eCostHistory agreements. Source: fiktivo.dbo.tblaff_eCost on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_eCost.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_eCost',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN eCostID COMMENT 'Primary key. Unique identifier for each eCost event. NOT FOR REPLICATION. Referenced by tblaff_eCost_Commissions.eCostID via trigger-enforced FK. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN CUSTOMER_ID COMMENT 'Customer identifier from the trading platform. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN ORDER_DATE COMMENT 'Timestamp of the eCost event. Clustered index column. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN AffiliateeCostAccepted COMMENT 'Attribution flag. 1=accepted for commission, 0=not attributed. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN IPAddress COMMENT 'Customer''s IP address. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Browser COMMENT 'Customer''s user agent. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Valid COMMENT 'Validation flag. 1=valid for commission, 0=rejected. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Reason COMMENT 'Rejection reason when Valid=0. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN BannerID COMMENT 'Marketing banner. References dbo.tblaff_Banners [done]. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN DaysToConvert COMMENT 'Days between affiliate click and this event. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Optional1 COMMENT 'Sub-affiliate tracking parameter. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Optional2 COMMENT 'Secondary tracking parameter. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Optional3 COMMENT 'Original CID or extended tracking ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Real COMMENT 'Whether from a real (funded) or demo account. 1=real, NULL/0=demo. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN DownloadID COMMENT 'App download event ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN ProviderID COMMENT 'Currently attributed affiliate provider. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN OriginalProviderID COMMENT 'First affiliate that acquired this customer. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN CountryID COMMENT 'Customer''s country. References dbo.tblaff_Country [done]. Nullable unlike other event tables. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN DID COMMENT 'Download tracking ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN FID COMMENT 'Funnel tracking ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN RealProviderID COMMENT 'Leaf-level provider after IB hierarchy resolution. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN Comment COMMENT 'Free-text comment about this specific expense event. Used for line-item annotations. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN eCostHistoryID COMMENT 'Parent eCost agreement. References dbo.tblaff_eCostHistory.eCostHistoryID. 0=no agreement linkage (ad-hoc). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN FunnelID COMMENT 'Marketing funnel identifier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_ecost ALTER COLUMN LabelID COMMENT 'Marketing label/campaign identifier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_eCost)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
