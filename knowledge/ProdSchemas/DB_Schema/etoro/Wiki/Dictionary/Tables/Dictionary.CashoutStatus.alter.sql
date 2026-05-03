-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.CashoutStatus
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutStatus.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_dictionary_cashoutstatus
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_dictionary_cashoutstatus (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutstatus SET TBLPROPERTIES (
    'comment' = 'Lookup table defining the 17-state lifecycle of withdrawal (cashout) requests, tracking from submission through processing to completion or rejection. Source: etoro.Dictionary.CashoutStatus on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutStatus.md).'
);

ALTER TABLE main.general.bronze_etoro_dictionary_cashoutstatus SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'CashoutStatus',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutstatus ALTER COLUMN CashoutStatusID COMMENT 'Primary key identifying the withdrawal lifecycle state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Partially Processed, 6=Payment Sent, 7=Rejected, 8=RejectedByProvider, 9=PendingByProvider, 10=SentToProvider, 11=SentToBilling, 12=ReceivedByBilling, 13=Failed, 14=Pending Review, 15=Under Review, 16=Reversed, 17=Partially Reversed. See Cashout Status. (Dictionary.CashoutStatus) (Tier 1 - upstream wiki, etoro.Dictionary.CashoutStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutstatus ALTER COLUMN Name COMMENT 'Human-readable status label. UNIQUE constraint. Used in back-office withdrawal management UI and user-facing withdrawal history. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutstatus ALTER COLUMN IsFinishedWithoutMoneyTransfer COMMENT 'Whether this status represents a termination where NO funds left the system. 1 for Canceled (4) and Rejected (7) - important for reconciliation because the withdrawal entry exists but no actual payment was made. 0 for all other statuses. (Tier 1 - upstream wiki, etoro.Dictionary.CashoutStatus)';
ALTER TABLE main.general.bronze_etoro_dictionary_cashoutstatus ALTER COLUMN IsFinalStatus COMMENT 'Whether this is a terminal state (no further transitions expected). 1 for Processed, Canceled, Partially Processed, Rejected, RejectedByProvider, Failed. NULL for intermediate states. Used by monitoring to identify stuck withdrawals (intermediate status for too long = alert). (Tier 1 - upstream wiki, etoro.Dictionary.CashoutStatus)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
