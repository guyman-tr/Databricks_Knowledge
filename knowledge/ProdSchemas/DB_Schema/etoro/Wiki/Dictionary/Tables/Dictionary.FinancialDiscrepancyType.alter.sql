-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Dictionary.FinancialDiscrepancyType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FinancialDiscrepancyType.md
-- Layer: bronze
-- UC Target: main.finance.bronze_etoro_dictionary_financialdiscrepancytype
-- =============================================================================

-- ---- UC Target: main.finance.bronze_etoro_dictionary_financialdiscrepancytype (business_group=finance) ----
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype SET TBLPROPERTIES (
    'comment' = 'Lookup table classifying the 17 types of financial discrepancies detected by eToro''s billing reconciliation — from duplicated deposits and cashouts to wrong exchange rates, conversion fee errors, and credit card data leakage alerts. Source: etoro.Dictionary.FinancialDiscrepancyType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.FinancialDiscrepancyType.md).'
);

ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Dictionary',
    'source_table' = 'FinancialDiscrepancyType',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN ID COMMENT 'Primary key identifying the discrepancy type. 1=Duplicated Deposit, 2=Update Customer Balance Discrepancy, 3=Customer Balance Recovery, 4=Duplicated Cashouts, 5=Duplicated FTD, 6=3DS Not Authorized, 7=Wrong Rate (Deposit), 8=Wrong Rate (Cashout), 9=Override Exchange Rate, 10=Deposit PIPS Mismatch, 11=Cashout PIPS Mismatch, 12=Wrong Conversion Fees, 13=eToroMoney Transfer Deposit Discrepancy, 14=Wrong Redeem Conversion Fees, 15=Wrong Withdraw Request Fees, 16=Credit Card Data Leakage, 17=Test. Referenced by Billing.FinancialDiscrepancy via explicit FK. (Tier 1 - upstream wiki, etoro.Dictionary.FinancialDiscrepancyType)';
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN Name COMMENT 'Short label for the discrepancy type. Used in BackOffice investigation UI and reconciliation reports. Describes the anomaly category concisely. (Tier 1 - upstream wiki, etoro.Dictionary.FinancialDiscrepancyType)';
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN Meaning COMMENT 'Extended description explaining the discrepancy in business terms. Provides investigation context for operations staff — what went wrong and what needs to be checked. (Tier 1 - upstream wiki, etoro.Dictionary.FinancialDiscrepancyType)';
ALTER TABLE main.finance.bronze_etoro_dictionary_financialdiscrepancytype ALTER COLUMN IsHaveFinancialImpact COMMENT 'Flag indicating whether this discrepancy type has a direct monetary impact on the customer''s balance (1=yes) versus being informational/security-only (0=no). Currently NULL for all production types (1-16) and false for the test entry (17), suggesting this classification is not yet actively used in automated workflows. (Tier 1 - upstream wiki, etoro.Dictionary.FinancialDiscrepancyType)';

