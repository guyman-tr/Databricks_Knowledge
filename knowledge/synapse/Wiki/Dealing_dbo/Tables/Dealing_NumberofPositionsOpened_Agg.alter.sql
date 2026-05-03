-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_NumberofPositionsOpened_Agg
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg SET TBLPROPERTIES (
    'comment' = 'Dealing_dbo.Dealing_NumberofPositionsOpened_Agg > 178K-row daily aggregation of positions opened, grouped by instrument type and marketing region -- a lightweight summary of Dealing_DealingDashboard_Clients used for high-level dealing desk trend analysis. Data from 2022-01-01 to present, refreshed daily by SP_DealingDashboard_Clients. | Property | Value | |----------|-------| | **Schema** | Dealing_dbo | | **Object Type** | Table | | **Production Source** | Derived - aggregation of Dealing_dbo.Dealing_DealingDashboard_Clients (which itself derives from Dim_Position + BI_DB_PositionPnL + customer/instrument dimensions) | | **Refresh** | Daily via SP_DealingDashboard_Clients (DELETE + INSERT for @DateID) | | | | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (DateID ASC) | | | | | **UC Target** | `bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofposit'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg SET TAGS (
    'source_schema' = 'Dealing_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN DateID COMMENT 'Snapshot date as YYYYMMDD integer. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. Range: 20220101 to present. Clustered index column. (Tier 2 - Dealing_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Date COMMENT 'Reporting calendar date. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. (Tier 2 - Dealing_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN InstrumentType COMMENT 'Asset class label: Currencies, Commodities, Indices, Stocks, ETF, Crypto Currencies. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Instrument.InstrumentType (CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies). (Tier 2 - Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Region COMMENT 'Marketing region label. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Country.Region (loaded from Dictionary.MarketingRegion.Name). 21 distinct values including USA, UK, Spain, ROW, ROE, Africa, etc. (Tier 2 - Dim_Country)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN NumberOfPositionsOpened COMMENT 'Total count of positions opened on this date for this InstrumentType and Region. SUM aggregation from Dealing_DealingDashboard_Clients.NumberOfPositionsOpened, which excludes partial close children (IsPartialCloseChild=1). (Tier 2 - Dealing_DealingDashboard_Clients)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() at insert time by SP_DealingDashboard_Clients. Not a business date. (Tier 2 - SP_DealingDashboard_Clients)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN NumberOfPositionsOpened SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:20:36 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 9
-- Statements: 14/14 succeeded
-- ====================
