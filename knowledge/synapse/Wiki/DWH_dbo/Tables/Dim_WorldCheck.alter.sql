-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_WorldCheck
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_WorldCheck` is a 5-row reference table defining the possible outcomes of screening customers against the Refinitiv World-Check database - a global sanctions, PEP (Politically Exposed Persons), and adverse media screening tool used for AML compliance. Every eToro customer undergoes World-Check screening as part of the KYC/AML process. The result is stored per-customer in the `WorldCheckID` column of customer dimension tables and determines the customer''s compliance risk tier: clear customers (ID=2) proceed normally; PEP matches (ID=3) trigger Enhanced Due Diligence; Risk matches (ID=4) may result in account restrictions or relationship termination. Source: `etoro.Dictionary.WorldCheck` on etoroDB-REAL. The Generic Pipeline exports it daily to Bronze, staged into `DWH_staging.etoro_Dictionary_WorldCheck`, and SP_Dictionaries_DL_To_Synapse loads with TRUNCATE + INSERT. ID=0 (unscreened, empty name string) already exists in the source - no ETL placeholder is added. Synapse: REPLICATE, CLUSTERED (W...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED (WorldCheckID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck ALTER COLUMN WorldCheckID COMMENT 'Primary key for the World-Check screening outcome. 0= (empty name), 1=Pending WCH (screening in progress), 2=No Match (clear), 3=PEP Match (Enhanced Due Diligence triggered), 4=Risk Match (sanctions/high-risk, possible freeze). Stored on customer dimension tables to classify each customer''s AML screening status. Referenced by risk classification procedures and economic reports. (Tier 1 - upstream wiki, Dictionary.WorldCheck)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck ALTER COLUMN WorldCheckName COMMENT 'Display label for the screening outcome. ID=0 has an empty string (not NULL). Used in BackOffice UI, PEP reports, and compliance dashboards. Sourced directly from Dictionary.WorldCheck.WorldCheckName. (Tier 1 - upstream wiki, Dictionary.WorldCheck)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp - use for ETL freshness monitoring only. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck ALTER COLUMN WorldCheckID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck ALTER COLUMN WorldCheckName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_worldcheck ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:27:16 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
