-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_IFRS15_Daily_Balance
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_IFRS15_Daily_Balance | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Distribution** | ROUND_ROBIN | | **Index** | CLUSTERED INDEX (Date ASC) | | **Writer SP** | BI_DB_dbo.SP_IFRS_15_Balance | | **ETL Pattern** | DELETE WHERE Date + ExcelOrder scope + INSERT (within WHILE loop for 2 days) | | **OpsDB Priority** | 20 | | **Frequency** | Daily | | **Row Estimate** | ~600 - 800 rows/day (20+ metric rows × N instruments × dimension combinations) | | **UC Target** | Not Migrated |'
);

-- ---- Table Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN ExcelOrder COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Metric COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionType COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Date COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN YearMonth COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Name COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionTiming COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TotalUnits COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN USDValue COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN UpdateDate COMMENT 'ETL_METADATA';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsValidCustomer COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsCreditReportValidCB COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsOutlier COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN OutlierTransition COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TanganyStatus COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsDLTUser COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TicketFeeVolume COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsC2P COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsTransferOut COMMENT 'Tier 2';
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Regulation COMMENT 'Tier 2';

-- ---- Column PII Tags ----
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN ExcelOrder SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Metric SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionType SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN YearMonth SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN PositionTiming SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TotalUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN USDValue SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsOutlier SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN OutlierTransition SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TanganyStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN TicketFeeVolume SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsC2P SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN IsTransferOut SET TAGS ('pii' = 'none');
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ifrs15_daily_balance ALTER COLUMN Regulation SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:55:39 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 42/42 succeeded
-- ====================
