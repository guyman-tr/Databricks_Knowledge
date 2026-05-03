-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CashoutFeeGroup
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutFeeGroup.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cashoutfeegroup
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cashoutfeegroup (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutfeegroup SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 withdrawal fee groups - Default, Exempt, and Discount - controlling which fee schedule applies to a customer''s cashout transactions. Source: etoro.Dictionary.CashoutFeeGroup on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutFeeGroup.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cashoutfeegroup SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CashoutFeeGroup',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutfeegroup ALTER COLUMN CashoutFeeGroupID COMMENT 'Primary key identifying the fee group. 1=Default, 2=Exempt, 3=Discount. Stored in BackOffice.Customer (FK), Trade.CashoutRange (FK). Mapped from PlayerLevel via Billing.PlayerLevelToCashoutFeeGroup and from GuruStatus via Billing.GuruStatusToCashoutFeeGroup. Auto-updated by Billing.ProcessCashoutFeeGroupUpdate when tier changes. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutFeeGroup)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutfeegroup ALTER COLUMN Name COMMENT 'Human-readable fee group name. Nullable. Joined in Billing.WithdrawalService_GetCustomerFeeGroups for display. Values: ''Default'', ''Exempt'', ''Discount''. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutFeeGroup)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
