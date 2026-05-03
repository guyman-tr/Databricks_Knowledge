-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.DepositStatusReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositStatusReason.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_dictionary_depositstatusreason
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_dictionary_depositstatusreason (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositstatusreason SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the sub-reason states within the deposit approval process - distinguishing between pre-approval, final approval, final decline, and no-reason states. Source: etoro.Dictionary.DepositStatusReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DepositStatusReason.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositstatusreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'DepositStatusReason',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositstatusreason ALTER COLUMN ID COMMENT 'Primary key (auto-increment). 0=None, 1=PreApproved, 2=FinalApproved, 3=FinalDecline. Referenced by Billing.Deposit.StatusReasonID. Note: despite being IDENTITY, values 0-3 were explicitly seeded. (Tier 1 - upstream wiki, etoro.Dictionary.DepositStatusReason)';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_depositstatusreason ALTER COLUMN StatusReason COMMENT 'Human-readable approval stage label. Used by Billing.UpdateDepositStatusReasonID procedure and BackOffice reporting. (Tier 1 - upstream wiki, etoro.Dictionary.DepositStatusReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
