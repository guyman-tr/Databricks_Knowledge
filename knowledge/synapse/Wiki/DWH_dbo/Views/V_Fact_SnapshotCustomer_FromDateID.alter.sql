-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_SnapshotCustomer_FromDateID
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
-- Resolved via: Wiki property table
-- Classification: PII Masked
-- Secondary UC Target: main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid  (PII unmasked)
-- Masked Columns: 
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer_FromDateID]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range` | | **Purpose** | Exposes Fact_SnapshotCustomer with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range boundary filtering without expanding to daily rows. |'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked SET TAGS (
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN FromDateID COMMENT 'Start date of the customer snapshot range (YYYYMMDD integer). (Tier 2 - view DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN ToDateID COMMENT 'End date of the customer snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 - view DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN All Fact_SnapshotCustomer columns COMMENT 'See [Fact_SnapshotCustomer.md](../Tables/Fact_SnapshotCustomer.md) for full column documentation. (Tier 2 - inherited)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked ALTER COLUMN All Fact_SnapshotCustomer columns SET TAGS ('pii' = 'none');

-- === Secondary UC Target (PII unmasked) ===
-- Column comments are identical - meaning is the same regardless of masking.

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotCustomer_FromDateID]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotCustomer`, `Dim_Range` | | **Purpose** | Exposes Fact_SnapshotCustomer with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range boundary filtering without expanding to daily rows. |'
);

ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid SET TAGS (
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
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN FromDateID COMMENT 'Start date of the customer snapshot range (YYYYMMDD integer). (Tier 2 - view DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN ToDateID COMMENT 'End date of the customer snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 - view DDL)';
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN All Fact_SnapshotCustomer columns COMMENT 'See [Fact_SnapshotCustomer.md](../Tables/Fact_SnapshotCustomer.md) for full column documentation. (Tier 2 - inherited)';

-- ---- Column PII Tags ----
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN All Fact_SnapshotCustomer columns SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:36:11 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 12/16 succeeded
-- Error: [PARSE_SYNTAX_ERROR] Syntax error at or near 'Fact_SnapshotCustomer'. SQLSTATE: 42601 (line 1, pos 106) == SQL == ALTER TABLE main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid ALTER COLUMN All Fact_SnapshotCustomer columns SET TAGS ('pii' = 'none'); ----------------------------------------------------------------------------------------------------------^^^
-- ====================
