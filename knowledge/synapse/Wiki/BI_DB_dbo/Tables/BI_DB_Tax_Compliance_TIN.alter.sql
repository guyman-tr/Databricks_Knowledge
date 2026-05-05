-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Tax_Compliance_TIN
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Tax_Compliance_TIN > 8.08M-row tax compliance table tracking Tax Identification Number (TIN) data for every eToro customer who has submitted a tax ID (FieldId=6), with per-country deduplication, sourced from UserApiDB.Customer.ExtendedUserField via SP_Tax_Compliance_W8_AND_TIN. Covers TIN submissions from 2017-12-22 to present. Daily UPDATE refresh. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | UserApiDB.Customer.ExtendedUserField (primary, FieldId=6) via SP_Tax_Compliance_W8_AND_TIN | | **Refresh** | Daily (UPDATE on matched CID+TIN_CountryID via OpsDB Service Broker, Priority 0) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (CID ASC) | | **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin` | | **UC Format** | delta | | **UC Partitio'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer (RealCID renamed to CID). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_CountryID COMMENT 'Country context for this TIN field value. Allows per-country field values. Renamed from ExtendedUserField.CountryId. FK to Dim_Country. (Tier 1 - UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_CountryName COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_Value COMMENT 'The user-provided value for this field (e.g., the actual tax number, national PIN). DWH note: SP converts empty/single-char values to the string ''Null''. (Tier 1 - UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN NoTIN_ReasonID COMMENT 'ETL-computed from ExtendedUserField.AdditionalDetails JSON. Parses `{"noTaxIdReason":N}` to extract the first digit as the reason code. 0=TIN provided or parse failure. 1=Unable to obtain, 2=Not required by authorities, 3=Country doesn''t issue, 4=Not legally required, 5=Diplomat/UN. (Tier 2 - SP_Tax_Compliance_W8_AND_TIN)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN NoTIN_Reason COMMENT 'User-facing description of the reason, displayed in the KYC form. DWH note: NULL values from KYC.ReasonsForNoTaxID are replaced with ''TIN Information Displayed''. 0=TIN Information Displayed, 1=I''m unable to obtain a TIN or equivalent number, 2=The authorities in my tax residency don''t require disclosure of TIN, 3=The country doesn''t issue TIN, 4=I''m not legally required to have TIN or functional equivalent, 5=I am Diplomat/UN employee or spouse/dependent. (Tier 1 - UserApiDB.KYC.ReasonsForNoTaxID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN IsTIN_Mandatory COMMENT 'Requirement level label used in admin configuration tools. Resolved via KYC.CountryTaxType.TaxIdRequirmentTypeId -> Dictionary.MandatoryType.Name. Values: ''Mandatory'', ''Optional'', or NULL/empty. (Tier 1 - UserApiDB.Dictionary.MandatoryType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_UpdateDateTime COMMENT 'When this field value was last updated. Passthrough from ExtendedUserField.LastModified. (Tier 1 - UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_UpdateDate COMMENT 'ETL-computed date truncation of TIN_UpdateDateTime. CAST(LastModified AS DATE). (Tier 2 - SP_Tax_Compliance_W8_AND_TIN)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_UpdateDateID COMMENT 'ETL-computed YYYYMMDD integer from TIN_UpdateDateTime. CAST(CONVERT(CHAR(8), LastModified, 112) AS INT). (Tier 2 - SP_Tax_Compliance_W8_AND_TIN)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN RN_TIN_CID_Country COMMENT 'ROW_NUMBER() OVER(PARTITION BY GCID, CountryID ORDER BY LastModified DESC). Deduplication rank - 1=most recent TIN per customer per country. Filter on RN=1 for current data. (Tier 2 - SP_Tax_Compliance_W8_AND_TIN)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN FieldID COMMENT 'FK to Dictionary.ExtendedUserField. Identifies which field: 0=province, 6=TaxId, 7=NationalPin, etc. Always 6 (TaxId) in this table. (Tier 1 - UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TypeID COMMENT 'Value subtype. Maps to Dictionary.ExtendedUserValueType for further classification (e.g., which specific type of tax ID). 24 distinct values observed. (Tier 1 - UserApiDB.Customer.ExtendedUserField)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TypeIDName COMMENT 'Value subtype name. camelCase for tax IDs (taxCPR), PascalCase for national PINs (NationalNumber). Dim-lookup passthrough from Dictionary.ExtendedUserValueType.Name. Top values: taxID (3.95M), SocialSecurityNumber (1.36M), taxUTR (1.35M), taxTFN (275K). (Tier 1 - UserApiDB.Dictionary.ExtendedUserValueType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 - ETL metadata)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_CountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_Value SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN NoTIN_ReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN NoTIN_Reason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN IsTIN_Mandatory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_UpdateDateTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TIN_UpdateDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN RN_TIN_CID_Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN FieldID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN TypeIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:34:53 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 10
-- Statements: 34/34 succeeded
-- ====================
