-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CustomerChangeType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype SET TBLPROPERTIES (
    'comment' = '`Dim_CustomerChangeType` is a lookup dimension that maps integer IDs to the names of customer attribute fields tracked for historical change. The table contains 16 rows - one per trackable Dim_Customer field. When `Fact_SnapshotCustomer` (or a related customer history table) records a change to a customer record, it uses `CustomerChangeTypeID` to identify WHICH field changed (e.g., ID=5 means "PlayerStatusID changed", ID=12 means "RegulationID changed"). The old value and new value are stored as separate columns in the fact table. This table was migrated from the legacy on-premises DWH SQL Server in September 2024 (`2024_09_16_17_31_03_DWH_Migration.Dim_CustomerChangeType.sql`). All 16 rows bear the same timestamp of 2018-10-02, indicating the lookup was last updated in 2018 and has been frozen since. The JUNK_ migration variant confirms the standard two-pass Synapse migration pattern. `SP_Fact_SnapshotCustomer` references `CustomerChangeTypeID` in its result query (currently commented out in the SP body) ...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CustomerChangeTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype ALTER COLUMN CustomerChangeTypeID COMMENT 'Primary key identifying the type of customer attribute change. Values 1-16, each mapping to a specific Dim_Customer field name. No ID=0 placeholder row exists. Tinyint supports up to 255 - room for future change types. (Tier 3 - live data, DWH_dbo.Dim_CustomerChangeType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype ALTER COLUMN Name COMMENT 'Name of the Dim_Customer field being tracked for changes. Values are field names (e.g., "CountryID", "PlayerStatusID") - see Section 2.1 for the full value map. Use this to understand which customer attribute changed in a fact table change event. (Tier 3 - live data, DWH_dbo.Dim_CustomerChangeType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype ALTER COLUMN UpdateDate COMMENT 'Timestamp of the last ETL refresh. All rows show 2018-10-02 - the lookup has not been updated since migration from the legacy DWH. No active ETL exists to change this. (Tier 2b - DWH_Migration DDL, legacy DWH SQL Server)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype ALTER COLUMN CustomerChangeTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

