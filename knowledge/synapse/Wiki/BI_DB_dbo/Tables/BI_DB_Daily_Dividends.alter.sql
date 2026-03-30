-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Daily_Dividends
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Daily_Dividends'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Regulation COMMENT 'Regulation name from Dim_Regulation.Name. NOT NULL. (Tier 2 -- SP_Daily_Dividends, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Date COMMENT 'Calendar date of dividend payment. Clustered index. NOT NULL. (Tier 2 -- SP_Daily_Dividends, @dd)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN InMonthWeekNumber COMMENT 'Week within month: 1 (days 1-7), 2 (8-15), 3 (16-22), 4 (23+). (Tier 2 -- SP_Daily_Dividends, computed from DAY())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Is_US_Stock COMMENT 'Flag: 1 if InstrumentID in BI_DB_US_Stocks. US tax reporting relevance. (Tier 2 -- SP_Daily_Dividends, BI_DB_US_Stocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Instrument_segment COMMENT 'Classification: "Real_Stocks", "Real_ETF", "CFD_Stocks", "CFD_ETF", "Other". Based on InstrumentTypeID, IsSettled, and Regulation. (Tier 2 -- SP_Daily_Dividends, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN ISINCode COMMENT 'ISIN code from Dim_Instrument.ISINCode. International Securities Identification Number. (Tier 2 -- SP_Daily_Dividends, Dim_Instrument.ISINCode)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN InstrumentID COMMENT 'Instrument identifier from Dim_Position.InstrumentID. (Tier 2 -- SP_Daily_Dividends, Dim_Position.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN InstrumentName COMMENT 'Display name from Dim_Instrument.InstrumentDisplayName. (Tier 2 -- SP_Daily_Dividends, Dim_Instrument.InstrumentDisplayName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Symbol COMMENT 'Trading symbol from Dim_Instrument.Name. Values: "AAPL/USD", "ABBV/USD", etc. (Tier 2 -- SP_Daily_Dividends, Dim_Instrument.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Exchange COMMENT 'Exchange name from Dim_Instrument.Exchange. Values: "NYSE", "NASDAQ", "CFD", etc. (Tier 2 -- SP_Daily_Dividends, Dim_Instrument.Exchange)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN DividendPaid COMMENT 'Total dividend amount paid for this instrument on this date. SUM(Dividend) aggregated from Fact_CustomerAction.Amount. (Tier 2 -- SP_Daily_Dividends, Fact_CustomerAction.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp. GETDATE(). (Tier 3 -- SP_Daily_Dividends, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN IsValidCustomer COMMENT 'Customer validity flag from Fact_SnapshotCustomer. (Tier 2 -- SP_Daily_Dividends, Fact_SnapshotCustomer.IsValidCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit report validity flag from Fact_SnapshotCustomer. (Tier 2 -- SP_Daily_Dividends, Fact_SnapshotCustomer.IsCreditReportValidCB)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN InMonthWeekNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Is_US_Stock SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Instrument_segment SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN DividendPaid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_daily_dividends ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 15:59:16 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 30/30 succeeded
-- ====================
