-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_conversionfee  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ConversionFee.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN CurrencyID COMMENT 'Primary key. The currency for which this fee applies. FK to `Dictionary.Currency` implicitly. CurrencyID=1 (USD) has no entry - USD is eToro''s base currency requiring no conversion.';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN InstrumentID COMMENT 'The forex trading instrument for this currency pair (e.g., EUR/USD=1, GBP/USD=2, AUD/USD=7). References `Trade.Instrument` implicitly. Used by the exchange rate SP to retrieve current bid/ask rates for the conversion.';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN DepositFee COMMENT 'Flat deposit conversion fee in the local currency''s smallest unit (cents, pence, subunits, etc.). Applied when a customer makes a deposit in this currency and eToro converts to USD.';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN CashoutFee COMMENT 'Flat cashout conversion fee in the local currency''s smallest unit. Applied when a customer withdraws in this currency and eToro converts from USD. CHF has asymmetric fees (DepositFee=140, CashoutFee=150).';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the last modification to this fee row. Defaults to GETUTCDATE() on insert. All rows = 2024-05-02 (bulk fee update). Distinct from temporal ValidFrom (which is system-managed).';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ValidFrom COMMENT 'System-managed temporal column. UTC timestamp when this row version became current. Automatically set by SQL Server on INSERT/UPDATE.';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ValidTo COMMENT 'System-managed temporal column. UTC timestamp when this row version was superseded. Current rows: 9999-12-31. Set to NOW when updated or deleted; historical row moved to History.ConversionFee.';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN DepositFeePercentage COMMENT 'Percentage-based deposit fee (e.g., 1.50 = 1.5%). Currently NULL for all rows - reserved for future percentage-based fee model. Already queried by GetExchangeRatesForCustomerFunding_v4.';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN CashoutFeePercentage COMMENT 'Percentage-based cashout fee. Currently NULL for all rows - future use.';
ALTER TABLE main.billing.bronze_etoro_billing_conversionfee ALTER COLUMN ConversionFeeID COMMENT 'Secondary identity column (NOT the PK). Auto-generated starting at 100,000. Provides a stable row identifier separate from the CurrencyID PK, used in override and audit references.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:27:10 UTC
-- Statements: 10/10 succeeded
-- ====================
