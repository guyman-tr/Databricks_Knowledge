-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CashoutActionStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutActionStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cashoutactionstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cashoutactionstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutactionstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 states of cashout (withdrawal) actions — New, Processed, and Failed — tracking each step in the withdrawal processing pipeline. Source: etoro.Dictionary.CashoutActionStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutActionStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cashoutactionstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CashoutActionStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutactionstatus ALTER COLUMN CashoutActionStatusID COMMENT 'Primary key identifying the action lifecycle state. 1=New (created, pending), 2=Processed (success), 3=Failed (error). Referenced by History.CashoutAction (explicit FK) and History.WithdrawToFundingAction (implicit). Written by all cashout processing procedures in legacy (CashoutProcess) and modern (WithdrawToFunding) flows. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutActionStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutactionstatus ALTER COLUMN Name COMMENT 'Human-readable status name. Unique constraint prevents duplicates. Values: ''New'', ''Processed'', ''Failed''. Used in withdrawal monitoring, BackOffice reports, and debugging. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutActionStatus)';

