-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_dbo.Dealing_NumberofPositionsOpened_Agg
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg SET TBLPROPERTIES (
    'comment' = 'Daily aggregate counting the number of positions opened, broken down by instrument type and geographic region. Serves as a high-level summary of trading activity for the Dealing Dashboard. | Property | Value | |----------|-------| | **Schema** | Dealing_dbo | | **Object Type** | Table | | **Distribution** | ROUND_ROBIN | | **Index** | Clustered (DateID ASC) | | **Row Count** | ~173K | | **Date Range** | 2022-01-01 -> present | | **Grain** | One row per DateID × InstrumentType × Region | | **Refresh** | Daily, via SP_DealingDashboard_Clients |'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg SET TAGS (
    'domain' = 'trading',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN DateID COMMENT 'Business date in YYYYMMDD integer format';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Date COMMENT 'Calendar date corresponding to DateID';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN InstrumentType COMMENT 'Asset class name (e.g., Stocks, ETF, Indices, Commodities, Currencies, Crypto)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Region COMMENT 'Geographic region label (21 distinct values, e.g., "Western Europe", "South & Central America", "Africa")';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN NumberOfPositionsOpened COMMENT 'Total count of positions opened for this InstrumentType + Region combination on the given date. Formula: `SUM(dddc.NumberOfPositionsOpened)`';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN UpdateDate COMMENT 'Timestamp when the row was written. Formula: `GETDATE()`';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN NumberOfPositionsOpened SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 13:59:38 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 14/14 succeeded
-- ====================
