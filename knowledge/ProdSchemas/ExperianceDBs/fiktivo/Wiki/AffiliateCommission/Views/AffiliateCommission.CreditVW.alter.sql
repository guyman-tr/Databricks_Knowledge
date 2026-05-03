-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.AffiliateCommission.CreditVW
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_affiliatecommission_credit
--   main.bi_db.bronze_fiktivo_affiliatecommission_creditvw
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_credit (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit SET TBLPROPERTIES (
    'comment' = 'View combining credit (deposit/chargeback) financial data with affiliate attribution from RegistrationMetaData, providing a unified record for commission reporting. Source: fiktivo.AffiliateCommission.CreditVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'CreditVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN CreditID COMMENT 'From Credit. Credit event identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN CreditDate COMMENT 'From Credit. Event timestamp. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN CID COMMENT 'From RegistrationMetaData. Customer ID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN AffiliateCampaign COMMENT 'From RegistrationMetaData. Campaign tracking. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN CreditTypeID COMMENT 'From Credit. 1=Deposit, 4/5=Chargeback. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN AdditionalData COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN AffiliateID COMMENT 'From RegistrationMetaData. Referring affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN Amount COMMENT 'From Credit. Credit amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN BannerID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN IsFirstDeposit COMMENT 'From Credit. FTD flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN DownloadID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN ProviderID COMMENT 'From Credit. Provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN OriginalProviderID COMMENT 'From Credit. Original provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN RealProviderID COMMENT 'From Credit. Execution entity. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN CountryID COMMENT 'From Credit. Customer country. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN FunnelID COMMENT 'From RegistrationMetaData. Marketing funnel. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN LabelID COMMENT 'Always NULL. Backward compatibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN PlayerLevelID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN Valid COMMENT 'From Credit. Commission eligibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN OriginalCID COMMENT 'From RegistrationMetaData. Original customer. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN TrackingDate COMMENT 'From Credit. Tracking entry time. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN IsProcessed COMMENT 'From Credit. Processing flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN ValidFrom COMMENT 'From RegistrationMetaData. Attribution effective date. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(CreditDate, ValidFrom). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN CommissionSource COMMENT 'From Credit. Commission calculation source. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_credit ALTER COLUMN ProductID COMMENT 'From Credit. Product identifier (ISA MoneyFarm). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_affiliatecommission_creditvw (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw SET TBLPROPERTIES (
    'comment' = 'View combining credit (deposit/chargeback) financial data with affiliate attribution from RegistrationMetaData, providing a unified record for commission reporting. Source: fiktivo.AffiliateCommission.CreditVW on the fiktivo production database, ingested via the Generic Pipeline (Merge strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'AffiliateCommission',
    'source_table' = 'CreditVW',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Merge',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN CreditID COMMENT 'From Credit. Credit event identifier. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN CreditDate COMMENT 'From Credit. Event timestamp. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN CID COMMENT 'From RegistrationMetaData. Customer ID. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN AffiliateCampaign COMMENT 'From RegistrationMetaData. Campaign tracking. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN CreditTypeID COMMENT 'From Credit. 1=Deposit, 4/5=Chargeback. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN AdditionalData COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN AffiliateID COMMENT 'From RegistrationMetaData. Referring affiliate. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN Amount COMMENT 'From Credit. Credit amount. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN BannerID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN IsFirstDeposit COMMENT 'From Credit. FTD flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN DownloadID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN ProviderID COMMENT 'From Credit. Provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN OriginalProviderID COMMENT 'From Credit. Original provider. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN RealProviderID COMMENT 'From Credit. Execution entity. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN CountryID COMMENT 'From Credit. Customer country. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN FunnelID COMMENT 'From RegistrationMetaData. Marketing funnel. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN LabelID COMMENT 'Always NULL. Backward compatibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN PlayerLevelID COMMENT 'From RegistrationMetaData. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN Valid COMMENT 'From Credit. Commission eligibility. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN OriginalCID COMMENT 'From RegistrationMetaData. Original customer. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN TrackingDate COMMENT 'From Credit. Tracking entry time. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN IsProcessed COMMENT 'From Credit. Processing flag. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN ValidFrom COMMENT 'From RegistrationMetaData. Attribution effective date. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN UpdateDate COMMENT 'Computed: GREATEST(CreditDate, ValidFrom). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN CommissionSource COMMENT 'From Credit. Commission calculation source. (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
ALTER TABLE main.bi_db.bronze_fiktivo_affiliatecommission_creditvw ALTER COLUMN ProductID COMMENT 'From Credit. Product identifier (ISA MoneyFarm). (Tier 1 - upstream wiki, fiktivo.AffiliateCommission.CreditVW)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
