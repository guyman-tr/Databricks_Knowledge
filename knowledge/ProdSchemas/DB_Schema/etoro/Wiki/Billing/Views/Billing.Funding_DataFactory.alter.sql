-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_billing_funding_datafactory  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.Funding_DataFactory.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN FundingID COMMENT 'Payment instrument PK. From Billing.Funding. IDENTITY(1000,1).';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN FundingTypeID COMMENT 'Payment method type. From Billing.Funding. 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 33=eToroMoney, etc.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN ManagerID COMMENT 'Operations manager ID. NULL=self-registered. From Billing.Funding.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN IsBlocked COMMENT '1=instrument blocked. 0=active. From Billing.Funding.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN BlockedDescription COMMENT 'Block reason text. From Billing.Funding.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN BlockedAt COMMENT 'Block timestamp. From Billing.Funding.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN FundingData COMMENT 'Provider-specific instrument data as native XML. Not CAST to NVARCHAR (unlike other Funding views). Subject to DDM masking. ADF pipelines must handle XML serialization.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN IsRefundExcluded COMMENT '1=excluded from automatic refund. From Billing.Funding.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN DocumentRequired COMMENT '1=KYC documentation required. From Billing.Funding.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN DateCreated COMMENT 'UTC timestamp of instrument registration. From Billing.Funding.';
ALTER TABLE main.billing.bronze_etoro_billing_funding_datafactory ALTER COLUMN PaymentDetails COMMENT 'Pre-computed human-readable payment account identifier. Trigger-maintained column from Billing.Funding (populated by TR_FundingPaymentDetails via Billing.FormatFundingPaymentDetailsForWithdraw on each FundingData change). Unlike other views where PaymentDetails is computed in the view''s CASE expression, this is a stored column from the base table.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:55:41 UTC
-- Statements: 11/11 succeeded
-- ====================
