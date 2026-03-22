-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CompensationReason
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason SET TBLPROPERTIES (
    'comment' = '`Dim_CompensationReason` defines the full taxonomy of reasons BackOffice uses when making manual compensation entries to customer accounts. Each row maps a reason code to its label and parent category. As of 2026-03-19 the table has 133 rows (IDs 0-134, with IDs 5 and 130 absent). The two-level hierarchy groups specific reasons under nine root categories: Custom(1), Marketing(4), Accounting/Ops(9), R&D(10), ACT(16), Obsolete(23), MT4(35), Dividend(45), and Inactivity Fee For Non Depositor(48). ID=0 is the ETL-inserted N/A placeholder. Data flows from `etoro.BackOffice.CompensationReason` via `DWH_staging.etoro_BackOffice_CompensationReason` and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ETL renames `CompensationReasonID` to `DWHCompensationID` (same value), hardcodes `StatusID=1`, and sets `UpdateDate`/`InsertDate` to `GETDATE()`. The production columns `DisplayName`, `IsShownInHistory`, `IsCashflowForGain`, `IsTaxable`, and `IsActive` are **not loaded into DWH**. See upstream wiki: `DB_Schema/etoro...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CompensationReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN Tier 1 COMMENT 'Verbatim from upstream production wiki';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN Tier 2 COMMENT 'Confirmed from Synapse ETL SP code';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN CompensationReasonID COMMENT 'Primary key. Unique reason identifier, 0-134 (IDs 5 and 130 absent). ID=0 is ETL-inserted N/A placeholder. Used as FK in Accounting.BalanceHistory and Fact_BillingCompensation. (Tier 1 - upstream wiki, BackOffice.CompensationReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN ParentID COMMENT 'Parent reason ID for 2-level hierarchy. NULL for root categories. Non-null values point directly to a root category row. Roots: 1=Custom, 4=Marketing, 9=Accounting/Ops, 10=R&D, 16=ACT, 23=Obsolete, 35=MT4, 45=Dividend, 48=Inactivity Fee For Non Depositor. (Tier 1 - upstream wiki, BackOffice.CompensationReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN Name COMMENT 'Human-readable reason label used in BackOffice UI and reports. E.g., "Satisfaction Bonus", "Cash Dividend", "Dormant Fee". Passed through unchanged from production. (Tier 1 - upstream wiki, BackOffice.CompensationReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN DWHCompensationID COMMENT 'DWH rename of CompensationReasonID. DWHCompensationID = CompensationReasonID (identical values). Redundant column - use CompensationReasonID for all JOINs. Added by SP_Dictionaries_DL_To_Synapse ETL mapping. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN StatusID COMMENT 'Active record flag hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from production BackOffice.CompensationReason. No filtering value - all rows have StatusID=1. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() on each daily reload for standard rows; CAST(GETDATE() AS DATE) for ID=0 placeholder. Not a business change date. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN InsertDate COMMENT 'ETL insert timestamp set to GETDATE() on each daily reload for standard rows; CAST(GETDATE() AS DATE) for ID=0 placeholder. Not the date the reason was originally created in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN Tier 1 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN Tier 2 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN CompensationReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN ParentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN DWHCompensationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
