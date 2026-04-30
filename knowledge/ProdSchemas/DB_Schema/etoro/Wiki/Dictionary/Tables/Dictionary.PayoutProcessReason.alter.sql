-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.PayoutProcessReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PayoutProcessReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_payoutprocessreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_payoutprocessreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_payoutprocessreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 10 reasons why a payout (withdrawal) processing operation reached its current state — from success (None) through technical, validation, provider, and communication errors. Source: etoro.Dictionary.PayoutProcessReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PayoutProcessReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_payoutprocessreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'PayoutProcessReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_payoutprocessreason ALTER COLUMN PayoutProcessReasonID COMMENT 'Primary key identifying the payout process reason. 0=None (success), 1=Technical, 2=Validation, 3=UnsupportedProvider, 4=Communication, 5=NoRecordsFound, 6=ProviderError, 7=FundingError, 8=DepositNotFound, 9=IncorrectStatus. Stored in Billing.PayoutProcess. (Tier 1 - upstream wiki, etoro.Dictionary.PayoutProcessReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_payoutprocessreason ALTER COLUMN Name COMMENT 'Human-readable label for the reason. Used in payout status reports and billing operations dashboards. (Tier 1 - upstream wiki, etoro.Dictionary.PayoutProcessReason)';

