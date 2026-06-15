-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_stockerror
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.StockError.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_stockerror SET TBLPROPERTIES (
    'comment' = 'A lookup table defining error codes for stock/REAL asset order failures. Each entry describes a specific failure condition that prevented a stock order from executing successfully. When a REAL (physical stock) order fails - due to insufficient funds, mirror relationship issues, or order cancellation - the system records a specific error code in `Stocks.OrderFail`. This table provides the human-readable error names for those failure codes, enabling support and operations teams to diagnose order failures. The `Stocks.OrderFail` table stores failed stock orders with a `StockErrorID` from this table. Support tools and reports join this table to display the failure reason. Error codes 0-3 relate to CopyTrading/mirror operations (where the copied trade failed due to the copier''s account conditions), while codes 6-7 relate to order cancellation scenarios.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_stockerror ALTER COLUMN StockErrorID COMMENT 'Primary key. Error code: 0=Unknown, 1=Mirror Not Found, 2=Insufficient Mirror Funds, 3=Insufficient Ancestor Funds, 6=Cancelled, 7=Parent Cancelled.';
ALTER TABLE main.general.bronze_etoro_dictionary_stockerror ALTER COLUMN Name COMMENT 'Fixed-width error name. Padded with spaces due to char(50) type. Describes the specific failure condition.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:28 UTC
-- Statements: 3/3 succeeded
-- ====================
