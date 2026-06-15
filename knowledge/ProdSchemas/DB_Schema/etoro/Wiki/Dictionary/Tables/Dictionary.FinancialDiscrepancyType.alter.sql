-- =============================================================================
-- Databricks ALTER Script: main.finance.bronze_etoro_dictionary_financialdiscrepancytype  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FinancialDiscrepancyType.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN ID COMMENT 'Primary key identifying the discrepancy type. 1=Duplicated Deposit, 2=Update Customer Balance Discrepancy, 3=Customer Balance Recovery, 4=Duplicated Cashouts, 5=Duplicated FTD, 6=3DS Not Authorized, 7=Wrong Rate (Deposit), 8=Wrong Rate (Cashout), 9=Override Exchange Rate, 10=Deposit PIPS Mismatch, 11=Cashout PIPS Mismatch, 12=Wrong Conversion Fees, 13=eToroMoney Transfer Deposit Discrepancy, 14=Wrong Redeem Conversion Fees, 15=Wrong Withdraw Request Fees, 16=Credit Card Data Leakage, 17=Test. Referenced by Billing.FinancialDiscrepancy via explicit FK.';
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN Name COMMENT 'Short label for the discrepancy type. Used in BackOffice investigation UI and reconciliation reports. Describes the anomaly category concisely.';
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN Meaning COMMENT 'Extended description explaining the discrepancy in business terms. Provides investigation context for operations staff - what went wrong and what needs to be checked.';
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN IsHaveFinancialImpact COMMENT 'Flag indicating whether this discrepancy type has a direct monetary impact on the customer''s balance (1=yes) versus being informational/security-only (0=no). Currently NULL for all production types (1-16) and false for the test entry (17), suggesting this classification is not yet actively used in automated workflows.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:56:34 UTC
-- Statements: 4/4 succeeded
-- ====================
