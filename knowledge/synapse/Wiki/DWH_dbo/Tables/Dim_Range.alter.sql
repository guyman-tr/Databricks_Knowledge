-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Range
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range SET TBLPROPERTIES (
    'comment' = 'Dim_Range is a DWH-internal helper lookup that pre-computes all possible (FromDate, ToDate) date range pairs needed by the Snapshot analytics pipelines. Each row represents a unique start-to-end date interval, identified by a composite BigInt key (DateRangeID). The table enables efficient range-based JOINs in SnapshotEquity and SnapshotCustomer views without requiring date arithmetic at query time. This table has no external production source. It is generated entirely within the DWH by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer, which INSERT new DateRangeID combinations as they encounter new date pairs during snapshot processing. The pattern is append-only - new rows are added daily but existing rows are never updated or deleted. As of 2026-03-10, the table contains approximately 1.3 million date range pairs spanning from 2007-01-01 to 2026-03-10 on the FromDate side, and 2007-08-26 to 2026-12-31 on the ToDate side. Synapse: REPLICATE, CLUSTERED INDEX (DateRangeID, FromDateID, ToDateID) + 3 NCI in...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (DateRangeID, FromDateID, ToDateID) + 3 NCI indexes',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN DateRangeID COMMENT 'Primary key (NOT ENFORCED). 12-digit composite key encoding FromDate and MMDD(ToDate). Formula: CONCAT(YYYYMMDD(From), MMDD(To)). Example: 200701011231 = From:20070101, To:20071231. (Tier 2 - SP code: SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN FromDateID COMMENT 'Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - SP code: SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN ToDateID COMMENT 'End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - SP code: SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN UpdateDate COMMENT 'ETL timestamp set to GETDATE() when the row was inserted. NULL for oldest rows (pre-UpdateDate tracking). Not a business date. (Tier 3b - DDL)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN DateRangeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
