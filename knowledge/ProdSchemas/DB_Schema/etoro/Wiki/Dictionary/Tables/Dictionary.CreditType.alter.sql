-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CreditType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_credittype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_credittype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_credittype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 33 types of balance-affecting operations that create credit/debit entries in a customer''s financial history. Source: etoro.Dictionary.CreditType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CreditType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_credittype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CreditType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_credittype ALTER COLUMN CreditTypeID COMMENT 'Financial operation type identifier (1-33). Classifies every balance change: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse Cashout, 9=Cashout Request, 10=IB Sync, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18-28=Mirror/CopyTrading operations, 29-30=Stock Orders, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. (Tier 1 - upstream wiki, etoro.Dictionary.CreditType)';
ALTER TABLE main.general.bronze_etoro_dictionary_credittype ALTER COLUMN Name COMMENT 'Human-readable operation name. Unique constraint ensures no duplicate names. Used in financial reports, transaction history, and reconciliation tools. Note: char(50) with trailing spaces — always RTRIM when displaying. (Tier 1 - upstream wiki, etoro.Dictionary.CreditType)';

