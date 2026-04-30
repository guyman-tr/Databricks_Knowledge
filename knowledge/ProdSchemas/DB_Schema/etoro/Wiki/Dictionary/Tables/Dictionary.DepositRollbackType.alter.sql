-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DepositRollbackType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositRollbackType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_depositrollbacktype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_depositrollbacktype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the types of deposit reversal operations — chargebacks, refunds, reversals, and adjustment corrections that reduce or reverse a customer''s deposited funds. Source: etoro.Dictionary.DepositRollbackType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositRollbackType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DepositRollbackType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktype ALTER COLUMN DepositRollbackTypeID COMMENT 'Primary key identifying the rollback type. 0=Chargeback, 1=Refund, 2=Refund as Chargeback, 3=Chargeback Reversal, 4=Refund Reversal, 5=Cancel Rollback, 6=Reverse Deposit, 7=Pooled deposit adjustment, 8=Failed deposit deduction, 9=Returned or Reversed Deposit, 10=Adjust Discrepancy. Referenced by BackOffice.DepositRollbackTypeToReason mapping table. (Tier 1 - upstream wiki, etoro.Dictionary.DepositRollbackType)';
ALTER TABLE main.general.bronze_etoro_dictionary_depositrollbacktype ALTER COLUMN Name COMMENT 'Human-readable rollback type label used in BackOffice UI, SSRS risk reports, and financial reconciliation. (Tier 1 - upstream wiki, etoro.Dictionary.DepositRollbackType)';

