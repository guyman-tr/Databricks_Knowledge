-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PositionChangeLog
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog SET TBLPROPERTIES (
    'comment' = 'Dim_PositionChangeLog is the audit trail for position state changes. Every time a position''s amount, stop-loss rate, settlement flag, or lot count is modified after the initial open, a change log entry is created. This allows analysts to reconstruct the exact state of a position at any historical point in time. Key use cases: - **IsSettled tracking**: When a stock position transitions to "settled" status, the log records PreviousIsSettled vs IsSettled. The SP_Dim_Position_DL_To_Synapse ETL reads this table to backfill the correct IsSettled value on Dim_Position. - **Amount corrections**: When a position''s Amount or StopRate changes (e.g., partial close, margin call adjustment), the log records PreviousAmount and AmountChanged. The Dim_Position ETL uses ChangeTypeID=12 entries to apply cumulative amount corrections. - **Initial open event**: ChangeTypeID=0 records the initial position open event -- used to detect the first appearance of a position in the changelog (primarily for hedge server tracking in SP_...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (PositionID)',
    'synapse_index' = 'CLUSTERED INDEX (OccurredDateID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PositionID COMMENT 'FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN CID COMMENT 'Customer ID who owns the position. Nullable (some system positions may not have CID). (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN Occurred COMMENT 'Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN OccurredDateID COMMENT 'ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN ChangeTypeID COMMENT 'Type of change event. Known codes: 0=Initial open, 1=Rate change, 2=Unknown, 5=Unknown (added 2024), 11=Partial close event, 12=Amount adjustment, 13=Unknown. No official lookup table in DWH. (Tier 4 - [UNVERIFIED])';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousAmount COMMENT 'Position amount (USD) before this change. NOT NULL -- always captured. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN AmountChanged COMMENT 'Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN NewAmount COMMENT 'Position amount after this change. Nullable -- may be absent for non-amount change types. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousIsSettled COMMENT 'Before the change: 1 = real asset, 0 = CFD asset. Cast from bit in staging. NULL if this event did not involve a settlement change. (Tier 5 - Expert Review)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN IsSettled COMMENT 'After the change: 1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousStopRate COMMENT 'Stop-loss rate before this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN StopRate COMMENT 'Stop-loss rate after this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousAmountInUnits COMMENT 'Unit count (shares/coins) before this change. Added for futures/unit-based positions. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN AmountInUnits COMMENT 'Unit count after this change. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN LotCountDecimal COMMENT 'New lot count after change. Added 2024-11-07 (Inbal BML) for futures project. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousLotCountDecimal COMMENT 'Lot count before this change. Added 2024-11-07. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (GETDATE()). Not from production source. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN OccurredDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN ChangeTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN AmountChanged SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN NewAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousIsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousStopRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN StopRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousAmountInUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN AmountInUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN LotCountDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN PreviousLotCountDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
