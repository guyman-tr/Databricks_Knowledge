-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_stockhedgesource
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.StockHedgeSource.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_stockhedgesource SET TBLPROPERTIES (
    'comment' = 'A lookup table defining the origin/method by which a stock hedge operation was initiated. Tracks whether the hedge was executed manually by the dealing desk, automatically via the FAPI (Front API) system, or automatically using a closing rate calculation. Stock (REAL asset) hedge operations can be triggered through different channels - manual dealing desk intervention, automated FAPI processing, or automated closing-rate-based execution. Tracking the source helps the dealing desk understand how hedges were created, supports audit trails, and enables analysis of manual vs. automated hedge ratios. The `History.StocksHedge` table records every stock hedge operation with a `StockHedgeSourceID` from this table. This allows reporting on hedge source distribution, identifying manual interventions, and tracking the automation rate of stock hedge execution.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_stockhedgesource ALTER COLUMN StockHedgeSourceID COMMENT 'Primary key. Hedge source: 0=Unknown, 1=Manual, 2=Auto FAPI, 3=Auto Closing Rate.';
ALTER TABLE main.general.bronze_etoro_dictionary_stockhedgesource ALTER COLUMN Name COMMENT 'Human-readable hedge source label for dealing desk reports and audit trails.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:29 UTC
-- Statements: 3/3 succeeded
-- ====================
