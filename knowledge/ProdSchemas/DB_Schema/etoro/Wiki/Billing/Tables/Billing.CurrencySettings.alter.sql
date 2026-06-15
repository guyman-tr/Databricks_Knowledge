-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_etoro_billing_currencysettings  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.CurrencySettings.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN ID COMMENT 'Surrogate primary key. No business significance - internal row identifier.';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN CurrencyID COMMENT 'Currency being configured. Implicit FK to Dictionary.Currency. The lookup key used by PIP calculation functions: `JOIN Billing.CurrencySettings ON CurrencyID = BD.CurrencyID`. Covers 31 currencies including EUR (2), GBP (3), JPY (4), AUD (5), CHF (6), CAD (7), and others.';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN InstrumentID COMMENT 'Trading instrument that provides the exchange rate for this currency. Implicit FK to the Trade instrument table. For major currencies, typically the standard forex pair (e.g., EUR->InstrumentID=1 is EUR/USD). For some currencies, CurrencyID=InstrumentID (e.g., 79, 80, 81 where currency and instrument share the same ID - likely non-USD instruments referenced directly).';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN IsReciprocal COMMENT 'Rate direction flag: 0=direct quote (currency is base, e.g., EUR/USD), 1=reciprocal quote (USD is base, e.g., USD/JPY, must invert rate). Used by PIP formula to determine whether to apply rate directly or as 1/rate. 0 for 9 currencies (EUR, GBP, AUD, CAD, and some crypto), 1 for 22 currencies (most others including JPY, CHF, CNY).';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN Precision COMMENT 'Decimal places used for this currency in PIP calculations. Determines rounding precision in the PIP formula. Values: 0=JPY-class (no decimal), 2=most standard currencies, 4=major FX pairs (EUR, GBP, AUD, CAD), 5=crypto/exotic instruments.';
ALTER TABLE main.bi_db.bronze_etoro_billing_currencysettings ALTER COLUMN ModificationDate COMMENT 'Timestamp of last configuration update. All 31 rows show 2024-05-06 - a bulk update/refresh event. Used for change tracking by the admin tool.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:59 UTC
-- Statements: 6/6 succeeded
-- ====================
