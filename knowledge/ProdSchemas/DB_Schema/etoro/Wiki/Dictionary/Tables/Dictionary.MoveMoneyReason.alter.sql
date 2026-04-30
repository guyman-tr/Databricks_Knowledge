-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.MoveMoneyReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MoveMoneyReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_movemoneyreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_movemoneyreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_movemoneyreason SET TBLPROPERTIES (
    'comment' = 'Classifies the business reasons for internal money movements (balance adjustments, transfers, staking, bonuses) recorded in the ActiveCredit ledger system. Source: etoro.Dictionary.MoveMoneyReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.MoveMoneyReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_movemoneyreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'MoveMoneyReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_movemoneyreason ALTER COLUMN MoveMoneyReasonID COMMENT 'Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures. (Tier 1 - upstream wiki, etoro.Dictionary.MoveMoneyReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_movemoneyreason ALTER COLUMN MoveMoneyReason COMMENT 'Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens. (Tier 1 - upstream wiki, etoro.Dictionary.MoveMoneyReason)';

