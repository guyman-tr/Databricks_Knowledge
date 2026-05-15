-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_VerificationLevel
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_VerificationLevel` defines the progressive identity verification tiers that eToro customers pass through as they complete KYC (Know Your Customer) requirements. Each level represents a milestone unlocking additional platform capabilities. Level 0 is the starting state (unverified); Level 3 is full KYC with unrestricted access. Without this table, the DWH cannot segment customers by identity verification status. Regulatory requirements (MiFID II, ASIC, CySEC) mandate that large withdrawals, leveraged trading, and real stock purchases require minimum verification thresholds. This dimension provides the classification system for those segments in DWH analytics. Source: `etoro.Dictionary.VerificationLevel` on etoroDB-REAL. Loaded by SP_Dictionaries_DL_To_Synapse with TRUNCATE + INSERT. Two DWH-specific additions beyond the source data: 1. `DWHVerificationLevelID` - populated as a copy of `ID` (passthrough alias used in DWH ETL) 2. `StatusID` - hardcoded to 1 for all rows (ETL active-row convention...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED (ID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN ID COMMENT 'Verification tier identifier. Clustered index key. 0=Unverified (registration default, severe restrictions), 1=Basic (limited trading), 2=Intermediate (POI submitted, moderate access), 3=Full KYC (all features unlocked). -1=DWH sentinel (NULL-safe JOIN placeholder). Stored in customer dimension tables as VerificationLevelID and checked by 60+ procedures to gate trading, withdrawals, and compliance operations. (Tier 1 - upstream wiki, Dictionary.VerificationLevel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN Name COMMENT 'Display label for the tier. "Level 0" through "Level 3". Used in BackOffice UI, compliance reports, and customer analytics. Nullable by DDL but all production rows are populated. (Tier 1 - upstream wiki, Dictionary.VerificationLevel)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN DWHVerificationLevelID COMMENT 'DWH ETL alias for the ID column. Populated as `[ID] AS [DWHVerificationLevelID]` in SP_Dictionaries_DL_To_Synapse - always equals ID. Used internally by DWH ETL procedures that reference this column name; carries the same value as ID. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN StatusID COMMENT 'ETL active-row indicator. Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from the production source; carries no business meaning. DWH-wide ETL convention. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload. Not a production change timestamp - use for ETL freshness monitoring only. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN InsertDate COMMENT 'ETL load timestamp for row insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN ID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN DWHVerificationLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');

