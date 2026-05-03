-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CashoutReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cashoutreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cashoutreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 19 reasons for initiating a cashout (withdrawal) - from user-requested withdrawals and PI payments to risk refunds, account closures, and crypto transfers. Source: etoro.Dictionary.CashoutReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cashoutreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CashoutReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutreason ALTER COLUMN CashoutReasonID COMMENT 'Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutreason ALTER COLUMN Name COMMENT 'Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
