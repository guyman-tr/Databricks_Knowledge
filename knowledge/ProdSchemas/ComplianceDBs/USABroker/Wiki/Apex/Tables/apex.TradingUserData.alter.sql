-- =============================================================================
-- Databricks ALTER Script: bronze USABroker.apex.TradingUserData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.TradingUserData.md
-- Layer: bronze
-- UC Target: main.finance.bronze_usabroker_apex_tradinguserdata
-- =============================================================================

-- ---- UC Target: main.finance.bronze_usabroker_apex_tradinguserdata (business_group=finance) ----
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata SET TBLPROPERTIES (
    'comment' = 'Trading platform''s copy of essential customer personal and address data, providing the trading system with name, address, and account identifiers needed for trade execution and CAT/OATS reporting. Source: USABroker.apex.TradingUserData on the USABroker production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.TradingUserData.md).'
);

ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'USABroker',
    'source_schema' = 'apex',
    'source_table' = 'TradingUserData',
    'business_group' = 'finance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN CID COMMENT 'Platform Customer ID. Different from GCID. The internal customer identifier used in the trading/user platform. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN GCID COMMENT 'Global Customer ID. Primary key. The cross-system unique identifier. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN GivenName COMMENT 'Customer''s first/given name in uppercase. Used for regulatory reporting and trade surveillance. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN FamilyName COMMENT 'Customer''s last/family name in uppercase. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN LegalName COMMENT 'Full legal name (first + middle + last) as a single string. Used in official communications and regulatory filings. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN Country COMMENT 'ISO 3166 alpha-3 country code of the customer''s home address. Observed: "USA". (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN State COMMENT 'US state abbreviation (e.g., "CA", "TX"). Two-character USPS code. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN City COMMENT 'City name from the customer''s home address. Uppercase format. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN PostalCode COMMENT 'ZIP/postal code of the customer''s home address. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN StreetAddress1 COMMENT 'Primary street address line. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN StreetAddress2 COMMENT 'Secondary address line (apartment, suite, etc.). NULL when not applicable. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN StreetAddress3 COMMENT 'Third address line. Rarely used. NULL when not applicable. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN ApexID COMMENT 'Apex Clearing account identifier. Same value as in ApexData and TradingApexData. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN FDID COMMENT 'Financial Data Identifier - the unique customer identifier used for CAT (Consolidated Audit Trail) and OATS regulatory trade reporting. Base32-encoded format. Required by FINRA for trade surveillance. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
ALTER TABLE main.finance.bronze_usabroker_apex_tradinguserdata ALTER COLUMN InsertDate COMMENT 'Timestamp when this record was created. Default is current UTC time. Indexed for chronological queries. (Tier 1 - upstream wiki, USABroker.apex.TradingUserData)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:47:20 UTC
-- Bronze deploy: USABroker batch 1
-- ====================
