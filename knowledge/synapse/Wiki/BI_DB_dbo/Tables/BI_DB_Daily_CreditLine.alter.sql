-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Daily_CreditLine
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Daily_CreditLine'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN RealCID COMMENT 'Customer ID. Part of clustered index. From previous day''s snapshot or new Fact_CustomerAction. (Tier 2 -- SP_Daily_CreditLine, Fact_CustomerAction.RealCID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN Date COMMENT 'Calendar date. Set from SP @ds parameter. (Tier 2 -- SP_Daily_CreditLine, @ds)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DateID COMMENT 'Date as integer YYYYMMDD. Part of clustered index. (Tier 2 -- SP_Daily_CreditLine, @ds)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN TotalCLAmount COMMENT 'Total credit line amount in USD. Carried forward from previous day + any new credit line actions for today. (Tier 2 -- SP_Daily_CreditLine, accumulated)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN MonthlyTableFeeCost COMMENT 'Monthly fee based on credit line tier from BI_DB_CreditLine_Amounts lookup. NULL if credit line amount not in tier table. (Tier 2 -- SP_Daily_CreditLine, BI_DB_CreditLine_Amounts.Cost)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DailyFee COMMENT 'Daily fee: `MonthlyTableFeeCost / DAY(EOMONTH(@ds))`. Pro-rated by days in the month. (Tier 2 -- SP_Daily_CreditLine, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN Liabilities COMMENT 'Customer''s total liabilities from V_Liabilities on this date. Used for CLRatio calculation. (Tier 2 -- SP_Daily_CreditLine, V_Liabilities.Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN CLRatio COMMENT 'Credit line to liability ratio: `TotalCLAmount / Liabilities`. Division-by-zero protected (denominator defaults to 1). (Tier 2 -- SP_Daily_CreditLine, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN IsExceeded COMMENT 'Flag: 1 if `CLRatio > 0.5` (credit line exceeds 50% of liabilities). Risk threshold indicator. (Tier 2 -- SP_Daily_CreditLine, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN ExceedingDaysCount COMMENT 'Consecutive days the credit line has been exceeded. Incremented from previous day if still exceeded, 0 if not. (Tier 2 -- SP_Daily_CreditLine, accumulated)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DateReceive COMMENT 'Date the credit line was received. Only set on the day of the credit line action; NULL otherwise. (Tier 2 -- SP_Daily_CreditLine, Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DateDeduct COMMENT 'Date the credit line was deducted. Only set on the day of the deduction action; NULL otherwise. (Tier 2 -- SP_Daily_CreditLine, Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp. GETDATE(). (Tier 3 -- SP_Daily_CreditLine, GETDATE())';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN TotalCLAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN MonthlyTableFeeCost SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DailyFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN Liabilities SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN CLRatio SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN IsExceeded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN ExceedingDaysCount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DateReceive SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN DateDeduct SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_creditline ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 15:59:05 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 28/28 succeeded
-- ====================
