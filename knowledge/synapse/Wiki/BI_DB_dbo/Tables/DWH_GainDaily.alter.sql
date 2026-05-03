-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.DWH_GainDaily
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.DWH_GainDaily > 6.25B-row daily multi-horizon portfolio gain table storing compound returns (daily, weekly, monthly, quarterly, half-yearly, yearly, MTD, YTD, QTD) for every customer - pivoted from the TradeGain Ranking service''s External_TradeGain_Ranking_Compound_Gain_Completed table, covering Jan 2013 to present. The largest table in BI_DB_dbo. Refreshed daily by SP_DWH_GainDaily via DELETE+INSERT by Date. Not migrated to Unity Catalog. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_GainDaily` from External_TradeGain_Ranking_Compound_Gain_Completed | | **Refresh** | Daily - DELETE WHERE Date=@gain_dt + INSERT. Accumulating by date. | | **Synapse Distribution** | HASH(CID) | | **Synapse Index** | HEAP (PK on Date, CID - NOT ENFORCED) | | **UC Target** | `_Not_Migrated'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Date COMMENT 'Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN CID COMMENT 'Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_w COMMENT 'Trailing 7-day (weekly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=7 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_m COMMENT 'Trailing 30-day (monthly) compound portfolio return as a decimal. IntervalTypeID=106 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_q COMMENT 'Trailing 90-day (quarterly) compound portfolio return as a decimal. IntervalTypeID=108 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_h COMMENT 'Trailing 180-day (half-yearly) compound portfolio return as a decimal. IntervalTypeID=109 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_y COMMENT 'Trailing 365-day (yearly) compound portfolio return as a decimal. IntervalTypeID=110 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was inserted by SP_DWH_GainDaily. (Tier 5 - ETL infrastructure)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_MTD COMMENT 'Month-to-date compound portfolio return as a decimal. From first of current month to Date. IntervalTypeID=101 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_YTD COMMENT 'Year-to-date compound portfolio return as a decimal. From Jan 1 to Date. IntervalTypeID=103 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_d COMMENT 'Daily compound portfolio return as a decimal. Single-day gain for this Date. IntervalTypeID=1 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_QTD COMMENT 'Quarter-to-date compound portfolio return as a decimal. From first of current quarter to Date. IntervalTypeID=102 from TradeGain service. (Tier 2 - SP_DWH_GainDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN ExecutionID COMMENT 'TradeGain Ranking service execution ID that produced these gains. Links to External_TradeGain_Ranking_Execution. Multiple executions may exist per date; SP uses the latest completed one (ObjectID=4). (Tier 2 - SP_DWH_GainDaily)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_w SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_m SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_q SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_h SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_y SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_MTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_YTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_d SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN Gain_QTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dwh_gaindaily ALTER COLUMN ExecutionID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:18:00 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 28/28 succeeded
-- ====================
