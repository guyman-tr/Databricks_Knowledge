-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_SnapshotEquity_FromDateID
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotEquity_FromDateID]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotEquity`, `Dim_Range` | | **Purpose** | Exposes Fact_SnapshotEquity with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range filtering without an additional join to Dim_Date. |'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN FromDateID COMMENT 'Start date of the equity snapshot range (YYYYMMDD integer). (Tier 2 — view DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN ToDateID COMMENT 'End date of the equity snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 — view DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN All Fact_SnapshotEquity columns COMMENT 'See [Fact_SnapshotEquity.md](../Tables/Fact_SnapshotEquity.md) for full column documentation. (Tier 2 — inherited)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN All Fact_SnapshotEquity columns SET TAGS ('pii' = 'none');
