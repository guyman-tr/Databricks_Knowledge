-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_duration
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Duration.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_duration SET TBLPROPERTIES (
    'comment' = 'A lookup table defining time duration configurations for legacy forex/game trading sessions. Each entry pairs a time interval (in minutes) with a fixed/variable duration flag. In the legacy "game-style" trading mode, users could open positions with predefined time durations (e.g., 1-minute, 5-minute, 50-minute trades). This table defined the available duration options and whether the duration was fixed (exact expiry time) or floating. Referenced by legacy game/session views (`Customer.GetSessionWithTrade`, `Customer.GetGameWithTrade`, `Game.GetForexResult`, `OldStyle.GetForexGame`) that join on `DurationID`. Part of the early eToro "social forex game" model that has since been replaced by standard CFD trading.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_duration ALTER COLUMN DurationID COMMENT 'Primary key. Sequential 0-15 identifier.';
ALTER TABLE main.general.bronze_etoro_dictionary_duration ALTER COLUMN Name COMMENT 'Duration code in `{Interval}{F|T}` format. Padded with spaces (char, not varchar). Unique index.';
ALTER TABLE main.general.bronze_etoro_dictionary_duration ALTER COLUMN Interval COMMENT 'Time interval in minutes (0, 1, 2, 3, 4, 5, 10, 50).';
ALTER TABLE main.general.bronze_etoro_dictionary_duration ALTER COLUMN IsFixDuration COMMENT 'Whether the duration is fixed (true=exact expiry, false=variable/floating).';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:43:23 UTC
-- Statements: 5/5 succeeded
-- ====================
