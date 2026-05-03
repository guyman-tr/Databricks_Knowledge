-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_InvestorsDetail
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_InvestorsDetail'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN Date COMMENT 'Calendar date of the trade or copy-investment event. CAST(Fact_CustomerAction.Occurred AS DATE). (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN DateID COMMENT 'Integer date key (YYYYMMDD format). Clustered index key. Derived from Fact_CustomerAction.DateID. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN RealCID COMMENT 'Customer ID who performed the trade or copy action. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN InstrumentType COMMENT 'Asset class of the traded instrument. Manual: Dim_Instrument.InstrumentType (Stocks, Commodities, Currencies, Indices, Crypto Currencies, ETF). Copy: ''Copy Trading'' (MirrorTypeID 1/2) or ''Copy Portfolio'' (MirrorTypeID 4). (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN ParentUserName COMMENT '**DUAL SOURCE**: For Manual rows, holds Dim_Instrument.InstrumentDisplayName (instrument name, e.g., ''Bitcoin'', ''Oil (Non Expiry)''). For Copy rows, holds Dim_Mirror.ParentUserName (Popular Investor''s username). Always filter on ActionType before interpreting this column. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN ActionType COMMENT 'Pipeline type: ''Manual'' (position opened/closed directly) or ''Copy'' (copy investment start/stop/add/clear). (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN AssetType COMMENT 'Classification of the action''s economic nature. ''Investment'': low-leverage Manual positions (InstrumentTypeID IN 4,5,6 AND Leverage<3), or all Copy actions. ''Trade'': all other Manual positions. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN MoneyOut COMMENT 'Total USD amount out (withdrawals/closes). Manual: ActionTypeID=4 (close). Copy: ActionTypeID IN (16,18) (stop/clear). Zero if no qualifying action on Date. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN MoneyIn COMMENT 'Total USD amount in (deposits/opens). Manual: (-1×Amount) for ActionTypeID=1 (open). Copy: (-1×Amount) for ActionTypeID IN (15,17) (start/add). The -1 reverses the negative sign convention in Fact_CustomerAction. Zero if no qualifying action. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN DaysContacted COMMENT 'Minimum days elapsed between the account manager''s most recent contact (phone or email, from BI_DB_UsageTracking_SF) and the trade date. Lookback window: 90 days. NULL if no contact in 90 days (~87% of rows). (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN AccountManagerID COMMENT 'ID of the account manager responsible for this customer at the time of the trade. Sourced from Fact_SnapshotCustomer at @date. FK to DWH_dbo.Dim_Manager. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN CountryID COMMENT 'Customer''s country of registration at @date. Integer FK to DWH_dbo.Dim_Country - join for country name. Sourced from Fact_SnapshotCustomer. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN UpdateDate COMMENT 'ETL run timestamp. Set to GETDATE() at INSERT time. (Tier 3 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN DaysContactedPhone COMMENT 'Same as DaysContacted but restricted to phone contacts only (ActionName=''Phone_Call_Succeed__c''). NULL if no phone contact in the 90-day window (~91% of rows). (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN IsDepositor COMMENT 'Whether the customer has ever deposited (1=yes, 0=no). Sourced from Fact_SnapshotCustomer.IsDepositor at @date. (Tier 2 - SP_InvestorReportDetails)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN Club COMMENT 'Customer VIP/experience tier. Standard Dim_PlayerLevel names (Silver, Gold, Platinum, Platinum Plus, Diamond) plus sub-divided Bronze: ''Low Bronze'' (Bronze AND portfolio<$1K) or ''High Bronze'' (Bronze AND portfolio >= $1K). Distribution (2026 YTD): Low Bronze 20.6%, Gold 17.8%, Platinum Plus 15.4%, Platinum 15.0%, High Bronze 14.3%, Silver 13.5%, Diamond 3.1%. (Tier 2 - SP_InvestorReportDetails)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN ParentUserName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN ActionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN AssetType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN MoneyOut SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN MoneyIn SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN DaysContacted SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN AccountManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN DaysContactedPhone SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN IsDepositor SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_investorsdetail ALTER COLUMN Club SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:56:16 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 34/34 succeeded
-- ====================
