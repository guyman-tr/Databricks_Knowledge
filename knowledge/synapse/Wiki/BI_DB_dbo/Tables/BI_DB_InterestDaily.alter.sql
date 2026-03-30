-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_InterestDaily
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_InterestDaily > Daily per-customer interest accrual record from the eToro Club "Interest on Balance" programme - stores the computed daily interest amount, eligible funds, applicable rates, and customer context for each interest-eligible customer per day. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (Fact - daily snapshot) | | **Production Source** | Interest DB: `interest-west.database.windows.net` -> `Interest.Trade.InterestDaily` | | **Refresh** | Daily - DELETE for @date + INSERT via external table (SP_InterestDaily @date) | | | | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (DateID ASC) | | | | | **UC Target** | _Pending - resolved during write-objects_ | | **UC Format** | _Pending - resolved during write-objects_ | | **UC Partitioned By** | _Pending - resolved during write-objects_ '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN CID COMMENT 'Customer ID. Passthrough from Interest.Trade.InterestDaily. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DailyInterest COMMENT 'Computed daily interest amount in USD for the customer. FundsForInterest × DailyInterestPercentage. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN FundsForInterest COMMENT 'Eligible balance for interest calculation - cash available after deducting pending cashouts, credit adjustments, and bonus. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DailyInterestPercentage COMMENT 'Daily interest rate applied (≈ YearlyInterestPercentage / 365). (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DayOfInterest COMMENT 'The calendar date for which interest was calculated. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DateID COMMENT 'YYYYMMDD integer from DayOfInterest. Clustered index key - always filter on this. ETL-computed: CONVERT(VARCHAR, DayOfInterest, 112). (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN CountryID COMMENT 'Customer''s country at the time of interest calculation. FK to Dim_Country. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN PlayerLevelID COMMENT 'eToro Club tier at calculation time (Bronze=1, Silver=2, Gold=3, Platinum=4, etc.). Determines the interest rate. FK to Dim_PlayerLevel. (Tier 4 - [UNVERIFIED])';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN AccountTypeID COMMENT 'Account type at calculation time. FK to Dim_AccountType. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN RegulationID COMMENT 'Regulatory jurisdiction at calculation time (EU, FSA, ASIC, US, FSRA). FK to Dim_Regulation. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN Interest COMMENT 'Accumulated interest amount. Meaning requires clarification - may be month-to-date running total or total accrued. (Tier 4 - [UNVERIFIED])';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN MinRealMoney COMMENT 'Minimum real money balance threshold for interest eligibility. (Tier 4 - [UNVERIFIED])';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN SumOfPendingCashoutRequests COMMENT 'Total pending cashout/withdrawal requests at calculation time. Reduces eligible funds for interest. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN Credit COMMENT 'Credit balance on the account at calculation time. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN RealizedEquity COMMENT 'Realized equity at calculation time. The base value from which eligible funds are derived. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN Bonus COMMENT 'Bonus amount on the account at calculation time. Excluded from interest-eligible balance. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN YearlyInterestPercentage COMMENT 'Annual interest rate percentage for the customer''s club tier. Determines DailyInterestPercentage. (Tier 2 - SP_InterestDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN StatusID COMMENT 'Customer status at calculation time. FK to status dimension. (Tier 4 - [UNVERIFIED])';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN MonthlyTaxPercentage COMMENT 'Tax rate applied to the monthly interest payment. Varies by regulation/jurisdiction. (Tier 4 - [UNVERIFIED])';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE(). (Tier 2 - SP_InterestDaily)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DailyInterest SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN FundsForInterest SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DailyInterestPercentage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DayOfInterest SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN Interest SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN MinRealMoney SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN SumOfPendingCashoutRequests SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN Bonus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN YearlyInterestPercentage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN MonthlyTaxPercentage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_interestdaily ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 16:06:14 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 42/42 succeeded
-- ====================
