-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation SET TBLPROPERTIES (
    'comment' = 'KYC/AML data from Apex Clearing EXT1034 extract: income, net worth, investment experience, risk tolerance, and employment per account. Source: Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation on the Sodreconciliation production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md).'
);

ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT1034_NewAccountFinancialInformation',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT1034 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN Correspondent COMMENT 'Correspondent firm identifier/name. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN Branch COMMENT 'Branch/office code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN RepCode COMMENT 'Registered representative code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN TaxIDNumber COMMENT 'Federal tax identification number (SSN or EIN). MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN CustomerCode COMMENT 'Apex customer classification code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN CodeDescription COMMENT 'Description of the customer code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AccountType COMMENT 'Account type classification. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN OpenDate COMMENT 'Date the account was opened. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN DateOfBirth COMMENT 'Account holder''s date of birth. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AccountName1 COMMENT 'Account holder name. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AddressLine1 COMMENT 'Primary address line. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AddressLine2 COMMENT 'Secondary address line. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN City COMMENT 'City. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN State COMMENT 'State code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN ZipCode COMMENT 'ZIP code. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN LegalAddressindicator COMMENT 'Indicator for whether the address is the legal/mailing address. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN CountryCode COMMENT 'Country code for the address. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN EmailAddress COMMENT 'Email address. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AnnualIncome COMMENT 'Self-reported annual income range or amount (stored as string). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN NetWorth COMMENT 'Self-reported total net worth range or amount (stored as string). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN LiquidNetWorth COMMENT 'Self-reported liquid net worth range or amount (stored as string). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN InvestmentExperience COMMENT 'Level of investment experience (none, limited, good, extensive). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN InvestmentObjective COMMENT 'Primary investment objective (income, growth, speculation, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN RiskTolerance COMMENT 'Risk tolerance level (low, medium, high). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN LiquidityNeeds COMMENT 'Liquidity needs (very important, somewhat important, not important). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN TimeHorizon COMMENT 'Investment time horizon (short, medium, long). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AffiliatedPerson COMMENT 'Affiliated person disclosure (broker-dealer affiliation). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AffiliatedPersonDetail COMMENT 'Details about the affiliated person relationship. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN AffiliatedApprovalSnapIDs COMMENT 'Reference ID for affiliated person approval snapshots. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN ControlPerson COMMENT 'Control person disclosure (officer, director, 10%+ shareholder). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN ControlPersonCompany COMMENT 'Company name for which the account holder is a control person. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN Employer COMMENT 'Account holder''s employer name. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';
ALTER TABLE main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation ALTER COLUMN EmploymentStatus COMMENT 'Employment status (employed, self-employed, retired, student, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation)';

