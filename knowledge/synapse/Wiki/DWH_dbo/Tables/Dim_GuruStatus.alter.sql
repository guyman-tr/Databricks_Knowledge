-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_GuruStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus SET TBLPROPERTIES (
    'comment' = '`Dim_GuruStatus` is a 9-row dictionary classifying eToro customers in the **Popular Investor (PI) program** (internally called "Guru"). The PI program allows experienced traders to earn income by being copied; status reflects their tier and program standing. The status ladder (active tiers): - 0 = No: Customer is not enrolled in the Popular Investor program - 1 = Certified: Entry-level PI certification - 2 = Cadet: First active tier of the PI program - 3 = Rising Star: Second tier - growing following - 4 = Champion: Third tier - 5 = Elite: Fourth tier - top performers - 6 = Elite Pro: Highest active tier - professional Popular Investors Negative states: - 7 = Removed: Previously enrolled, now removed from the program - 8 = Rejected: Applied but rejected from the program **GuruStatusID=0 (No)** serves as both the "not enrolled" value and the null-safe join sentinel: SP_Dim_Customer uses `ISNULL(GuruStatusID, 0)` to coerce NULLs to 0. The data originates from `etoro.Dictionary.GuruStatus` via `DWH_staging.et...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (GuruStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus ALTER COLUMN GuruStatusID COMMENT 'Primary key identifying the PI program state. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Referenced by BackOffice.Customer (FK), Billing.GuruStatusToCashoutFeeGroup (FK). Filtered as IN (2,3,4,5) for active PIs or IN (2,3,4,5,6) including Elite Pro. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus ALTER COLUMN GuruStatusName COMMENT 'Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 - Dictionary.GuruStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus ALTER COLUMN GuruStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus ALTER COLUMN GuruStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
