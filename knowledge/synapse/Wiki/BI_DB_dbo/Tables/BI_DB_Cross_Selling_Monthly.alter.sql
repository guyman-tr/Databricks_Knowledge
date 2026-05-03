-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Cross_Selling_Monthly
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Cross_Selling_Monthly > 145.4M-row end-of-month cross-selling product-holdings snapshot for all active depositors (5.07M distinct CIDs across history). Monthly EOM-only sibling of BI_DB_Cross_Selling_Daily - captures product type usage per customer per end-of-month date across 8 categories. Hold columns carry the EOM suffix to signal point-in-time end-of-month state. ActiveOpen lookback = 2 months (despite "3M" in column names). Data spans January 2017 to March 2026 (111 months). Built by SP_Cross_Selling_Monthly. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Dim_Position + Dim_Mirror + V_Liabilities + Fact_SnapshotCustomer via SP_Cross_Selling_Monthly | | **Refresh** | Monthly EOM only - SP aborts unless @date = EOMONTH(@date). DELETE WHERE DateKey=@date_int + INSERT. | | **Synapse Distr'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN DateKey COMMENT 'ETL date integer (YYYYMMDD) for the end-of-month reporting date. Derived as CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Always last day of a calendar month. Used for incremental DELETE+INSERT. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN FullDate COMMENT 'End-of-month reporting date (e.g., 2026-03-31). Matches @date parameter passed to SP. Always a month-end date. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID. (Tier 1 - DWH_dbo.Dim_Customer wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Country COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dim_Country wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Region COMMENT 'Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. (Tier 3 - Dim_Country.MarketingRegionManualName via Ext_Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN EOM_Club COMMENT 'eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000 - Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. Distribution on 2026-04-11: LowBronze 53%, HighBronze 18%, Silver 10%, Gold 9%, Platinum 5%, Platinum+ 4%, Diamond <1%. (Tier 1 - DWH_dbo.Dim_PlayerLevel wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN ClusterDetail COMMENT 'Customer behaviour cluster name from BI_DB_CID_DailyCluster (e.g., ''Equities Crypto''). NULL for unclustered customers. (Tier 2 - BI_DB_CID_DailyCluster)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN ETF_HoldEOM COMMENT '1 if customer has at least one open ETF position (InstrumentTypeID=6, IsSettled=1, MirrorID=0) at the end-of-month date; 0 otherwise. Renamed from ETF_Hold (daily) to ETF_HoldEOM to signal EOM snapshot semantics. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Smart_Portfolios_HoldEOM COMMENT '1 if customer has at least one open CopyPortfolio mirror (Dim_Mirror.MirrorTypeID=4) at the end-of-month date; 0 otherwise. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Copy_Trader_HoldEOM COMMENT '1 if customer has at least one open Copy Trader mirror (Dim_Mirror.MirrorTypeID != 4) at the end-of-month date; 0 otherwise. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN CFD_ActiveOpen3M COMMENT 'Count (not binary) of CFD positions (IsSettled=0, MirrorID=0) opened by this customer in the prior 2-month window (DATEADD(month,-2,EOM_start)..@date_int). Despite the "3M" name, this uses a 2-month lookback in the monthly SP. Can be >1. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Real_Crypto COMMENT '1 if customer holds an open real crypto position (InstrumentTypeID=10, IsSettled=1) at EOM OR opened one in the prior 2-month window; 0 otherwise. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Real_Non_US_Stocks COMMENT '1 if customer holds or recently opened real non-US stock positions (InstrumentTypeID=5, IsSettled=1, Exchange not in US exchanges) at EOM OR in prior 2M; 0 otherwise. US exchanges = ''Chicago Board Options Exchange'', ''NYSE'', ''Nasdaq'', ''OTC Markets Stock Exchange''. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Real_US_Stocks COMMENT '1 if customer holds or recently opened real US stock positions (InstrumentTypeID=5, IsSettled=1, Exchange IN US exchanges) at EOM OR in prior 2M; 0 otherwise. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN eMoney_ActiveOpen3M COMMENT '1 if customer executed an eToro Money IBAN trade (Fact_CustomerAction.ActionTypeID=44) in the prior 2-month window, restricted to ValidETM accounts (eMoney_Dim_Account.IsValidETM=1, GCID_Unique_Count=1). Only populated for activity from 2024-04-01 onwards; pre-April 2024 EOM rows always 0. Despite "3M" name, uses 2-month window. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Total_Products COMMENT 'Sum of all 8 product engagement indicators: ETF_HoldEOM + Smart_Portfolios_HoldEOM + Copy_Trader_HoldEOM + CFD_ActiveOpen3M + Real_Crypto + Real_Non_US_Stocks + Real_US_Stocks + eMoney_ActiveOpen3M. Range: 1 - 8 (Total_Products=0 rows excluded from INSERT). March 2026: 1 product (54%), 2 (24%), 3 (13%), 4 (6%), 5+ (3%). CFD_ActiveOpen3M is an int - can inflate this sum. (Tier 2 - SP_Cross_Selling_Monthly)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Propagation)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN DateKey SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN EOM_Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN ClusterDetail SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN ETF_HoldEOM SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Smart_Portfolios_HoldEOM SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Copy_Trader_HoldEOM SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN CFD_ActiveOpen3M SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Real_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Real_Non_US_Stocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Real_US_Stocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN eMoney_ActiveOpen3M SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN Total_Products SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cross_selling_monthly ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:33:30 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 36/36 succeeded
-- ====================
