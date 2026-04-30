-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CashoutType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutType.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cashouttype
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cashouttype (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cashouttype SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 3 cashout (withdrawal) classifications — NewMoneyCashout, CashoutRefund, and RiskRefund — determining whether a withdrawal is a standard payout, a deposit refund, or a risk-driven return. Source: etoro.Dictionary.CashoutType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutType.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cashouttype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CashoutType',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cashouttype ALTER COLUMN CashoutTypeID COMMENT 'Primary key identifying the withdrawal classification. 1=NewMoneyCashout (standard), 2=CashoutRefund (deposit reversal), 3=RiskRefund (compliance return). Stored in Billing.WithdrawToFunding and History.WithdrawToFundingAction. Drives CASE branching in 15+ BackOffice/Billing procedures. Types 2 and 3 are often grouped as refund types. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutType)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashouttype ALTER COLUMN CashoutTypeName COMMENT 'Human-readable type label. Nullable. Note: column named CashoutTypeName (not Name) — matches table naming convention. Joined in BackOffice reports and payout processing for display. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutType)';

