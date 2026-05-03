-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.AffiliateStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AffiliateStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_affiliatestatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_affiliatestatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_affiliatestatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 6 affiliate partner quality tiers - Normal, Good, Bad, Untouchable, Excellent, and Platinum - used to classify introducing broker (affiliate) performance and trustworthiness. Source: etoro.Dictionary.AffiliateStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AffiliateStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_affiliatestatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'AffiliateStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_affiliatestatus ALTER COLUMN AffiliateStatusID COMMENT 'Primary key identifying the affiliate quality tier. 1=Normal, 2=Good, 3=Bad, 4=Untouchable, 5=Excellent, 6=Platinum. Stored in BackOffice.Affiliate.AffiliateStatusID. Set by BackOffice.AffiliateEdit, read during Customer.RegisterReal and Customer.PostRegisterOperations. (Tier 1 - upstream wiki, etoro.Dictionary.AffiliateStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_affiliatestatus ALTER COLUMN Name COMMENT 'Human-readable tier name. Unique index enforced (DAFS_NAME). Displayed in BackOffice affiliate management screens and registration reports (BackOffice.GetRegistrationReport). (Tier 1 - upstream wiki, etoro.Dictionary.AffiliateStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
