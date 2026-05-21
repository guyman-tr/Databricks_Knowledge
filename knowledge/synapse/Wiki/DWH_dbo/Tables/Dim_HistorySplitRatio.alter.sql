-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_HistorySplitRatio
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_HistorySplitRatio` stores the cumulative adjustment factors for every stock split and corporate action that has occurred on instruments traded on the eToro platform. Each row defines a contiguous date range (`MinDate` to `MaxDate`) during which a specific price ratio and amount ratio applied. When a new split occurs, the instrument gains a new row with a new date range, and all prior rows are updated to reflect the cumulative adjustment stack. The table is the canonical reference for converting historical prices to split-adjusted form for analytics. Data originates from `PriceLog.History.SplitRatio` on the price server (AZR-W-PRICEDB-2-Price). The Generic Pipeline exports this table hourly to `Bronze/PriceLog/History/SplitRatio/` in the data lake (UC: `dealing.bronze_pricelog_history_splitratio`). The ETL SP (`SP_Dim_HistorySplitRatio_DL_To_Synapse`) then loads it into Synapse from `DWH_staging.etoro_History_SplitRatio` daily. Source: upstream `PriceLog.History.SplitRatio` (no upstream wiki in...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (InstrumentID ASC, MinDate ASC, MaxDate ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN ID COMMENT 'Integer primary key identifying each split ratio record. Not auto-incremented in the DWH; value is passed through from the staging source via SP_Dim_HistorySplitRatio_DL_To_Synapse.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN InstrumentID COMMENT 'The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto). (Tier 1 - History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN MinDate COMMENT 'Start of the period this split ratio is effective. Default ''2000-01-01'' means "from the beginning of the instrument''s history." The split adjustment applies to transactions from this date forward until MaxDate. (Tier 1 - History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN MaxDate COMMENT 'End of the period this split ratio is effective (exclusive). Sentinel value ''2100-01-01'' means "currently active - no end date set." When a new split occurs, the current active row''s MaxDate is set to the new split''s MinDate. (Tier 1 - History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN PriceRatio COMMENT 'Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment. (Tier 1 - History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN AmountRatio COMMENT 'Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment. (Tier 1 - History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN PriceRatioUnAdjusted COMMENT 'Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison. DWH note: stored as decimal(19,4) in Synapse (money in production). (Tier 1 - History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN AmountRatioUnAdjusted COMMENT 'Original unadjusted amount ratio stored as money type. Before cumulative adjustments. DWH note: stored as decimal(19,4) in Synapse (money in production). (Tier 1 - History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - set to GETDATE() on each truncate/reload by SP_Dim_HistorySplitRatio_DL_To_Synapse. All rows share the same value after each daily refresh. (Tier 2 - SP_Dim_HistorySplitRatio_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN MinDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN MaxDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN PriceRatio SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN AmountRatio SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN PriceRatioUnAdjusted SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN AmountRatioUnAdjusted SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:22:27 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 20/20 succeeded
-- ====================
