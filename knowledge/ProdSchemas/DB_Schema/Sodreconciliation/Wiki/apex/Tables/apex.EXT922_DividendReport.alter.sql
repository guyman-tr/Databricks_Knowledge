-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT922_DividendReport
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT922_DividendReport.md
-- Layer: bronze
-- UC Target: main.finance.bronze_sodreconciliation_apex_ext922_dividendreport
-- =============================================================================

-- ---- UC Target: main.finance.bronze_sodreconciliation_apex_ext922_dividendreport (business_group=finance) ----
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport SET TBLPROPERTIES (
    'comment' = 'Dividend and interest report from Apex Clearing EXT922 extract: ex-dates, record dates, pay dates, dividend rates, and withholding per security and account. Source: Sodreconciliation.apex.EXT922_DividendReport on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT922_DividendReport.md).'
);

ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT922_DividendReport',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT922 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN ReportDate COMMENT 'Date the dividend/interest report was generated. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN ReportNumber COMMENT 'Apex report identifier number. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN ReportName COMMENT 'Name/title of the report. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN Symbol COMMENT 'Trading symbol of the security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN Cusip COMMENT 'CUSIP identifier of the security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN Description1 COMMENT 'Security description line 1. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN Description2 COMMENT 'Security description line 2. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN Description3 COMMENT 'Security description line 3. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN SecurityTypeCode COMMENT 'Security type classification code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN CurrencyCode COMMENT 'ISO currency code for the dividend/interest payment. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN ExchangeDate COMMENT 'Ex-dividend date (date the stock trades without the dividend). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN RecordDate COMMENT 'Record date for dividend entitlement. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN PayDate COMMENT 'Payment date when dividends/interest are distributed. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN DividendRate COMMENT 'Dividend or interest rate per share/unit. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN MaturityDate COMMENT 'Bond maturity date (for fixed-income securities). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN CouponDate COMMENT 'Next coupon payment date for bonds. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN FirstCouponDate COMMENT 'First coupon payment date for newly issued bonds. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN CouponRate COMMENT 'Annual coupon rate for bonds (stored as string). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN IssueDate COMMENT 'Original issue date of the security. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN AccountType COMMENT 'Account type code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN AccountName COMMENT 'Account holder name. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN Position COMMENT 'Position quantity as a string value. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN PositionQuantityLongOrShort COMMENT 'Indicates whether the position is long or short and its quantity. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN DividendInterest COMMENT 'Calculated dividend or interest amount for the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
ALTER TABLE main.finance.bronze_sodreconciliation_apex_ext922_dividendreport ALTER COLUMN WithHoldAmount COMMENT 'Tax withholding amount deducted from the dividend/interest. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT922_DividendReport)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:42:23 UTC
-- Bronze deploy: Sodreconciliation batch 1
-- ====================
