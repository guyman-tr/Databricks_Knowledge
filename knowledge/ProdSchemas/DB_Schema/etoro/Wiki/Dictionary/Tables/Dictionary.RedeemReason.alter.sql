-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.RedeemReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_redeemreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_redeemreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_redeemreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 18 reasons for redeem (copy-fund exit) failures and rejections — from trade/funding blocks and verification issues to server errors, cancellations, and data integrity failures. Source: etoro.Dictionary.RedeemReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.RedeemReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_redeemreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'RedeemReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_redeemreason ALTER COLUMN RedeemReasonID COMMENT 'Primary key identifying the failure/rejection reason. Range 1-20 (gaps at 17, 19). Referenced by Billing.Redeem (explicit FK), Trade.OrdersExitTbl. Used as parameter in Billing.RedeemStatusUpdate, Trade.PositionClose, Trade.OrderExitOpen. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemreason ALTER COLUMN Name COMMENT 'Internal reason code name. Not nullable. Prefix convention: "Rre" = Redeem Rejection, "ServerError" = service failure, "Failed" = processing failure. Used in procedure logic and debugging. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemreason ALTER COLUMN Description COMMENT 'Extended description of the reason. Currently NULL for all rows — available for future enrichment. PAGE compressed. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_redeemreason ALTER COLUMN DisplayName COMMENT 'Customer/UI-facing display name. Currently matches Name for all rows. Used by dbo.SSRS_REDEEM_REPORT for report output. (Tier 1 - upstream wiki, etoro.Dictionary.RedeemReason)';

