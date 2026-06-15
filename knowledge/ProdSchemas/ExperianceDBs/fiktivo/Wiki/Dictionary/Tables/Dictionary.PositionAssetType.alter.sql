-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dictionary_positionassettype  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_positionassettype ALTER COLUMN ID COMMENT 'Primary key identifying the asset class. Values: 0=All, 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto, 11=Copy. See [Position Asset Type](../../_glossary.md#position-asset-type) for full definitions. ID=0 serves as a wildcard in filter contexts.';
ALTER TABLE main.bi_db.bronze_fiktivo_dictionary_positionassettype ALTER COLUMN Name COMMENT 'Human-readable label for the asset class. Used in commission plan configuration, reporting displays, and admin UIs.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:16 UTC
-- Statements: 2/2 succeeded
-- ====================
