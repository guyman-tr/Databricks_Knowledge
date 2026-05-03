-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_AML_SubEntity_Categorization
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_AML_SubEntity_Categorization > 2.11M-row daily snapshot table classifying every verified depositor customer into one or more AML sub-entities (eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta) based on their KYC country, regulation, and eToro Money account type. Rebuilt daily via TRUNCATE+INSERT from DWH_dbo dimensions and eMoney account data. Last updated 2026-04-13. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country + DWH_dbo.Dim_Regulation + eMoney_dbo.eMoney_Dim_Account via SP_AML_SubEntity_Categorization | | **Refresh** | Daily (SB_Daily, Priority 20). TRUNCATE + INSERT - full rebuild every run. | | **Synapse Distribution** | HASH(CID) | | **Synapse Index** | CLUSTERED INDEX (CID ASC) | | **UC Target** | `compliance.gold_sql_dp_prod_we_b'
);

-- ---- Table Tags ----
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer (RealCID). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN GCID COMMENT 'Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN CountryID COMMENT 'Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer via Dim_Country.DWHCountryID=CountryID identity. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN Country COMMENT 'Country name, denormalized from DWH_dbo.Dim_Country.Name. Matches CountryID. Included to avoid join in downstream AML reports. (Tier 2 - SP_AML_SubEntity_Categorization)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN RegulationID COMMENT 'Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. In this table: 1=CySEC, 2=FCA, 4=ASIC, 9=FSA Seychelles, 10=ASIC&GAML only (other regulations are excluded by SP eligibility criteria). (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN Regulation COMMENT 'Regulation name, denormalized from DWH_dbo.Dim_Regulation.Name. Matches RegulationID. (Tier 2 - SP_AML_SubEntity_Categorization)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. All rows share the same timestamp per daily run (single TRUNCATE+INSERT batch). (Tier 2 - SP_AML_SubEntity_Categorization)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN VerificationLevelID COMMENT 'KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Only VerLevel >= 2 customers are in this table; 99.999% are VerLevel=3. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN AML_Sub_Entity COMMENT 'ETL-computed comma-separated list of eToro AML sub-entities this customer qualifies for. Possible values (may be combined): eToro_Germany, eToro_Gibraltar, eToro_Money_UK, eToro_Money_Malta. NULL if no entity label applies. Use LIKE ''%value%'' for filtering. (Tier 2 - SP_AML_SubEntity_Categorization)';

-- ---- Column PII Tags ----
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN VerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_subentity_categorization ALTER COLUMN AML_Sub_Entity SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:23:22 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 20/20 succeeded
-- ====================
