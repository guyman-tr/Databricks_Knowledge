-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.v_Dim_Mirror
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror SET TBLPROPERTIES (
    'comment' = '`v_Dim_Mirror` is a thin view over `DWH_dbo.Dim_Mirror` that exposes all columns of the underlying copy-trading relationship table plus one computed column: `snapshot_date = CAST(GETDATE() AS DATE)`. The view definition is: ```sql SELECT *, CAST(GETDATE() AS DATE) AS snapshot_date FROM [DWH_dbo].[Dim_Mirror] ``` `Dim_Mirror` contains 11.1M rows representing every copy-trading relationship on eToro from 2011 to present - copier (`CID`), copied person (`ParentCID`), investment amount, open/close dates, P&L, risk settings, and mirror type (Regular, Fund, CopyMe, Smart Portfolio). For full documentation of the underlying data model, see [DWH_dbo.Dim_Mirror](../Tables/Dim_Mirror.md). **Purpose of snapshot_date**: By adding `CAST(GETDATE() AS DATE)`, this view stamps each query result with today''s date, enabling consumers (dashboards, pipelines, snapshot exports) to label the result set with its query date without modifying the base table or requiring a separate date join. **Note**: `snapshot_date` is evaluated ...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror SET TAGS (
    'domain' = 'trading',
    'object_type' = 'table',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A (View - inherits from Dim_Mirror: HASH(MirrorID))',
    'synapse_index' = 'N/A (View)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror ALTER COLUMN snapshot_date COMMENT 'Current calendar date at query execution time. `CAST(GETDATE() AS DATE)`. Used as a daily snapshot label for dashboards and snapshot exports. Changes on every query invocation - not a stable historical timestamp. (Tier 2 - view DDL)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror ALTER COLUMN snapshot_date SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:35:58 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 4/4 succeeded
-- ====================
