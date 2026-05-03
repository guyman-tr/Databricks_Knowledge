-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading > 885-row daily reference table classifying 200 countries across 14 AML/compliance forbidden-trading restriction categories (Rank 1/2 countries, No CFD at all, No real Crypto, No smart portfolio, No copy trader, etc.). Source: AML/Compliance-maintained Google Sheets spreadsheet synced via Fivetran to Azure Data Lake (Silver/SharePoint/forbiddentrading). Refreshed daily by TRUNCATE+INSERT. No date-range columns - this is a current-state classification only. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | AML/Compliance Google Sheets (forbiddentrading) via Fivetran -> Silver/SharePoint | | **Refresh** | Daily - TRUNCATE + INSERT (full rebuild each run) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (CountryID ASC) | | *'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN CountryID COMMENT 'DWH country identifier. NULL when the country has no mapping in Dim_Country. FK to Dim_Country.CountryID where not NULL. Sourced from Google Sheet (country_id, nvarchar) - implicitly cast to int at INSERT. (Tier 2 - SP_CID_Compliance_CID_And_Country_Risk_Lists)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN Country COMMENT 'Country name as entered in the AML/Compliance Google Sheet. Always populated in practice. Use this column for reliable joins when CountryID is NULL. (Tier 2 - SP_CID_Compliance_CID_And_Country_Risk_Lists)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN List COMMENT 'Trading restriction category name. 14 distinct values (see Section 2.2). Note: varchar(500) - wider than other restriction list tables. (Tier 2 - SP_CID_Compliance_CID_And_Country_Risk_Lists)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline (set to GETDATE() at INSERT). Not a business date. (Tier 2 - SP_CID_Compliance_CID_And_Country_Risk_Lists)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN List SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_restriction_lists_forbidden_trading ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:33:07 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 10/10 succeeded
-- ====================
