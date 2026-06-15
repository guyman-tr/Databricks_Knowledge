-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_etoro_billing_financialdiscrepancy  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.FinancialDiscrepancy.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN ID COMMENT 'Surrogate PK. Auto-incremented discrepancy record identifier.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN DiscrepancyTypeID COMMENT 'Type of financial discrepancy. FK to Dictionary.FinancialDiscrepancyType(ID). 17 types covering duplicate transactions, wrong exchange rates, balance mismatches, conversion fee errors, 3DS issues, and data leakage.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN CreditTypeID COMMENT 'Credit type of the originating operation (e.g., deposit, cashout, redeem). Likely references Dictionary.FundingType or a similar credit type table. No FK constraint. Used to disambiguate the type of OperationID.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN OperationID COMMENT 'ID of the specific billing operation that triggered the discrepancy (e.g., DepositID, CashoutID, RedeemID). Implicit reference - no FK constraint. Combined with CreditTypeID, identifies the exact transaction that caused the discrepancy.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN HasFinancialImpact COMMENT 'Whether this discrepancy resulted in a real monetary gap. 1=financial impact detected (FinancialGap will be set), 0=discrepancy detected but no monetary consequence.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN FinancialGap COMMENT 'The monetary size of the discrepancy in USD. High precision (8 decimal places) to capture fractional amounts from currency conversion. NULL when HasFinancialImpact=0.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN FinancialDiscrepancyDirectionID COMMENT 'Direction of the financial gap. FK to Dictionary.FinancialDiscrepancyDirection(ID). Currently only 1 value: "Missing funds on eToro Account Balance". NULL when HasFinancialImpact=0.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN Description COMMENT 'Free-text description of the discrepancy. Written by the detection system or manual investigator. Contains diagnostic details about what was expected vs. what was found. Stored in TEXTIMAGE_ON [MAIN] due to max length.';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN CreatedDate COMMENT 'When this discrepancy record was created (detection timestamp). Set by the inserting process.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:27:42 UTC
-- Statements: 9/9 succeeded
-- ====================
