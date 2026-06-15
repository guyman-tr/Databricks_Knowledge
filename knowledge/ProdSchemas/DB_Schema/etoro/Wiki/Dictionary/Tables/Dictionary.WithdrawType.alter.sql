-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_etoro_dictionary_withdrawtype  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.WithdrawType.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype ALTER COLUMN WithdrawTypeID COMMENT 'Unique identifier for the withdrawal classification: 0=Default (standard cashout), 1=Transfer (internal), 2=ApprovedForClosure (closure disbursement). Stored on Billing.Withdraw and checked by 15+ procedures to determine processing path, approval requirements, and reporting categorization.';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype ALTER COLUMN WithdrawType COMMENT 'Short code name for the type: "Default", "Transfer", "ApprovedForClosure". Used as a programmatic identifier in application code and API responses.';
ALTER TABLE main.bi_db.bronze_etoro_dictionary_withdrawtype ALTER COLUMN Description COMMENT 'Human-readable description of the type. Empty for Default (0), "Internal Transfer" for Transfer (1), "Approved for closure" for ApprovedForClosure (2). Used in BackOffice UI and reports.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:45 UTC
-- Statements: 3/3 succeeded
-- ====================
