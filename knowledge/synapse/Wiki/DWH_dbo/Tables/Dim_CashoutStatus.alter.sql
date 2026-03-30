-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CashoutStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus SET TBLPROPERTIES (
    'comment' = '`Dim_CashoutStatus` is the DWH dimension for withdrawal request lifecycle states. In production, `Dictionary.CashoutStatus` defines 17 distinct states spanning the full cashout pipeline - from initial submission through compliance review, billing processing, provider settlement, and potential reversal. The DWH version contains only 5 rows: the 4 core workflow states (Pending, InProcess, Processed, Canceled) plus an ID=0 N/A placeholder. The production `IsFinishedWithoutMoneyTransfer` (terminal vs. no-money states) and `IsFinalStatus` (terminal/non-terminal flag) columns are **not loaded into DWH**. DWH instead adds `DWHCashoutStatusID` (a redundant surrogate equal to `CashoutStatusID`) and `StatusID` (hardcoded to 1). This means analysts using `Dim_CashoutStatus` in DWH JOINs will fail to resolve statuses such as Rejected (7), Reversed (16), Under Review (15), or SentToProvider (10) - those IDs will return NULL. Data flows from `etoro.Dictionary.CashoutStatus` via the Generic Pipeline (daily Override to Br...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CashoutStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN CashoutStatusID COMMENT 'Primary key. DWH values: 0=N/A (placeholder), 1=Pending, 2=InProcess, 3=Processed, 4=Canceled. Note: production has 17 states (IDs 5-17 missing from DWH). Stored in withdrawal request records and updated as requests progress. (Tier 1 - upstream wiki, Dictionary.CashoutStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN Name COMMENT 'Human-readable status label. Values: "N/A", "Pending", "InProcess", "Processed", "Canceled". UNIQUE at production level (not enforced in DWH DDL). Used in reports and monitoring. (Tier 1 - upstream wiki, Dictionary.CashoutStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN DWHCashoutStatusID COMMENT 'DWH surrogate - always equal to CashoutStatusID. Set by SP_Dictionaries as `[CashoutStatusID] as [DWHCashoutStatusID]`. No analytical value; redundant pattern used for consistency across DWH dictionary tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN StatusID COMMENT 'Active record indicator, hardcoded to 1 for all rows (including ID=0 placeholder). Mirrors the StatusID=1 convention used across SP_Dictionaries-loaded tables. Not sourced from production Dictionary.CashoutStatus. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. GETDATE() for rows loaded from staging (IDs 1-4); @ddate (midnight, CAST(GETDATE() AS DATE)) for the ID=0 N/A placeholder. Not a business change date. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN InsertDate COMMENT 'ETL insert timestamp. GETDATE() for staging rows; @ddate (midnight) for the ID=0 placeholder. Same value as UpdateDate (full reload on each run). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN CashoutStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN DWHCashoutStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:27:04 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 14/14 succeeded
-- ====================
