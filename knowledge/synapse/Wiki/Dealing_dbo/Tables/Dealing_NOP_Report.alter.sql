-- =============================================================================
-- Databricks ALTER Script: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_NOP_Report.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Date COMMENT 'Report date. Saturday is skipped; Sunday uses prior Friday''s date.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN NOP COMMENT 'Net Open Position with this LP (in USD or native units - varies by LP).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN Margin COMMENT 'Margin held at this LP for this instrument position.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:25:20 UTC
-- Statements: 4/4 succeeded
-- ====================
