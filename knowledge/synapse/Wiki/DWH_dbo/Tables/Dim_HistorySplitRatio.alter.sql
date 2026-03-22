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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN ID COMMENT 'Sequential integer primary key for the split ratio record. Passed through from PriceLog.History.SplitRatio without transformation. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN InstrumentID COMMENT 'Instrument identifier (FK to DWH_dbo.Dim_Currency.CurrencyID and DWH_dbo.Dim_Instrument.InstrumentID). Groups all split ratio records for a single tradeable instrument. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN MinDate COMMENT 'Start of the date range (inclusive) for which the ratio applies. `2000-01-01` is the beginning-of-history sentinel for the earliest period before any splits. (Tier 3 -- live data, PriceLog.History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN MaxDate COMMENT 'End of the date range (exclusive) for which the ratio applies. `2100-01-01` is the open-ended sentinel indicating the currently active ratio (no further splits yet). (Tier 3 -- live data, PriceLog.History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN PriceRatio COMMENT 'Cumulative price adjustment multiplier for this period. Multiply a historical price by this value to get its split-adjusted equivalent. 1.0 means no adjustment. Example: PriceRatio=0.25 means a 4:1 stock split occurred (1 old share = 4 new shares, price adjusted down to 25%). (Tier 3 -- live data, PriceLog.History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN AmountRatio COMMENT 'Cumulative amount/quantity adjustment multiplier for this period. Multiply a historical position size by this value to get the split-adjusted share count. Inverse of PriceRatio: AmountRatio=4.0 corresponds to PriceRatio=0.25 (4:1 split). (Tier 3 -- live data, PriceLog.History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN PriceRatioUnAdjusted COMMENT 'Incremental (non-cumulative) price ratio from the most recent split event only, before stacking with prior splits. Used to isolate the effect of a single split. 1.0 for the oldest period (before any splits). (Tier 3 -- live data, PriceLog.History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN AmountRatioUnAdjusted COMMENT 'Incremental (non-cumulative) amount ratio from the most recent split event only. Inverse of PriceRatioUnAdjusted for the current split. 1.0 for the oldest period (before any splits). (Tier 3 -- live data, PriceLog.History.SplitRatio)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- set to GETDATE() by SP_Dim_HistorySplitRatio_DL_To_Synapse at each reload. Not from the production source. Reflects when DWH was last refreshed, not when the split data changed. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse)';

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
