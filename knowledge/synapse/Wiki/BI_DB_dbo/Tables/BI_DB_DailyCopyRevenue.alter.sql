-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DailyCopyRevenue
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DailyCopyRevenue > 7.2M-row daily copy trading revenue table attributing platform spread commissions to Popular Investors (Gurus) by instrument type. Each row = one PI (ParentCID) on one date. Revenue broken down across 7 instrument categories (real stocks, CFD stocks, real/CFD crypto, FX, commodities, indices). Refreshed daily via DELETE+INSERT by SP_CID_DailyCopyRevenue. Not yet migrated to Unity Catalog. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Distribution** | ROUND_ROBIN | | **Index** | HEAP | | **Writer SP** | SP_CID_DailyCopyRevenue | | **Refresh** | DELETE WHERE DateID=@startDateINT + INSERT daily (@date parameter) | | **Row Count** | 7,192,560 rows (2026-04-22 live count) | | **Date Range** | 2020-01-01 to 2026-04-12 (2,294 distinct dates) | | **Distinct PIs** | 58,592 unique ParentCIDs across all dates '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Date COMMENT 'Reporting date (SP @date input parameter). (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN DateID COMMENT 'YYYYMMDD integer of Date - DELETE+INSERT key. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN ParentCID COMMENT 'Popular Investor (Guru) customer ID being copied. Groups all copier revenue by the PI they follow. One row per PI per day. (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN GuruStatusID COMMENT 'Popular Investor status tier ID at @date - from Fact_SnapshotCustomer via #CIDs0. Raw integer; join Dim_GuruStatus for label. Sample values: 0, 4, 5. (Tier 3 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN CountryID COMMENT 'PI''s country of registration ID at @date - from Fact_SnapshotCustomer via #CIDs0. Raw integer; join Dim_Country for country name. (Tier 3 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN AccountTypeID COMMENT 'PI''s account type ID at @date - from Fact_SnapshotCustomer via #CIDs0. Raw integer; join Dim_AccountType for label (e.g., Retail=1, Professional). (Tier 3 - DWH_dbo.Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Copy COMMENT 'Total copy trading revenue for this PI on @date = sum of all instrument-type revenue columns. Includes commissions (3-case UNION) + rollover fees (ActionTypeID=35) + crypto TicketFeeByPercent. (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Real_Stocks COMMENT 'Revenue from real stock copy positions - InstrumentTypeID IN (5,6), Leverage=1, IsBuy=1. Commission + rollover fees. (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_CFD_Stocks COMMENT 'Revenue from CFD stock copy positions - InstrumentTypeID IN (5,6), Leverage>1 OR IsBuy=0 (leveraged or short). Commission + rollover fees. (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Real_Crypto COMMENT 'Revenue from settled (real) crypto copy positions - InstrumentTypeID=10, IsSettled=1. Commission + rollover fees + TicketFeeByPercent (added 2025-10-26). (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_CFD_Crypto COMMENT 'Revenue from CFD crypto copy positions - InstrumentTypeID=10, IsSettled=0. Commission + rollover fees + TicketFeeByPercent (added 2025-10-26). (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_FX COMMENT 'Revenue from FX copy positions - InstrumentTypeID=1. Commission + rollover fees. (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Comm COMMENT 'Revenue from commodities copy positions - InstrumentTypeID=2. Commission + rollover fees. (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Ind COMMENT 'Revenue from indices copy positions - InstrumentTypeID=4. Commission + rollover fees. (Tier 2 - SP_CID_DailyCopyRevenue)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp - GETDATE() at DELETE+INSERT time. (Tier 2 - SP_CID_DailyCopyRevenue)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN ParentCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN GuruStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Copy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Real_Stocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_CFD_Stocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Real_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_CFD_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_FX SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Comm SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN Revenue_Ind SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycopyrevenue ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:35:06 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 32/32 succeeded
-- ====================
