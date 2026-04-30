-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RedeemApprovalReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemApprovalReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_redeemapprovalreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_redeemapprovalreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_redeemapprovalreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining CopyTrading redeem manual approval reasons — currently only 1 value ("Other") — used by BackOffice.RedeemApproval for manual redeem review justifications. Source: etoro.Dictionary.RedeemApprovalReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemApprovalReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_redeemapprovalreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RedeemApprovalReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_redeemapprovalreason ALTER COLUMN RedeemApprovalReasonID COMMENT 'Primary key. Currently only value 1. Referenced by BackOffice.RedeemApproval. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemApprovalReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemapprovalreason ALTER COLUMN Name COMMENT 'Human-readable reason label. Displayed in BackOffice redeem approval screens. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemApprovalReason)';

