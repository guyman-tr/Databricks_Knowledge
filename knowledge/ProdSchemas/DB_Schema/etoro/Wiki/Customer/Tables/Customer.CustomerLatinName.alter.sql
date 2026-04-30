-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Customer.CustomerLatinName
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerLatinName.md
-- Layer: bronze
-- UC Targets (2):
--   main.pii_data.bronze_etoro_customer_customerlatinname
--   main.general.bronze_etoro_customer_customerlatinname_masked
-- =============================================================================

-- ---- UC Target: main.pii_data.bronze_etoro_customer_customerlatinname (business_group=pii_data) ----
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname SET TBLPROPERTIES (
    'comment' = 'Per-customer Latin-script transliteration store: holds converted versions of customer names (first, last, middle), address, and city for KYC/tax/regulatory reporting where non-Latin scripts must be represented in ASCII/Latin characters. Source: etoro.Customer.CustomerLatinName on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerLatinName.md).'
);

ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'CustomerLatinName',
    'business_group' = 'pii_data',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname ALTER COLUMN CID COMMENT 'Customer ID - primary key. One Latin name record per customer. References CID in Customer.CustomerStatic (no FK constraint declared). (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname ALTER COLUMN FirstName COMMENT 'Latin-script first name. Transliterated from original non-Latin first name or supplied directly. varchar (not nvarchar) ensures only Latin/ASCII characters stored. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname ALTER COLUMN LastName COMMENT 'Latin-script last name. Transliterated equivalent of the customer''s legal surname. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname ALTER COLUMN ModifiedDate COMMENT 'UTC timestamp of last update. Default = getdate() (table-level), but Customer.SetCustomerLatinName explicitly sets GetUTCDate() on insert and update. Always UTC. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname ALTER COLUMN Address COMMENT 'Latin-script street address. Used for KYC and tax form submissions (W8BEN mailing address). NULL when address was not provided. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname ALTER COLUMN City COMMENT 'Latin-script city name. Complements Address for full mailing address on regulatory forms. NULL when address was not provided. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.pii_data.bronze_etoro_customer_customerlatinname ALTER COLUMN MiddleName COMMENT 'Latin-script middle name. Nullable - many naming conventions do not include middle names. Empty string ('''') stored for some accounts where MiddleName was set but empty in the source TVP. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';

-- ---- UC Target: main.general.bronze_etoro_customer_customerlatinname_masked (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked SET TBLPROPERTIES (
    'comment' = 'Per-customer Latin-script transliteration store: holds converted versions of customer names (first, last, middle), address, and city for KYC/tax/regulatory reporting where non-Latin scripts must be represented in ASCII/Latin characters. Source: etoro.Customer.CustomerLatinName on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerLatinName.md).'
);

ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'CustomerLatinName',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked ALTER COLUMN CID COMMENT 'Customer ID - primary key. One Latin name record per customer. References CID in Customer.CustomerStatic (no FK constraint declared). (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked ALTER COLUMN FirstName COMMENT 'Latin-script first name. Transliterated from original non-Latin first name or supplied directly. varchar (not nvarchar) ensures only Latin/ASCII characters stored. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked ALTER COLUMN LastName COMMENT 'Latin-script last name. Transliterated equivalent of the customer''s legal surname. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked ALTER COLUMN ModifiedDate COMMENT 'UTC timestamp of last update. Default = getdate() (table-level), but Customer.SetCustomerLatinName explicitly sets GetUTCDate() on insert and update. Always UTC. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked ALTER COLUMN Address COMMENT 'Latin-script street address. Used for KYC and tax form submissions (W8BEN mailing address). NULL when address was not provided. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked ALTER COLUMN City COMMENT 'Latin-script city name. Complements Address for full mailing address on regulatory forms. NULL when address was not provided. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';
ALTER TABLE main.general.bronze_etoro_customer_customerlatinname_masked ALTER COLUMN MiddleName COMMENT 'Latin-script middle name. Nullable - many naming conventions do not include middle names. Empty string ('''') stored for some accounts where MiddleName was set but empty in the source TVP. (Tier 1 - upstream wiki, etoro.Customer.CustomerLatinName)';

