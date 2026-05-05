-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_PLTV
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_PLTV > 5.9K-row predicted Lifetime Value (PLTV) lookup table by country, age bucket, and KYC questionnaire answers. Two-part UNION: granular predictions (country + age + Q11 + MAX(Q33/Q35)) from 2-8 month FTD cohort, plus regional fallback averages by MarketingRegion. TRUNCATE+INSERT via SP_BI_DB_PLTV. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | BI_DB_dbo.BI_DB_LTV_BI_Actual + BI_DB_KYC_Score_CID_Level + BI_DB_KYC_Panel + DWH_dbo.Dim_Customer via `SP_BI_DB_PLTV` | | **Refresh** | Daily (TRUNCATE+INSERT, no date parameter) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP | | **UC Target** | `_Not_Migrated` | | **UC Format** | - | | **UC Partitioned By** | - | | **UC Table Type** | - | | **Author** | Nitsan Sharabi (2024-05-03) | | **Row Count** | ~5,915 (as of 2026-04-01) '
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN CountryID COMMENT 'Country identifier. FK to Dim_Country.CountryID. In Part 1: direct from Dim_Country via customer''s CountryID. In Part 2: from Dim_Country joined via MarketingRegionManualName. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN Min_Age COMMENT 'Lower bound of the age-at-registration bucket. Values: 18, 27, 35, or 999 (regional fallback). (Tier 2 - SP_BI_DB_PLTV)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN Max_Age COMMENT 'Upper bound of the age-at-registration bucket. Values: 26, 35, 999 (999 = no upper limit or regional fallback). (Tier 2 - SP_BI_DB_PLTV)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN Q11_AnswerID COMMENT 'KYC questionnaire Q11 answer ID from BI_DB_KYC_Panel. Segmentation dimension for financial knowledge. 999 = regional fallback. (Tier 2 - SP_BI_DB_PLTV, BI_DB_KYC_Panel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN `MaxQ33/MaxQ35` COMMENT 'Maximum of Q33_AnswerID and Q35_AnswerID from BI_DB_KYC_Panel. Financial literacy segmentation. 999 = regional fallback or ELSE branch. (Tier 2 - SP_BI_DB_PLTV, BI_DB_KYC_Panel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN LeadScore COMMENT 'DEPRECATED - always NULL since 2024-10-25 removal. Column retained in DDL but no longer populated. (Tier 2 - SP_BI_DB_PLTV)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN PLTV COMMENT 'Predicted Lifetime Value in USD. Part 1: SUM(Revenue8Y_LTV_New)/COUNT(RealCID) for the segment. Part 2: AVG(Revenue8Y_LTV_New) by marketing region. (Tier 2 - SP_BI_DB_PLTV, BI_DB_LTV_BI_Actual)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN updateDate COMMENT 'ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 - SP_BI_DB_PLTV)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN Min_Age SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN Max_Age SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN Q11_AnswerID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN `MaxQ33/MaxQ35` SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN LeadScore SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN PLTV SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pltv ALTER COLUMN updateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:34:18 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 10
-- Statements: 18/18 succeeded
-- ====================
