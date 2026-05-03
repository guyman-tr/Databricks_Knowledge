-- =============================================================================
-- Databricks ALTER Script: bronze UserApiDB.Customer.CustomerIdentification
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.CustomerIdentification.md
-- Layer: bronze
-- UC Target: main.compliance.bronze_userapidb_customer_customeridentification
-- =============================================================================

-- ---- UC Target: main.compliance.bronze_userapidb_customer_customeridentification (business_group=compliance) ----
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification SET TBLPROPERTIES (
    'comment' = 'Maps the three user identifiers (GCID, CID, DemoCID) and stores crypto custody wallet data (Tangany and DLT identifiers with statuses). Source: UserApiDB.Customer.CustomerIdentification on the UserApiDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/UserApiDB/Wiki/Customer/Tables/Customer.CustomerIdentification.md).'
);

ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'UserApiDB',
    'source_schema' = 'Customer',
    'source_table' = 'CustomerIdentification',
    'business_group' = 'compliance',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN GCID COMMENT 'Primary key. Global Customer ID - the modern universal identifier. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN CID COMMENT 'Legacy real-account Customer ID. Used by older trading systems. Indexed for fast CID-to-GCID lookup. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN DemoCID COMMENT 'Demo/practice account Customer ID. Links to the user''s virtual-money account. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN TanganyID COMMENT 'Tangany crypto custody wallet GUID. Uniquely indexed (filtered, non-null only). NULL if user has no Tangany wallet. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN UpdateDate COMMENT 'Last modification timestamp for this record. Default: current datetime. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN TanganyStatusID COMMENT 'FK to Dictionary.TanganyStatus. Wallet lifecycle state: 1=Pending, 2=Internal, 3=Customer, 4=Inactive, 5=MicaCustomer, 6=ConsentCustomer. See Tangany Status. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN DltID COMMENT 'DLT (Distributed Ledger Technology) identifier for blockchain operations. NULL if user has no DLT setup. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
ALTER TABLE main.compliance.bronze_userapidb_customer_customeridentification ALTER COLUMN DltStatusID COMMENT 'FK to Dictionary.DltStatus. DLT verification state: 1=Pending, 2=Ongoing, 3=Failed, 4=Passed, 5=Inactive. See DLT Status. (Tier 1 - upstream wiki, UserApiDB.Customer.CustomerIdentification)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:48:45 UTC
-- Bronze deploy: UserApiDB batch 1
-- ====================
