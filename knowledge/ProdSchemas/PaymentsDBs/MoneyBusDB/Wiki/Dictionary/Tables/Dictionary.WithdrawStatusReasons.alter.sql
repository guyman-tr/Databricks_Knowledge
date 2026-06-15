-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/Dictionary/Tables/Dictionary.WithdrawStatusReasons.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons ALTER COLUMN ID COMMENT 'Primary key identifying each withdrawal status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Withdrawals. Values: 1=Created, 2=Success, 3=HoldInitiated, 4=HoldApproved, 5=HoldDeclined, 6=AuthorizeInitiated, 7=AuthorizeApproved, 8=AuthorizeDeclined, 9=PayoutInitiated, 10=PayoutApproved, 11=PayoutDeclined, 12=AbortInitiated, 13=AbortCompleted, 14=AbortFailed, 15=RiskManualReview. See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason) for full business definitions.';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons ALTER COLUMN Name COMMENT 'Human-readable label for the status reason. Names follow {Step}{Outcome} pattern (e.g., HoldApproved, PayoutDeclined, AbortCompleted). Read by Dictionary.WithdrawStatusReasonGet for application caching.';
ALTER TABLE main.billing.bronze_moneybusdb_dictionary_withdrawstatusreasons ALTER COLUMN WithdrawStatusID COMMENT 'Parent status that this reason belongs to. Implicit FK to Dictionary.WithdrawStatuses.ID. Maps each granular reason to its top-level outcome: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. Encodes recoverability: reasons mapping to InProcess can still progress, others are terminal. See [Withdraw Status](../../_glossary.md#withdraw-status).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:55 UTC
-- Statements: 3/3 succeeded
-- ====================
