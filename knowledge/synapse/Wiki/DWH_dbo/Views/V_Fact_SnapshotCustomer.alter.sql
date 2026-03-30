-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_SnapshotCustomer
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer
-- Resolved via: Wiki property table
-- Classification: PII Only
-- =============================================================================

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range`, `Dim_Date` | | **Purpose** | Expands Fact_SnapshotCustomer SCD2 date ranges into individual daily rows via `Dim_Range` + `Dim_Date` bridge. Adds `DateKey` for easy daily-grain queries. |'
);

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer SET TAGS (
    'domain' = 'customer',
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DateKey COMMENT 'Specific date within the snapshot range (YYYYMMDD integer). One row per day per customer. (Tier 2 - view DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN All Fact_SnapshotCustomer columns COMMENT 'See [Fact_SnapshotCustomer.md](../Tables/Fact_SnapshotCustomer.md). (Tier 2 - inherited)';

-- ---- Column PII Tags ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN DateKey SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer ALTER COLUMN All Fact_SnapshotCustomer columns SET TAGS ('pii' = 'none');
