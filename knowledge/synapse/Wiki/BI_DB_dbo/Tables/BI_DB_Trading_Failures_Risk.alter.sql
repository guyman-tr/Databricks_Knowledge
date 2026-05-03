-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Trading_Failures_Risk
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Trading_Failures_Risk > 27.7M-row trading execution monitoring table tracking both failed and succeeded position open/close events aggregated by date, instrument, error code, leverage type, copy/manual, direction, hedge server, and regulation. Sourced from Dealing_staging.PositionFail + DWH_dbo.Dim_Position via SP_Trading_Failures_Risk. Covers April 2024 to present. Daily DELETE+INSERT refresh. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Dealing_staging.PositionFailReal_History_PositionFail_DWH (failures) + DWH_dbo.Dim_Position (succeeds) via SP_Trading_Failures_Risk (author: Artyom Bogomolsky, 2024-08-14) | | **Refresh** | Daily (DELETE+INSERT by @Date via OpsDB Service Broker, Priority 0) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | HEAP | | **UC Target** | `trading.gold'
);

-- ---- Table Tags ----
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Date COMMENT 'Event date. Failures: CAST(FailOccurred AS DATE). Succeeds: CAST(OpenOccurred/CloseOccurred AS DATE). Used as partition key for DELETE+INSERT. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN ErrorCode COMMENT 'Execution error code. Failures: actual error code from PositionFail (e.g., 954, 1072). Succeeds: -1 (sentinel meaning success). Excludes noise codes 1043, 1044. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN InstrumentID COMMENT 'Unique identifier for a tradeable financial instrument. FK to Dim_Instrument. From PositionFail/Dim_Position. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Leverage_Type COMMENT 'Leverage classification. ''Leveraged'' if Leverage>1, ''Not Leveraged'' if Leverage=1. 2 distinct values. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Copy_Manual COMMENT 'Trade origin classification. ''Copy'' if MirrorID>0 (copy-trading), ''Manual'' if MirrorID=0/NULL (user-initiated). 2 distinct values. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN ind_open_close COMMENT 'Trade direction. ''Open'' for position opening events, ''Close'' for position closing events. 2 distinct values. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Type COMMENT 'Event outcome type. ''Failures'' for execution failures, ''Succeeds'' for successful executions. 2 distinct values. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Customers COMMENT 'COUNT(DISTINCT CID) of unique customers in this aggregation bucket. Not additive across dimension slices. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Orders_Positions COMMENT 'Count of orders (for failures) or positions (for succeeds) in this aggregation bucket. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Amount COMMENT 'Sum of investment amounts in this bucket. Failures: from PositionFail.Amount or OpenExecutionPlan.Amount. Succeeds (Open): InitialAmountCents/100. Succeeds (Close): Dim_Position.Amount. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Volume COMMENT 'Sum of leveraged volume (Amount * Leverage) in this bucket. Represents notional trading value. Succeeds (Close): uses VolumeOnClose from Dim_Position. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN HedgeServerID COMMENT 'Hedge server that processed the execution. From PositionFail/Dim_Position. FK to hedge server dimension. (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 - ETL metadata)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN RegulationID COMMENT 'Regulatory entity ID from Dim_Customer.RegulationID. NULL for data before October 2024 (regulation added later by SR-276909). (Tier 2 - SP_Trading_Failures_Risk)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Dim_Customer.RegulationID -> Dim_Regulation.Name. NULL before October 2024. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN AirDrop_Type COMMENT 'Column exists in DDL but is not populated by the current SP INSERT statement. Always NULL. (Tier 2 - SP_Trading_Failures_Risk)';

-- ---- Column PII Tags ----
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN ErrorCode SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Leverage_Type SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Copy_Manual SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN ind_open_close SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Type SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Customers SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Orders_Positions SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Volume SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk ALTER COLUMN AirDrop_Type SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:14:45 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 34/34 succeeded
-- ====================
