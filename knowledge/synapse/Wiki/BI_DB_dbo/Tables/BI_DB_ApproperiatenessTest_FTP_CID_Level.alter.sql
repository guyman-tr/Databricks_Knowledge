-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level > 1,052,545-row customer-level appropriateness test (AT) popup interaction summary, tracking how many times each customer was shown the AT popup, whether they completed the FTP (First Time Pass) process, and their overall appropriateness status. Sourced from ComplianceStateDB (Compliance.CustomerInteractionActionCounts + CustomerInteractions + UserInteractionDetails, UserInteractionTypeId=4/UserInteractionId=22) and SettingsDB (FTP completion, ResourceId=5907/SelectedValue=''2''). Refreshed daily via TRUNCATE+INSERT. Date range: FirstInteractionDate 2022-04-03 to 2026-04-13. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | ComplianceStateDB.Compliance.CustomerInteractionActionCounts + CustomerInteractions + UserInteractionDetails; SettingsDB.Settings.CustomerData (FT'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN GCID COMMENT 'Global Customer ID - the customer identifier used in ComplianceStateDB. Imported from ComplianceStateDB.Compliance.CustomerInteractions. Links to GCID in other compliance system tables. (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN RealCID COMMENT 'Real Customer ID - the eToro platform customer identifier. Distribution key. Sourced via JOIN to BI_DB_Scored_Appropriateness_Negative_Market on GCID; maps the ComplianceStateDB GCID to the DWH RealCID. FK to DWH_dbo.Dim_Customer.RealCID. (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN PopUpsCount COMMENT 'Total number of times the appropriateness test popup was displayed to this customer (CustomerInteractionActionCounts.Count). Aggregated across all sessions. Value range from sample: 1 - 18+ (some customers are shown the popup many times before completing FTP). (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN FirstInteractionDate COMMENT 'Timestamp of the customer''s first appropriateness test popup interaction, from ComplianceStateDB.Compliance.CustomerInteractionActionCounts.FirstInteractionDate. Range: 2022-04-03 to 2026-04-13. (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN LastInteractionDate COMMENT 'Timestamp of the customer''s most recent appropriateness test popup interaction, from ComplianceStateDB.Compliance.CustomerInteractionActionCounts.LastInteractionDate. Equals FirstInteractionDate when PopUpsCount=1. (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN HasCompletedFTP COMMENT 'Binary flag indicating whether the customer has completed the First Time Pass (FTP) process: 1=completed (787,902; 74.9%), 0=not completed (264,643; 25.1%). Derived: 1 if customer has a SettingsDB.Settings.CustomerData record with ResourceId=5907 and SelectedValue=''2''; 0 if no such record exists (LEFT JOIN NULL check). (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN CompletionFTPDate COMMENT 'Date the customer completed the FTP process, from SettingsDB.Settings.CustomerData.BeginDate (ResourceId=5907, SelectedValue=''2''). NULL when HasCompletedFTP=0 (264,643 NULLs). (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN DaysFromFirstToLast COMMENT 'Number of days between FirstInteractionDate and LastInteractionDate: DATEDIFF(DAY, FirstInteractionDate, LastInteractionDate). Value of 0 means first and last interaction were on the same day. No NULLs observed. (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN ApproprietnessScore_Status COMMENT 'Appropriateness test outcome. From ComplianceStateDB Dictionary.RestrictionStatus.Name, filtered to RestrictionStatusReasonID=14. Values: "Failed" (majority), "Passed", "Borderline Pass" (rare), NULL. Note: column name contains typo ("Approprietness" vs "Appropriateness"). Passthrough from BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market. (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level, join-enriched via BI_DB_Scored_Appropriateness_Negative_Market)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN AT_Date COMMENT 'Date the Appropriateness Test was taken. From ComplianceStateDB.Compliance.CustomerRestrictions.BeginTime. NULL for ~3% of customers (31,542 NULLs). Passthrough from BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market. (Tier 2 - SP_BI_DB_ApproperiatenessTest_FTP_CID_Level, join-enriched via BI_DB_Scored_Appropriateness_Negative_Market)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time during daily TRUNCATE+INSERT. (Propagation)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN PopUpsCount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN FirstInteractionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN LastInteractionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN HasCompletedFTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN CompletionFTPDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN DaysFromFirstToLast SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN ApproprietnessScore_Status SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN AT_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_approperiatenesstest_ftp_cid_level ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-05 13:31:44 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 10
-- Statements: 24/24 succeeded
-- ====================
