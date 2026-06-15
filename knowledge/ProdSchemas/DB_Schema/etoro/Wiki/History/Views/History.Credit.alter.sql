-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_history_credit  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Views/History.Credit.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN CreditID COMMENT 'CAST to bigint in all branches. INT range (< 2^31) for 2007-2020 archive rows; bigint range for 2021+ rows.';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MirrorEquity COMMENT 'Mirror portfolio equity. Present in History.ActiveCredit; present in archive branches where the column existed (older archives may have it or not).';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MirrorDividendID COMMENT 'NULL in all archive branches (column post-dates archives). Native in History.ActiveCredit.';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN MoveMoneyReasonID COMMENT 'NULL in all archive branches. Native in History.ActiveCredit.';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN BSLRealFunds COMMENT 'NULL in all archive branches (Buy Stock Limit feature added later). Native in History.ActiveCredit.';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN OriginalPositionID COMMENT 'ISNULL(OriginalPositionID, PositionID) from History.ActiveCredit. PositionID AS OriginalPositionID in all archive branches.';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN SubCreditTypeID COMMENT 'NULL in all archive branches. Native in History.ActiveCredit.';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN PartitionCol COMMENT 'NULL in all archive branches. Native value from History.ActiveCredit (hash bucket).';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN DepositRollbackID COMMENT 'NULL in all archive branches. Native in History.ActiveCredit.';
ALTER TABLE main.general.bronze_etoro_history_credit ALTER COLUMN InterestMonthlyID COMMENT 'NULL in all archive branches. Native in History.ActiveCredit.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:20:30 UTC
-- Statements: 10/10 succeeded
-- ====================
