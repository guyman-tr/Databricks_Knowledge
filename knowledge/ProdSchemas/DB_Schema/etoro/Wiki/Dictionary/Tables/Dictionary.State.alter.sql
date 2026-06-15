-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_state  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.State.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_state ALTER COLUMN StateID COMMENT 'Primary key. State identifier. 0=Not Available, 1-68=US states/territories.';
ALTER TABLE main.general.bronze_etoro_dictionary_state ALTER COLUMN CountryID COMMENT 'FK -> `Dictionary.Country`. All states reference CountryID 219 (United States) except StateID 0 which references CountryID 0.';
ALTER TABLE main.general.bronze_etoro_dictionary_state ALTER COLUMN Code COMMENT 'Standard 2-letter US state abbreviation (e.g., CA, NY, TX). NULL for StateID 0. Indexed for lookup.';
ALTER TABLE main.general.bronze_etoro_dictionary_state ALTER COLUMN Name COMMENT 'Full uppercase state name. Enforced unique by index `DSTA_NAME`. Fixed-width char(50) - padded with spaces.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:29:21 UTC
-- Statements: 4/4 succeeded
-- ====================
