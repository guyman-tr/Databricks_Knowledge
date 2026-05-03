-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.WithdrawApprovalReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawApprovalReason.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_withdrawapprovalreason
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_withdrawapprovalreason (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_withdrawapprovalreason SET TBLPROPERTIES (
    'comment' = 'Hierarchical lookup table defining the reasons why a withdrawal request is held for manual approval - from "Awaiting Documents" to "Bonus Abusing" - with parent-child categorization and optional email template linkage for automated customer notifications. Source: etoro.Dictionary.WithdrawApprovalReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawApprovalReason.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_withdrawapprovalreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'WithdrawApprovalReason',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_withdrawapprovalreason ALTER COLUMN WithdrawApprovalReasonID COMMENT 'Unique identifier for the approval hold reason. IDs 1-7 are top-level categories; IDs 8-16 are sub-reasons. Referenced by 10+ withdrawal approval procedures for recording, filtering, and reporting hold reasons. (Tier 1 - upstream wiki, etoro.Dictionary.WithdrawApprovalReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_withdrawapprovalreason ALTER COLUMN Name COMMENT 'Display name of the hold reason (e.g., "Awaiting Documents", "CC Docs", "Bonus Abusing"). Shown in BackOffice approval UI. Unique within each parent category (enforced by DWAR_NAME unique index on Name+ParentID). (Tier 1 - upstream wiki, etoro.Dictionary.WithdrawApprovalReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_withdrawapprovalreason ALTER COLUMN ParentID COMMENT 'Self-referencing FK to WithdrawApprovalReasonID - links sub-reasons to their parent category. NULL for top-level categories (IDs 1-7). FK_DWAR_DWAR enforces referential integrity. Enables hierarchical reason selection in BackOffice UI. (Tier 1 - upstream wiki, etoro.Dictionary.WithdrawApprovalReason)';
ALTER TABLE main.general.bronze_etoro_dictionary_withdrawapprovalreason ALTER COLUMN MailingTemplateID COMMENT 'Foreign key to the mailing template system - identifies which email template to auto-send when this reason is selected. Only populated for sub-reasons (IDs 8-15). NULL means no automated email; compliance must communicate manually. Values: 875, 1122-1128. (Tier 1 - upstream wiki, etoro.Dictionary.WithdrawApprovalReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
