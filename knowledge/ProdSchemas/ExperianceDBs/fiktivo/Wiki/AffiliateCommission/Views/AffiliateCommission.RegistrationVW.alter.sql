-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.RegistrationVW
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_affiliatecommission_registration
--   main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_registration (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration SET TBLPROPERTIES (
    'comment' = 'View combining Registration event data with affiliate attribution from RegistrationMetaData, providing unified registration records for commission reporting with dual-path UNION ALL for current and legacy registrations. Source: fiktivo.AffiliateCommission.RegistrationVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'RegistrationVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN RegistrationID COMMENT 'From Registration. Registration identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN CID COMMENT 'From RegistrationMetaData. Customer ID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN OriginalCID COMMENT 'From RegistrationMetaData. Original customer. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN AffiliateID COMMENT 'From RegistrationMetaData. Referring affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN AffiliateCampaign COMMENT 'From RegistrationMetaData. Campaign. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN AdditionalData COMMENT 'From RegistrationMetaData. Extensible metadata. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN RegistrationDate COMMENT 'From Registration. Registration timestamp. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN DownloadID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN BannerID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN CountryID COMMENT 'From Registration. Customer country. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN ProviderID COMMENT 'From Registration. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN OriginalProviderID COMMENT 'From Registration. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN RealProviderID COMMENT 'From Registration. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN FunnelID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN LabelID COMMENT 'Always NULL. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN PlayerLevelID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN TrackingDate COMMENT 'From Registration. Tracking entry. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN Valid COMMENT 'From Registration. Eligibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN IsProcessed COMMENT 'From Registration. Processing flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN ValidFrom COMMENT 'From RegistrationMetaData. Attribution effective. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registration ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(RegistrationDate, ValidFrom). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw SET TBLPROPERTIES (
    'comment' = 'View combining Registration event data with affiliate attribution from RegistrationMetaData, providing unified registration records for commission reporting with dual-path UNION ALL for current and legacy registrations. Source: fiktivo.AffiliateCommission.RegistrationVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'RegistrationVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN RegistrationID COMMENT 'From Registration. Registration identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN CID COMMENT 'From RegistrationMetaData. Customer ID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN OriginalCID COMMENT 'From RegistrationMetaData. Original customer. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN AffiliateID COMMENT 'From RegistrationMetaData. Referring affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN AffiliateCampaign COMMENT 'From RegistrationMetaData. Campaign. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN AdditionalData COMMENT 'From RegistrationMetaData. Extensible metadata. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN RegistrationDate COMMENT 'From Registration. Registration timestamp. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN DownloadID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN BannerID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN CountryID COMMENT 'From Registration. Customer country. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN ProviderID COMMENT 'From Registration. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN OriginalProviderID COMMENT 'From Registration. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN RealProviderID COMMENT 'From Registration. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN FunnelID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN LabelID COMMENT 'Always NULL. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN PlayerLevelID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN TrackingDate COMMENT 'From Registration. Tracking entry. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN Valid COMMENT 'From Registration. Eligibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN IsProcessed COMMENT 'From Registration. Processing flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN ValidFrom COMMENT 'From RegistrationMetaData. Attribution effective. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(RegistrationDate, ValidFrom). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationVW)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
