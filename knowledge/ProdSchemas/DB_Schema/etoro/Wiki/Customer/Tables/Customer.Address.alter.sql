-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Customer.Address
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md
-- Layer: bronze
-- UC Targets (2):
--   main.pii_data.bronze_etoro_customer_address
--   main.bi_db.bronze_etoro_customer_address_masked
-- =============================================================================

-- ---- UC Target: main.pii_data.bronze_etoro_customer_address (business_group=pii_data) ----
ALTER TABLE main.pii_data.bronze_etoro_customer_address SET TBLPROPERTIES (
    'comment' = 'Temporal table storing customer mailing/tax addresses by GCID and address type, used for KYC compliance, W8BEN tax form collection, and regulatory correspondence. Source: etoro.Customer.Address on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md).'
);

ALTER TABLE main.pii_data.bronze_etoro_customer_address SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'Address',
    'business_group' = 'pii_data',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN GCID COMMENT 'Global Customer ID - part of composite PK. Identifies the customer globally across eToro systems. References the same GCID in Customer.CustomerStatic. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN AddressTypeID COMMENT 'Address classification: 1=Mailing (only current type). FK to Dictionary.AddressType. Designed for future expansion (billing, residential, etc.). See AddressType for full definitions. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN CountryID COMMENT 'Country of the address. FK to Dictionary.Country. Always populated - the minimum required field for tax and KYC purposes. Determines which tax treaty rules apply. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN Address COMMENT 'Street address line (street name and number). NULL in many records, indicating partial submissions where only Zip was required for the specific KYC workflow. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN City COMMENT 'City/locality of the address. NULL in many records - optional depending on country-specific KYC requirements. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN Zip COMMENT 'Postal/ZIP code. The most frequently populated address field - used for country-level verification, mailing zone determination, and tax jurisdiction. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN BuildingNumber COMMENT 'Building or apartment number, separate from the street address line. NULL in most records. Supports address formats (common in some European countries) where building number is a separate field from street name. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN SubRegionID COMMENT 'Sub-regional geographic division (e.g., US state, Canadian province). FK to Dictionary.SubRegion. NULL for most records; populated for countries where regulatory compliance requires sub-region tracking. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN BeginTime COMMENT 'System-generated temporal period start. Set automatically by SQL Server when the row is created or when a previous version''s EndTime closes. Marks when this version of the address became effective. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN EndTime COMMENT 'System-generated temporal period end. Value of ''9999-12-31 23:59:59.9999999'' indicates the current active version. SQL Server sets this to the actual change time when the row is superseded. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.pii_data.bronze_etoro_customer_address ALTER COLUMN RegionID COMMENT 'IP-based geographic region. FK to Dictionary.RegionByIP (RegionByIP_ID). Optionally populated to correlate declared address with IP-inferred region for fraud/compliance checks. (Tier 1 - upstream wiki, etoro.Customer.Address)';

-- ---- UC Target: main.bi_db.bronze_etoro_customer_address_masked (business_group=bi_db) ----
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked SET TBLPROPERTIES (
    'comment' = 'Temporal table storing customer mailing/tax addresses by GCID and address type, used for KYC compliance, W8BEN tax form collection, and regulatory correspondence. Source: etoro.Customer.Address on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'Address',
    'business_group' = 'bi_db',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN GCID COMMENT 'Global Customer ID - part of composite PK. Identifies the customer globally across eToro systems. References the same GCID in Customer.CustomerStatic. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN AddressTypeID COMMENT 'Address classification: 1=Mailing (only current type). FK to Dictionary.AddressType. Designed for future expansion (billing, residential, etc.). See AddressType for full definitions. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN CountryID COMMENT 'Country of the address. FK to Dictionary.Country. Always populated - the minimum required field for tax and KYC purposes. Determines which tax treaty rules apply. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN Address COMMENT 'Street address line (street name and number). NULL in many records, indicating partial submissions where only Zip was required for the specific KYC workflow. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN City COMMENT 'City/locality of the address. NULL in many records - optional depending on country-specific KYC requirements. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN Zip COMMENT 'Postal/ZIP code. The most frequently populated address field - used for country-level verification, mailing zone determination, and tax jurisdiction. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN BuildingNumber COMMENT 'Building or apartment number, separate from the street address line. NULL in most records. Supports address formats (common in some European countries) where building number is a separate field from street name. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN SubRegionID COMMENT 'Sub-regional geographic division (e.g., US state, Canadian province). FK to Dictionary.SubRegion. NULL for most records; populated for countries where regulatory compliance requires sub-region tracking. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN BeginTime COMMENT 'System-generated temporal period start. Set automatically by SQL Server when the row is created or when a previous version''s EndTime closes. Marks when this version of the address became effective. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN EndTime COMMENT 'System-generated temporal period end. Value of ''9999-12-31 23:59:59.9999999'' indicates the current active version. SQL Server sets this to the actual change time when the row is superseded. (Tier 1 - upstream wiki, etoro.Customer.Address)';
ALTER TABLE main.bi_db.bronze_etoro_customer_address_masked ALTER COLUMN RegionID COMMENT 'IP-based geographic region. FK to Dictionary.RegionByIP (RegionByIP_ID). Optionally populated to correlate declared address with IP-inferred region for fraud/compliance checks. (Tier 1 - upstream wiki, etoro.Customer.Address)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
