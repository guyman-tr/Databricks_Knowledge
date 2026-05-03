-- =============================================================================
-- Databricks ALTER Script: bronze Sodreconciliation.apex.EXT765_AccountMaster
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT765_AccountMaster.md
-- Layer: bronze
-- UC Target: main.general.bronze_sodreconciliation_apex_ext765_accountmaster
-- =============================================================================

-- ---- UC Target: main.general.bronze_sodreconciliation_apex_ext765_accountmaster (business_group=general) ----
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster SET TBLPROPERTIES (
    'comment' = 'Account master data from Apex Clearing EXT765 extract: customer accounts with addresses, tax info, IRA status, margin settings, and option levels. Source: Sodreconciliation.apex.EXT765_AccountMaster on the Sodreconciliation production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT765_AccountMaster.md).'
);

ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'Sodreconciliation',
    'source_schema' = 'apex',
    'source_table' = 'EXT765_AccountMaster',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Id COMMENT 'Primary key. Auto-generated sequential GUID for each row. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN SodFileId COMMENT 'FK to apex.SodFiles. Links this row to the specific EXT765 file import. CASCADE DELETE. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AccountNumber COMMENT 'Apex customer account number. MASKED (PII). Primary account identifier at the clearing firm. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN OfficeCode COMMENT 'Apex office/branch code associated with the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN RegisteredRepCode COMMENT 'Registered representative code assigned to the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN FederalIDIndicator COMMENT 'Indicates the type of federal tax ID: SSN for individuals, EIN for entities. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TaxIdNumber COMMENT 'Federal tax identification number (SSN or EIN). MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN ShortName COMMENT 'Abbreviated account holder name. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN RelatedParty COMMENT 'Code indicating related party status for regulatory reporting. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AccountName COMMENT 'Full account holder name. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AddressLine1 COMMENT 'Primary address line. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AddressLine2 COMMENT 'Secondary address line. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AddressLine3 COMMENT 'Third address line. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AddressLine4 COMMENT 'Fourth address line. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN City COMMENT 'City of the account holder''s address. MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN State COMMENT 'State code of the account holder''s address. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN ZipCode COMMENT 'ZIP code (5 or 9 digits). MASKED (PII). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN IRSControl COMMENT 'IRS control code for tax reporting purposes. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN MMSweep COMMENT 'Money market sweep enrollment flag. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Pay COMMENT 'Payment instruction code for the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Div COMMENT 'Dividend instruction code (reinvest, cash, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AccountClass COMMENT 'Account classification code (e.g., cash, margin, DVP). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN PrintStatment COMMENT 'Statement printing preference flag. Note: column name has typo ("Statment"). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Discretion COMMENT 'Discretionary authority indicator or description. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN PortfolioIndicator COMMENT 'Flag indicating portfolio margin eligibility or enrollment. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN IRA COMMENT 'IRA account type code (Traditional, Roth, SEP, etc.). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN CreditInterestSweep COMMENT 'Credit interest sweep program enrollment flag. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN MoneySweep COMMENT 'Money sweep program enrollment flag. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN OptionLevel COMMENT 'Options trading approval level (0-5 typically). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Exposure COMMENT 'Account exposure level or risk rating. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN NYTax COMMENT 'New York state tax withholding indicator. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN StateTax COMMENT 'State tax withholding indicator. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN IRSCode COMMENT 'IRS reporting code for the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN NonObjecting COMMENT 'Non-Objecting Beneficial Owner (NOBO) status flag for proxy communications. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN IRSExempt COMMENT 'IRS tax exemption indicator. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN ForeignCode COMMENT 'Foreign account indicator code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN OptionLimit COMMENT 'Maximum number of option contracts allowed. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN SuppressConfirm COMMENT 'Flag to suppress trade confirmation mailings. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN RestrictReasonCode COMMENT 'Restriction reason code if the account is restricted. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN W8 COMMENT 'W-8 form status indicator for foreign account holders. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Joint COMMENT 'Joint account indicator. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Margin COMMENT 'Margin account eligibility/status flag. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN OptionCode COMMENT 'Option trading authorization code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN PowerAttorney COMMENT 'Power of attorney indicator on the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN DVP COMMENT 'Delivery vs. Payment settlement indicator. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Sweep COMMENT 'Cash sweep program enrollment flag. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN Instituion COMMENT 'Institution code. Note: column name has typo ("Instituion"). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AgentBank COMMENT 'Agent bank code for the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoExtension1 COMMENT 'Primary phone extension. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoExtension2 COMMENT 'Secondary phone extension. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN RestrDate COMMENT 'Date the restriction was applied to the account. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN OpenDDate COMMENT 'Account open date. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN LastChangeDate COMMENT 'Date the account record was last modified at Apex. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN LastActivtyDate COMMENT 'Date of last activity on the account. Note: column name has typo ("Activty"). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AddressIndicator COMMENT 'Address type or validation indicator. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoCode1 COMMENT 'Primary phone type code (home, work, mobile). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoCode2 COMMENT 'Secondary phone type code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoAreaCode1 COMMENT 'Primary phone area code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoExchange1 COMMENT 'Primary phone exchange digits. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoBase1 COMMENT 'Primary phone base number digits. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoAreaCode2 COMMENT 'Secondary phone area code. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoExchange2 COMMENT 'Secondary phone exchange digits. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TelcoBase2 COMMENT 'Secondary phone base number digits. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN OldSystemAccountNumber COMMENT 'Account number from a prior clearing system (legacy migration reference). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN ClosedDate COMMENT 'Date the account was closed. NULL if the account is active. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN TefraChangeYY COMMENT 'Date of last TEFRA (Tax Equity and Fiscal Responsibility Act) status change. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN ProcessDate COMMENT 'Business date of the Apex extract file. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN AccountNature COMMENT 'Account nature code describing the ownership type or purpose. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN CATAccountType COMMENT 'Consolidated Audit Trail (CAT) account type classification. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN FDID COMMENT 'Firm Designated ID for CAT reporting (SEC Rule 613). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN MPID COMMENT 'Market Participant Identifier for regulatory reporting. (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
ALTER TABLE main.general.bronze_sodreconciliation_apex_ext765_accountmaster ALTER COLUMN OATSAccountType COMMENT 'OATS (Order Audit Trail System) account type code (legacy, replaced by CAT). (Tier 1 - upstream wiki, Sodreconciliation.apex.EXT765_AccountMaster)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:42:23 UTC
-- Bronze deploy: Sodreconciliation batch 1
-- ====================
