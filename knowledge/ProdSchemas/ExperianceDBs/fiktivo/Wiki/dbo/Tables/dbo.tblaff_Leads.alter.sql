-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_Leads
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_leads
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_leads (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads SET TBLPROPERTIES (
    'comment' = 'Tracks lead generation events - when potential customers referred by affiliates show initial interest (e.g., form submissions, demo account creation) before converting to a registered user. Source: fiktivo.dbo.tblaff_Leads on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Leads.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_Leads',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN LeadID COMMENT 'Primary key. Unique identifier for each lead event. NOT FOR REPLICATION. Referenced by tblaff_Leads_Commissions.LeadID via trigger-enforced FK. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN CUSTOMER_ID COMMENT 'Customer identifier from the trading platform. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN ORDER_DATE COMMENT 'Timestamp when the lead was generated. Clustered index column. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN AffiliateSaleAccepted COMMENT 'Attribution flag (legacy name from shared codebase). 1=lead attributed to an affiliate, 0=not attributed. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN IPAddress COMMENT 'Customer''s IP address. Fraud detection and geo-verification. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN Browser COMMENT 'Customer''s user agent string. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN Valid COMMENT 'Validation flag. 1=qualified lead, 0=rejected. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN Reason COMMENT 'Rejection reason when Valid=0. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN BannerID COMMENT 'Marketing banner. References dbo.tblaff_Banners [done]. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN DaysToConvert COMMENT 'Days between affiliate click and lead generation. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN Optional1 COMMENT 'Sub-affiliate tracking parameter. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN Optional2 COMMENT 'Secondary tracking parameter. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN Optional3 COMMENT 'Original CID or extended tracking ID. Has NC index. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN Real COMMENT 'Whether the lead is from a real (funded) or demo account. 1=real, NULL/0=demo or unknown. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN DownloadID COMMENT 'App download event ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN ProviderID COMMENT 'Currently attributed affiliate provider. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN OriginalProviderID COMMENT 'First affiliate that acquired this customer. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN CountryID COMMENT 'Customer''s country. References dbo.tblaff_Country [done]. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN DID COMMENT 'Download tracking ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN FID COMMENT 'Funnel tracking ID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN RealProviderID COMMENT 'Leaf-level provider after IB hierarchy resolution. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN FunnelID COMMENT 'Marketing funnel identifier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN LabelID COMMENT 'Marketing label/campaign identifier. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN PlayerLevelID COMMENT 'Customer tier at event time. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_leads ALTER COLUMN ClubID COMMENT 'Customer club membership. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_Leads)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
