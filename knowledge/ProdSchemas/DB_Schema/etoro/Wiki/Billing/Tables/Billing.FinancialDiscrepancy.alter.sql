-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.FinancialDiscrepancy
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.FinancialDiscrepancy.md
-- Layer: bronze
-- UC Target: main.finance.bronze_etoro_billing_financialdiscrepancy
-- =============================================================================

-- ---- UC Target: main.finance.bronze_etoro_billing_financialdiscrepancy (business_group=finance) ----
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy SET TBLPROPERTIES (
    'comment' = 'Financial discrepancy audit log for the billing domain; captures detected inconsistencies (duplicated deposits/cashouts, wrong exchange rates, balance mismatches, 3DS unauthorized transactions, etc.) with type, direction, financial gap amount, and description. Source: etoro.Billing.FinancialDiscrepancy on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.FinancialDiscrepancy.md).'
);

ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'FinancialDiscrepancy',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN ID COMMENT 'Surrogate PK. Auto-incremented discrepancy record identifier. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN DiscrepancyTypeID COMMENT 'Type of financial discrepancy. FK to Dictionary.FinancialDiscrepancyType(ID). 17 types covering duplicate transactions, wrong exchange rates, balance mismatches, conversion fee errors, 3DS issues, and data leakage. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN CreditTypeID COMMENT 'Credit type of the originating operation (e.g., deposit, cashout, redeem). Likely references Dictionary.FundingType or a similar credit type table. No FK constraint. Used to disambiguate the type of OperationID. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN OperationID COMMENT 'ID of the specific billing operation that triggered the discrepancy (e.g., DepositID, CashoutID, RedeemID). Implicit reference - no FK constraint. Combined with CreditTypeID, identifies the exact transaction that caused the discrepancy. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN HasFinancialImpact COMMENT 'Whether this discrepancy resulted in a real monetary gap. 1=financial impact detected (FinancialGap will be set), 0=discrepancy detected but no monetary consequence. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN FinancialGap COMMENT 'The monetary size of the discrepancy in USD. High precision (8 decimal places) to capture fractional amounts from currency conversion. NULL when HasFinancialImpact=0. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN FinancialDiscrepancyDirectionID COMMENT 'Direction of the financial gap. FK to Dictionary.FinancialDiscrepancyDirection(ID). Currently only 1 value: "Missing funds on eToro Account Balance". NULL when HasFinancialImpact=0. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN Description COMMENT 'Free-text description of the discrepancy. Written by the detection system or manual investigator. Contains diagnostic details about what was expected vs. what was found. Stored in TEXTIMAGE_ON [MAIN] due to max length. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
ALTER TABLE main.finance.bronze_etoro_billing_financialdiscrepancy ALTER COLUMN CreatedDate COMMENT 'When this discrepancy record was created (detection timestamp). Set by the inserting process. (Tier 1 - upstream wiki, etoro.Billing.FinancialDiscrepancy)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
