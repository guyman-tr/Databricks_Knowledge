-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ClientWithdrawReason
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason SET TBLPROPERTIES (
    'comment' = '`Dim_ClientWithdrawReason` lists the predefined reasons a customer can select when submitting a withdrawal request. These options appear in the withdrawal form UI during the cash-out flow, allowing customers to indicate why they are withdrawing funds. The reasons range from "Withdrawing profits" (indicating trading success) to "Moving to a competitor" (competitive churn signal). This dimension enables churn analysis and product improvement by revealing withdrawal motivations. Data flows from `etoro.Dictionary.ClientWithdrawReason` via the Generic Pipeline (daily Override to Bronze), through `DWH_staging.etoro_Dictionary_ClientWithdrawReason`, and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ETL applies two changes: (1) the production `Name` column is renamed to `ClientWithdrawReasonName`, and (2) `UpdateDate` is replaced by `GETDATE()`. The production `IsActive` and `DisplayOrder` columns (used to control UI display) are **not loaded into DWH**. All 7 production active reasons are present (IDs 1-7). N...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (ClientWithdrawReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason ALTER COLUMN ClientWithdrawReasonID COMMENT 'Primary key. Values 1-7. Referenced by Billing.Withdraw via FK on production. Passed as @ClientWithdrawReasonID to WithdrawalService_WithdrawRequestAdd on production. DWH DDL defines as nullable - this is a DDL quirk (production column is NOT NULL). (Tier 1 - upstream wiki, Dictionary.ClientWithdrawReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason ALTER COLUMN ClientWithdrawReasonName COMMENT 'Human-readable reason label shown in the withdrawal form. DWH note: column renamed from production `Name` to `ClientWithdrawReasonName` by SP_Dictionaries_DL_To_Synapse. E.g., "Withdrawing profits", "Moving to a competitor", "None of the reasons above". (Tier 1 - upstream wiki, Dictionary.ClientWithdrawReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() on each daily reload. Not a business change date - reflects SP_Dictionaries_DL_To_Synapse execution time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason ALTER COLUMN ClientWithdrawReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason ALTER COLUMN ClientWithdrawReasonName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:27:13 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
