-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CashoutRejectReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutRejectReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cashoutrejectreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cashoutrejectreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutrejectreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 28 reasons for rejecting a cashout (withdrawal) request — from missing documents and wrong payment details to risk flags, bonus abuse, and unclaimed payments. Source: etoro.Dictionary.CashoutRejectReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutRejectReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cashoutrejectreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CashoutRejectReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutrejectreason ALTER COLUMN RejectReasonID COMMENT 'Primary key identifying the rejection reason. Range 0-27. Referenced by Billing.WithdrawRejects (explicit FK). Written by Billing.WithdrawReject procedure. TINYINT type limits to 256 possible values. Note: column named RejectReasonID (not CashoutRejectReasonID) — differs from naming pattern of parent table name. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutRejectReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutrejectreason ALTER COLUMN RejectReasonName COMMENT 'Human-readable rejection description. Nullable. Longer varchar(200) allows detailed descriptions (vs typical 50). Joined in rejection reports as display label. Some values are customer-facing when IsInDisplay=1. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutRejectReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutrejectreason ALTER COLUMN IsInDisplay COMMENT 'Whether this reason is displayed in customer-facing interfaces. 1=visible to customers, NULL=internal-only. Only 7 of 28 reasons are customer-visible (IDs 11, 15, 19, 23, 24, 26, 27). Controls which reasons appear in self-service withdrawal status screens. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutRejectReason)';

