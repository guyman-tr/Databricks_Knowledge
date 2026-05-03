-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.UserData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.UserData.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_apex_userdata
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_apex_userdata (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_apex_userdata SET TBLPROPERTIES (
    'comment' = 'Master record of customer personal, identification, and compliance data collected during the Apex Clearing brokerage account onboarding process, with dynamic data masking on PII fields. Source: USABroker.apex.UserData on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.UserData.md).'
);

ALTER TABLE main.finance.bronze_usabroker_apex_userdata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'UserData',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN GCID COMMENT 'Global Customer ID. Primary key. One user data record per customer. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN AccountTypeID COMMENT 'Brokerage account type. FK to Dictionary.AccountType: 1=CASH, 2=MARGIN, 3=OPTION. See Account Type. Observed: most customers have MARGIN (2). (Dictionary.AccountType) (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN CustomerTypeID COMMENT 'Account ownership structure. FK to Dictionary.CustomerType: 1=INDIVIDUAL, 2=IRA, 3=JOINT, 4=CUSTODIAN. See Customer Type. (Dictionary.CustomerType) (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN FirstName COMMENT 'Customer''s first name. Dynamic data masking applied. Uppercase format for Apex API compatibility. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN LastName COMMENT 'Customer''s last/family name. Dynamic data masking applied. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN MiddleName COMMENT 'Customer''s middle name. Dynamic data masking applied. May be empty string if no middle name. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN DateOfBirth COMMENT 'Customer''s date of birth. Dynamic data masking applied. Required for CIP verification and FINRA suitability assessment. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN NationalPin COMMENT 'Social Security Number (SSN) or equivalent national identification number. Stored encrypted/hashed (varchar(128)). Dynamic data masking applied. Required for US tax reporting (W-9) and CIP verification. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN CitizenshipCountryID COMMENT 'Country ID of the customer''s citizenship. Integer reference to a country lookup (not in this schema''s Dictionary). Determines citizenship-related compliance requirements. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN PermanentResident COMMENT 'Whether the customer is a US permanent resident (green card holder). True for most US customers. Affects which forms are required and whether visa verification is needed. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN PhoneNumber COMMENT 'Customer''s phone number. Dynamic data masking applied. Format includes country code. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN PhoneNumberTypeID COMMENT 'Type of phone number provided. FK to Dictionary.PhoneType: 1=Home, 2=Work, 3=Mobile, 4=Fax, 5=Other. See Phone Type. Most customers provide Mobile (3). (Dictionary.PhoneType) (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN Email COMMENT 'Customer''s email address. Dynamic data masking applied. Used for account communications. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN Address COMMENT 'Primary street address line. Dynamic data masking applied. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN BuildingNumber COMMENT 'Building/apartment number. Dynamic data masking applied. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN City COMMENT 'City name from home address. Dynamic data masking applied. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN ProvinceID COMMENT 'State/province ID for the home address. Integer reference to a region lookup. NULL for addresses where province is not applicable. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN Zip COMMENT 'ZIP/postal code. Dynamic data masking applied. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN CountryID COMMENT 'Country ID of the customer''s home address. Integer reference to a country lookup. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN POBCountryID COMMENT 'Place of Birth country ID. NULL if not collected. Required for certain compliance checks. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN IsControlPerson COMMENT 'Whether the customer is a control person (director, 10%+ shareholder, policy-making officer) of a public company. Requires DisclosureCompanySymbols. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN DisclosureCompanySymbols COMMENT 'Stock ticker symbols of companies where the customer is a control person. Required when IsControlPerson=true. Comma-separated. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN IsAffiliatedExchangeOrFINRA COMMENT 'Whether the customer is affiliated with a FINRA member firm or stock exchange. Triggers AffiliatedApprovalRequired state and requires pre-trade approval letter. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN DisclosureFirmName COMMENT 'Name of the FINRA member firm or exchange the customer is affiliated with. Required when IsAffiliatedExchangeOrFINRA=true. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN IsPoliticallyExposed COMMENT 'Whether the customer is a Politically Exposed Person (PEP). Triggers enhanced due diligence requirements under AML regulations. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN PepAdditionalData COMMENT 'Additional PEP disclosure information (government position, family relationship to a PEP, etc.). Required when IsPoliticallyExposed=true. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN ApproverName COMMENT 'Name of the compliance officer who manually approved this account. NULL for auto-approved accounts. Set by SaveUserDataApproveInfo. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN ApprovedByDate COMMENT 'Timestamp of manual approval. NULL for auto-approved accounts. Set by SaveUserDataApproveInfo. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN BeginTime COMMENT 'System versioning row start time. Part of SYSTEM_TIME period for History.UserData. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN EndTime COMMENT 'System versioning row end time. Part of SYSTEM_TIME period. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN CID COMMENT 'Platform Customer ID (different from GCID). Links to the user management system. NULL for records created before CID tracking was added. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN Created COMMENT 'Timestamp when this user data record was first created. Distinct from BeginTime which tracks the current version''s start. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN VisaType COMMENT 'US visa classification code (e.g., H1B, F1, L1). NULL for US citizens and permanent residents. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN VisaExpirationDate COMMENT 'Expiration date of the customer''s US visa. NULL for non-visa holders. Used to determine if the visa is still valid for account operations. (Tier 1 - upstream wiki, USABroker.apex.UserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_userdata ALTER COLUMN UsVisaHolder COMMENT 'Whether the customer holds a US visa (as opposed to being a citizen or permanent resident). True triggers visa verification workflow (ApexStateID=46). (Tier 1 - upstream wiki, USABroker.apex.UserData)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:47:20 UTC
-- Bronze deploy: USABroker batch 1
-- ====================
