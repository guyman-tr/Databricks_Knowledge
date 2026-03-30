-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_AffiliateCostType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype SET TBLPROPERTIES (
    'comment' = '`Dim_AffiliateCostType` is a reference dimension enumerating the cost categories used to classify affiliate marketing expenditures. Each row represents a distinct type of cost that the eToro affiliate program may incur when acquiring customers through affiliate channels (e.g., a CPA payment triggered by a first deposit, a Lead fee for a registration, or a Bonus for a qualified trade). This table was migrated from the legacy on-premises DWH SQL Server into Synapse in September 2024 via a one-time DWH_Migration load script (`2024_09_16_17_31_03_DWH_Migration.Dim_AffiliateCostType.sql`). A JUNK_ variant of the migration staging table also exists, confirming the standard two-pass migration pattern used during the Synapse migration project. No active ETL SP populates this table. The 11 rows (including the standard ID=0 N/A placeholder) represent the full set of cost types as they existed in the legacy DWH at migration time. As of 2026-03-19, this table has zero references from any stored procedure, view, or dow...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (AffiliateCostTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN AffiliateCostTypeID COMMENT 'Primary key identifying the affiliate cost type. Values 0-10; ID=0 is the standard N/A placeholder row for fact JOINs. (Tier 3 - live data, DWH_dbo.Dim_AffiliateCostType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN Name COMMENT 'Human-readable label for the affiliate cost category. See value map in Section 2.1 for all 10 active categories plus the N/A placeholder. Note: ID=9 "Copys" is likely a typo for "Copy" (copy-trade commissions). (Tier 3 - live data, DWH_dbo.Dim_AffiliateCostType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN InsertDate COMMENT 'Migration artifact - always NULL. In a live ETL table this would record the row creation timestamp; this table has no active ETL and was never populated during the DWH_Migration one-time load. (Tier 2b - DWH_Migration DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN UpdateDate COMMENT 'Migration artifact - always NULL. In a live ETL table this would record the last ETL refresh timestamp. No active ETL writes to this table. (Tier 2b - DWH_Migration DDL)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN AffiliateCostTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
