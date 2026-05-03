-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.ClientWithdrawReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClientWithdrawReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_clientwithdrawreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_clientwithdrawreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_clientwithdrawreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining customer-facing reasons for requesting a withdrawal. Displayed in the withdrawal form UI and used for analytics and churn understanding. Source: etoro.Dictionary.ClientWithdrawReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClientWithdrawReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_clientwithdrawreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'ClientWithdrawReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_clientwithdrawreason ALTER COLUMN ClientWithdrawReasonID COMMENT 'Primary key. Values 1 - 7. Referenced by Billing.Withdraw via FK. Passed as @ClientWithdrawReasonID to WithdrawalService_WithdrawRequestAdd, WithdrawRequestAdd, UpsertWithdraw. (Tier 1 - upstream wiki, etoro.Dictionary.ClientWithdrawReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_clientwithdrawreason ALTER COLUMN Name COMMENT 'Human-readable reason label displayed in the withdrawal form. E.g., "Withdrawing profits", "Moving to a competitor". NULL allowed. (Tier 1 - upstream wiki, etoro.Dictionary.ClientWithdrawReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_clientwithdrawreason ALTER COLUMN IsActive COMMENT 'Controls visibility in UI. 1 = shown in WithdrawalService_GetClientWitdrawReasons; 0 = hidden for new requests. (Tier 1 - upstream wiki, etoro.Dictionary.ClientWithdrawReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_clientwithdrawreason ALTER COLUMN DisplayOrder COMMENT 'Sort order for UI display. Lower values first. Used in ORDER BY when fetching active reasons. (Tier 1 - upstream wiki, etoro.Dictionary.ClientWithdrawReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
