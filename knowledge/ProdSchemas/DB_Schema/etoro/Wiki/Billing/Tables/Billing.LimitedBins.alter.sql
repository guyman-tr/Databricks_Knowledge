-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_limitedbins  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.LimitedBins.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_limitedbins ALTER COLUMN Bin COMMENT 'Credit/debit card BIN (Bank Identification Number) - the first 6 digits of the card number identifying the issuing bank and card program. Serves as both the primary key and the sole data element. Cards whose BIN matches an entry here are treated as "limited" in the deposit flow and may face deposit restrictions.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:57:54 UTC
-- Statements: 1/1 succeeded
-- ====================
