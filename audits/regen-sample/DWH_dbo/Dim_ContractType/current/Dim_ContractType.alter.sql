-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ContractType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_ContractType is a reference table defining affiliate commission model types for eToro''s affiliate marketing program. Each row represents a distinct compensation structure used in partner agreements: - **CPR** (Cost Per Registration): flat fee per new user registration - **CPA** (Cost Per Acquisition): flat fee per qualifying deposit - **Rev** (Revenue Share): percentage of ongoing trading revenue - **Hyb** (Hybrid): combination model (e.g., CPA + Rev share) - **eCost**: electronic/digital cost model - **ZeroCost**: no-commission arrangement - **CPL** (Cost Per Lead): fee per lead submitted The table is a DWH-internal lookup with no direct equivalent in the production etoro database (etoro.Dictionary has no ContractType table). It was migrated from the legacy DWH SQL Server as a one-time load and has never been updated since - all InsertDate and UpdateDate values are NULL. Note: SP_Dim_Affiliate populates Dim_Affiliate.ContractType via an inline CASE expression on ContractName text patterns (LIK...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ContractTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN ContractTypeID COMMENT 'Affiliate commission model identifier. Values: 0=N/A (unknown/fallback), 1=CPR (Cost Per Registration), 2=CPA (Cost Per Acquisition), 3=Rev (Revenue Share), 4=Hyb (Hybrid), 5=Other, 6=eCost, 7=ZeroCost, 8=CPL (Cost Per Lead). SP_Dim_Affiliate derives these values via CASE on ContractName text. (Tier 2 - DWH_Migration.Dim_ContractType DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN Name COMMENT 'Abbreviated commission model name: N/A, CPR, CPA, Rev, Hyb, Other, eCost, ZeroCost, CPL. Short abbreviations used as display labels in affiliate reporting. No description column exists - analyst reference only. (Tier 3 - live data sampling, SELECT * FROM Dim_ContractType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN InsertDate COMMENT 'Migration load timestamp. All 9 rows are NULL - this column was populated as varchar(50) in the DWH_Migration staging DDL but the values were not carried over (or were NULL in the legacy DWH SQL Server source). Not useful for row age determination. (Tier 2 - DWH_Migration.Dim_ContractType DDL + Tier 3 live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN UpdateDate COMMENT 'Last update timestamp. All 9 rows are NULL - same as InsertDate, no values were populated during migration. Table is effectively static since initial load. (Tier 2 - DWH_Migration.Dim_ContractType DDL + Tier 3 live data)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN ContractTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:27:28 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 10/10 succeeded
-- ====================
