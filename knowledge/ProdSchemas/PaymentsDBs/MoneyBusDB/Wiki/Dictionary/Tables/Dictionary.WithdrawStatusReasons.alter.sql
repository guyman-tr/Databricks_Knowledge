-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.Dictionary.WithdrawStatusReasons
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md
-- Layer: bronze
-- UC Target: main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons
-- =============================================================================

-- ---- UC Target: main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons (business_group=billing) ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons SET TBLPROPERTIES (
    'comment' = 'Lookup table providing granular sub-states within the withdrawal lifecycle, tracking step-level progress through the hold-authorize-payout pipeline. Source: MoneyBusDB.Dictionary.WithdrawStatusReasons on the MoneyBusDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md).'
);

ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'Dictionary',
    'source_table' = 'WithdrawStatusReasons',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons ALTER COLUMN ID COMMENT 'Primary key identifying each withdrawal status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Withdrawals. Values: 1=Created, 2=Success, 3=HoldInitiated, 4=HoldApproved, 5=HoldDeclined, 6=AuthorizeInitiated, 7=AuthorizeApproved, 8=AuthorizeDeclined, 9=PayoutInitiated, 10=PayoutApproved, 11=PayoutDeclined, 12=AbortInitiated, 13=AbortCompleted, 14=AbortFailed, 15=RiskManualReview. See Withdraw Status Reason for full business definitions. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.WithdrawStatusReasons)';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons ALTER COLUMN Name COMMENT 'Human-readable label for the status reason. Names follow {Step}{Outcome} pattern (e.g., HoldApproved, PayoutDeclined, AbortCompleted). Read by Dictionary.WithdrawStatusReasonGet for application caching. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.WithdrawStatusReasons)';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons ALTER COLUMN WithdrawStatusID COMMENT 'Parent status that this reason belongs to. Implicit FK to Dictionary.WithdrawStatuses.ID. Maps each granular reason to its top-level outcome: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. Encodes recoverability: reasons mapping to InProcess can still progress, others are terminal. See Withdraw Status. (Tier 1 - upstream wiki, MoneyBusDB.Dictionary.WithdrawStatusReasons)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:41:14 UTC
-- Bronze deploy: MoneyBusDB batch 1
-- ====================
