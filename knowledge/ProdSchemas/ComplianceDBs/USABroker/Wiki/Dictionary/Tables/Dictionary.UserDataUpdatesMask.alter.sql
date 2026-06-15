-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_usabroker_dictionary_userdataupdatesmask
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.UserDataUpdatesMask.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_userdataupdatesmask SET TBLPROPERTIES (
    'comment' = '`Dictionary.UserDataUpdatesMask` is a static reference table that defines the individual bit flags used to represent which specific data fields were included in a user data update event. Rather than storing a separate boolean column for each updatable field, the platform encodes the set of changed fields as a single integer bitmask - a common pattern for efficient storage and flexible multi-field queries. Each row defines one bit position and its corresponding field name. A bitmask value stored in `Apex.UserDataUpdates.UpdatesMask`, `Apex.UserParameters.UpdatesMask`, or `Apex.RequestLog.UpdateEventMask` is decoded by bitwise AND against each row in this table. For example, a mask value of `192` means both `PhoneNumber` (64) and `HomeAddress` (128) were updated in that event.'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_usabroker_dictionary_userdataupdatesmask ALTER COLUMN Mask COMMENT 'The power-of-two bit value representing this field in a composite bitmask integer. Used as the PK and as the operand in bitwise AND operations.';
ALTER TABLE main.finance.bronze_usabroker_dictionary_userdataupdatesmask ALTER COLUMN Name COMMENT 'Human-readable field name corresponding to this bit position; used in reporting and audit decoding.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:40:45 UTC
-- Statements: 3/3 succeeded
-- ====================
