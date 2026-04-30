-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.RegistrationMetaData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.RegistrationMetaData.md
-- Layer: bronze
-- UC Target: main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata
-- =============================================================================

-- ---- UC Target: main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata (business_group=experience) ----
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata SET TBLPROPERTIES (
    'comment' = 'Temporal table storing full affiliate attribution context for each registered customer, with system versioning to track changes over time as re-attribution events occur. Source: fiktivo.AffiliateCommission.RegistrationMetaData on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Tables/AffiliateCommission.RegistrationMetaData.md).'
);

ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'RegistrationMetaData',
    'business_group' = 'experience',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN CID COMMENT 'Customer ID. First column of composite PK. One row per customer. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN PartitionCol COMMENT 'Computed partition column. Formula: CID modulo 50. Distributes data across 50 partitions on PS_Mod50. Second column of composite PK. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN GCID COMMENT 'Global Customer ID. Cross-provider customer identifier. Unique index on (GCID, CID, PartitionCol) ensures 1:1 mapping. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN AffiliateID COMMENT 'The affiliate attributed with this customer''s registration. Can change via re-attribution (tracked by system versioning). Indexed for affiliate-based lookups. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN AffiliateCampaign COMMENT 'Campaign tracking string from the affiliate link. May contain encoded tracking parameters. Empty string when no campaign context was captured. NOT NULL (uses empty string instead of NULL). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN BannerID COMMENT 'Banner that led to the registration. 0 = no banner tracked. References the banner/creative system. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN DownloadID COMMENT 'Download/app install tracking ID. 0 = no download tracked. Links to app installation events. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN CountryID COMMENT 'Customer''s registration country. May differ from country in Registration table if attribution changes include country correction. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN FunnelID COMMENT 'Marketing funnel identifier. NULL when funnel tracking is not applicable or not configured for the affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN PlayerLevelID COMMENT 'Player level classification at registration time. 1 = standard new player. May be updated as player progresses. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN OriginalCID COMMENT 'Original customer in sub-account/copy-trade scenarios. For standard registrations, equals CID or another reference. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN Trace COMMENT 'Computed execution context. NOT PERSISTED. Captures hostname, app name, SQL user, SPID, database name, and calling procedure name. Provides forensic trail for attribution changes. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN ValidFrom COMMENT 'System versioning start time. When this version of the row became effective. Automatically set by SQL Server temporal tables. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN ValidTo COMMENT 'System versioning end time. When this version was superseded. 9999-12-31 for the current row. History rows have the actual end time. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN AdditionalData COMMENT 'Extensible metadata field. Defaults to empty string. Allows additional attribution data without schema changes. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';
ALTER TABLE main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata ALTER COLUMN EtoroUserName COMMENT 'eToro username of the registered customer. Allows quick human-readable identification alongside the numeric CID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.RegistrationMetaData)';

