-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_spreadtype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.SpreadType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_spreadtype SET TBLPROPERTIES (
    'comment' = 'A lookup table defining how spread values are expressed for instruments. Spread can be measured either in absolute pips or as a percentage of the market rate. Different instrument classes use different spread conventions. Forex instruments typically use pip-based spreads (e.g., "2 pips"), while some instruments use percentage-based spreads (e.g., "0.5% of rate"). This table classifies which convention applies so the spread engine interprets the configured spread values correctly. The `Trade.InstrumentSpread` table references this type to indicate how each instrument''s spread values should be interpreted. The trading engine reads the spread type to determine whether to add a fixed pip amount or calculate a percentage markup when constructing bid/ask prices.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_spreadtype ALTER COLUMN SpreadTypeID COMMENT 'Primary key. Spread convention: 1=SpreadInPips (absolute), 2=PrecentageSpread (proportional).';
ALTER TABLE main.general.bronze_etoro_dictionary_spreadtype ALTER COLUMN Name COMMENT 'Spread type identifier used in configuration. Note: "PrecentageSpread" (original spelling preserved).';
ALTER TABLE main.general.bronze_etoro_dictionary_spreadtype ALTER COLUMN Description COMMENT 'Human-readable description explaining how the spread values should be interpreted.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:26 UTC
-- Statements: 4/4 succeeded
-- ====================
