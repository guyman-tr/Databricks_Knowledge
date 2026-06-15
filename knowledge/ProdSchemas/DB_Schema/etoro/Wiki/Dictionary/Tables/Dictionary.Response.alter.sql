-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_response  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Response.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ResponseID COMMENT 'Primary key. Sequential identifier for each response mapping.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ProtocolID COMMENT 'FK -> Dictionary.Protocol. Identifies which payment protocol this response belongs to. Indexed.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN PaymentActionTypeID COMMENT 'FK -> Dictionary.PaymentActionType. The action type context (PreAuth=1, Purchase=2, Refund=3, etc.). Indexed.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN PaymentStatusID COMMENT 'FK -> Dictionary.PaymentStatus. The resulting eToro payment status (Approved=1, Declined=2, etc.). Indexed.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ResponseCode COMMENT 'PSP-specific response code (e.g., "00", "51", "APPROVED", "DECLINED"). Format varies by protocol.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ResponseName COMMENT 'Human-readable PSP response description (e.g., "Transaction Approved", "Insufficient Funds").';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN Meaning COMMENT 'Extended explanation of the response code''s meaning and recommended action. May be NULL for self-explanatory codes.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN TerminalID COMMENT 'Optional terminal-specific override. When set, this response mapping only applies to transactions on this terminal. NULL = all terminals.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN GatewayID COMMENT 'FK -> Dictionary.Gateway. Optional gateway-specific override. When set, this mapping only applies to this gateway. NULL = all gateways.';
ALTER TABLE main.general.bronze_etoro_dictionary_response ALTER COLUMN ShouldTerminate COMMENT 'When true, the billing engine should stop retrying - the response is final and won''t change (e.g., card stolen, fraud, account closed).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:55:54 UTC
-- Statements: 10/10 succeeded
-- ====================
