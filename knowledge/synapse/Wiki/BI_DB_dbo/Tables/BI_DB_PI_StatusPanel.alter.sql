-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_PI_StatusPanel
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_PI_StatusPanel > 11K-row accumulating table tracking the most recent PI tier upgrade, downgrade, and removal events for each customer who has ever been a Popular Investor. Daily UPDATE+INSERT (upsert pattern) via SP_PI_StatusPanel. Source: Fact_SnapshotCustomer GuruStatusID change detection via LAG() window function. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Fact_SnapshotCustomer + Dim_GuruStatus via `SP_PI_StatusPanel` | | **Refresh** | Daily (UPDATE existing + INSERT new - accumulating, not truncate) | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (CID ASC) | | **UC Target** | `_Not_Migrated` | | **UC Format** | - | | **UC Partitioned By** | - | | **UC Table Type** | - | | **Author** | Katy F (2017-06-01), rewritten by Ben Einav (2024-05-10) | | **'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN CID COMMENT 'Customer ID. Mapped from Fact_SnapshotCustomer.RealCID. Clustered index key. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeID COMMENT 'GuruStatusID of the most recent downgrade target tier. NULL if no downgrade recorded. Values: 0=No, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeTo COMMENT 'Human-readable name of the downgrade target tier. From Dim_GuruStatus.GuruStatusName. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeFromID COMMENT 'GuruStatusID of the tier BEFORE the downgrade. NULL if no downgrade recorded. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeFrom COMMENT 'Human-readable name of the tier before downgrade. From Dim_GuruStatus.GuruStatusName. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeDate COMMENT 'Date of the most recent downgrade event. Derived from Dim_Range.FromDateID. NULL if no downgrade. (Tier 2 - SP_PI_StatusPanel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeID COMMENT 'GuruStatusID of the most recent upgrade target tier. NULL if no upgrade recorded. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeTo COMMENT 'Human-readable name of the upgrade target tier. From Dim_GuruStatus.GuruStatusName. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeFromID COMMENT 'GuruStatusID of the tier BEFORE the upgrade. NULL if no upgrade recorded. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeFrom COMMENT 'Human-readable name of the tier before upgrade. From Dim_GuruStatus.GuruStatusName. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeDate COMMENT 'Date of the most recent upgrade event. Derived from Dim_Range.FromDateID. NULL if no upgrade. (Tier 2 - SP_PI_StatusPanel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastRemovedDate COMMENT 'Date of the most recent removal from the PI program (downgrade to GuruStatusID=0). NULL if never removed. (Tier 2 - SP_PI_StatusPanel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN UpdateDate COMMENT 'ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 - SP_PI_StatusPanel)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeTo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeFromID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastDowngradeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeTo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeFromID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastUpgradeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN LastRemovedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_pi_statuspanel ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:11:08 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 28/28 succeeded
-- ====================
