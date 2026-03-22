-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot SET TBLPROPERTIES (
    'comment' = 'Dim_PositionHedgeServerChangeLog_Snapshot tracks which hedge server (HedgeServerID) was responsible for executing and managing each position during any given date range. A hedge server is the execution venue or broker-side system where a position is "hedged" (i.e., covered with a liquidity provider). Positions can move between hedge servers during their lifetime. This table uses an SCD Type 2 pattern: - **FromDate**: The YYYYMMDD date from which HedgeServerID was active for this position. - **ToDate**: The YYYYMMDD date to which HedgeServerID was active. ToDate=20991231 indicates the current/active assignment. - A position moving from HedgeServer A to HedgeServer B generates two rows: (PositionID, ServerA, FromDate=OpenDate, ToDate=yesterday) and (PositionID, ServerB, FromDate=today, ToDate=20991231). **Predecessor table**: The original `Dim_PositionHedgeServerChangeLog` table was replaced by this snapshot variant. The `_Snapshot` suffix indicates the SCD2 approach vs. the original raw-log approach. `Dim_P...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (PositionID)',
    'synapse_index' = 'CLUSTERED INDEX (PositionID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN PositionID COMMENT 'The position that was moved between hedge servers. References Trade.PositionTbl.PositionID (implicit - no declared FK). Part of composite PK with OperationSummaryID. A position can appear multiple times if moved across different operations. (Tier 1 — Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN HedgeServerID COMMENT 'The hedge server ID the position was moved to. After this operation, Trade.PositionTbl.HedgeServerID equals this value for the affected position. (Tier 1 — Trade.PositionsHedgeServerChangeLog)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN FromDate COMMENT 'Start date of this hedge server assignment (YYYYMMDD int). For initial position open: equals OpenDateID. For subsequent changes: equals the date the change took effect. (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN ToDate COMMENT 'End date of this hedge server assignment (YYYYMMDD int). 20991231=currently active. For closed/changed records: the last day this assignment was valid (inclusive). (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (GETDATE()). All rows share same timestamp per daily ETL run. Last seen: 2026-02-27. (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN FromDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN ToDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
