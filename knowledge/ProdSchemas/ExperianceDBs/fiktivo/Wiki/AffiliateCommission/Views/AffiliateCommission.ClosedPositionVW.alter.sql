-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.ClosedPositionVW
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_affiliatecommission_closedposition
--   main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_closedposition (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition SET TBLPROPERTIES (
    'comment' = 'View combining closed position financial data with affiliate attribution from RegistrationMetaData, providing a unified record for commission reporting that includes both position details and the referring affiliate context. Source: fiktivo.AffiliateCommission.ClosedPositionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'ClosedPositionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN ClosedPositionID COMMENT 'From ClosedPosition. Unique position identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN CommissionDate COMMENT 'From ClosedPosition. When commission was calculated. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN Amount COMMENT 'From ClosedPosition. Gross commission-eligible amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN HedgeCommission COMMENT 'From ClosedPosition. Hedge commission component. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN CID COMMENT 'From RegistrationMetaData. Customer ID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN OriginalCID COMMENT 'From RegistrationMetaData. Original customer in copy-trading. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN AffiliateID COMMENT 'From RegistrationMetaData. Referring affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN AffiliateCampaign COMMENT 'From RegistrationMetaData. Campaign tracking string. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN ProviderID COMMENT 'From ClosedPosition. Current provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN OriginalProviderID COMMENT 'From ClosedPosition. Original provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN AdditionalData COMMENT 'From RegistrationMetaData. Extensible metadata. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN RealProviderID COMMENT 'From ClosedPosition. Execution entity. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN CountryID COMMENT 'From ClosedPosition. Customer country. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN NetProfit COMMENT 'From ClosedPosition. Position profit/loss. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN FunnelID COMMENT 'From RegistrationMetaData. Marketing funnel. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN LabelID COMMENT 'Always NULL. Column preserved for backward compatibility with legacy consumers. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN PlayerLevelID COMMENT 'From RegistrationMetaData. Player level classification. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN DownloadID COMMENT 'From RegistrationMetaData. Download tracking. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN LotCount COMMENT 'From ClosedPosition. Position size in lots. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN BannerID COMMENT 'From RegistrationMetaData. Banner reference. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN Valid COMMENT 'From ClosedPosition. Commission eligibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN TrackingDate COMMENT 'From ClosedPosition. Tracking system entry time. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN IsProcessed COMMENT 'From ClosedPosition. Processing completion flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN ValidFrom COMMENT 'From RegistrationMetaData. When current attribution became effective. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedposition ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(CommissionDate, ValidFrom). Latest change timestamp for CDC consumers. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw SET TBLPROPERTIES (
    'comment' = 'View combining closed position financial data with affiliate attribution from RegistrationMetaData, providing a unified record for commission reporting that includes both position details and the referring affiliate context. Source: fiktivo.AffiliateCommission.ClosedPositionVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'ClosedPositionVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN ClosedPositionID COMMENT 'From ClosedPosition. Unique position identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN CommissionDate COMMENT 'From ClosedPosition. When commission was calculated. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN Amount COMMENT 'From ClosedPosition. Gross commission-eligible amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN HedgeCommission COMMENT 'From ClosedPosition. Hedge commission component. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN CID COMMENT 'From RegistrationMetaData. Customer ID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN OriginalCID COMMENT 'From RegistrationMetaData. Original customer in copy-trading. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN AffiliateID COMMENT 'From RegistrationMetaData. Referring affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN AffiliateCampaign COMMENT 'From RegistrationMetaData. Campaign tracking string. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN ProviderID COMMENT 'From ClosedPosition. Current provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN OriginalProviderID COMMENT 'From ClosedPosition. Original provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN AdditionalData COMMENT 'From RegistrationMetaData. Extensible metadata. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN RealProviderID COMMENT 'From ClosedPosition. Execution entity. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN CountryID COMMENT 'From ClosedPosition. Customer country. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN NetProfit COMMENT 'From ClosedPosition. Position profit/loss. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN FunnelID COMMENT 'From RegistrationMetaData. Marketing funnel. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN LabelID COMMENT 'Always NULL. Column preserved for backward compatibility with legacy consumers. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN PlayerLevelID COMMENT 'From RegistrationMetaData. Player level classification. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN DownloadID COMMENT 'From RegistrationMetaData. Download tracking. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN LotCount COMMENT 'From ClosedPosition. Position size in lots. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN BannerID COMMENT 'From RegistrationMetaData. Banner reference. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN Valid COMMENT 'From ClosedPosition. Commission eligibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN TrackingDate COMMENT 'From ClosedPosition. Tracking system entry time. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN IsProcessed COMMENT 'From ClosedPosition. Processing completion flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN ValidFrom COMMENT 'From RegistrationMetaData. When current attribution became effective. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(CommissionDate, ValidFrom). Latest change timestamp for CDC consumers. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.ClosedPositionVW)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
