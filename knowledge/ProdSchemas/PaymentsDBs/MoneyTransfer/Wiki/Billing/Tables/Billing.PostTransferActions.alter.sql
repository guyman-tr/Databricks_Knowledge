-- =============================================================================
-- Databricks ALTER Script: bronze MoneyTransfer.Billing.PostTransferActions
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_moneytransfer_billing_posttransferactions
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_moneytransfer_billing_posttransferactions (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions SET TBLPROPERTIES (
    'comment' = 'Records follow-up actions that occur after a primary money transfer is initiated, such as secondary fund movements, notifications, or reconciliation steps, each tracked with its own status and payload. Source: MoneyTransfer.Billing.PostTransferActions on the MoneyTransfer production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.PostTransferActions.md).'
);

ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyTransfer',
    'source_schema' = 'Billing',
    'source_table' = 'PostTransferActions',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN PostTransferActionID COMMENT 'Auto-incrementing primary key (NONCLUSTERED). Unique identifier for each post-transfer action. Current values in the ~2.59M range. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN TransferID COMMENT 'Foreign key to Billing.Transfers.TransferID (implicit, no constraint). Links this action to its parent transfer. Set by CreatePostTransfer. Every action must be associated with an existing transfer. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN ReferenceID COMMENT 'Business reference GUID for this action. Indexed (IX_Billing_PostTransferActions) for lookup performance. Used as the primary lookup key by GetPostTransfer, UpdatePostTransferPayload, and UpdatePostTransferStatus. May correspond to the parent transfer''s ReferenceID or be action-specific. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN Payload COMMENT 'Masked (Dynamic Data Masking: default()) JSON or structured data containing the action''s operational details. Contains PII. Set by CreatePostTransfer and can be updated by UpdatePostTransferPayload. The content depends on the action type and may include funding instrument details, provider responses, or processing metadata. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN FundingTypeID COMMENT 'Type of funding instrument associated with this action. No lookup table in this database. Sample data consistently shows value 33 (matching the DestinationFundingTypeID pattern in Billing.Transfers), suggesting most post-transfer actions relate to destination-side processing. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN PostTransferStatusID COMMENT 'Lifecycle status of this post-transfer action. Implicit reference to Dictionary.PostTransferStatus (currently empty). Observed values: 1 (initial/in-progress), 2 (completed). Set by CreatePostTransfer, updated by UpdatePostTransferStatus. See Post Transfer Status. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN CreateDate COMMENT 'UTC timestamp of action creation. Set automatically via DEFAULT constraint. No modification timestamp exists - status changes are tracked only by value, not by when they occurred. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';
ALTER TABLE main.bi_db.bronze_moneytransfer_billing_posttransferactions ALTER COLUMN PostTransferActionTypeID COMMENT 'Type classification for the post-transfer action. Defaults to 1 via constraint DF_PostTransferActions_PostTransferActionTypeID. All observed data shows value 1, suggesting only one action type is currently in use. No lookup table exists in this database. Set by CreatePostTransfer. (Tier 1 - upstream wiki, MoneyTransfer.Billing.PostTransferActions)';

