-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CashoutReason
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason SET TBLPROPERTIES (
    'comment' = '`Dim_CashoutReason` enumerates why a withdrawal was initiated on the eToro platform. Every withdrawal carries a `CashoutReasonID` that classifies the business context: was it a standard user request, a Popular Investor payment, an affiliate payment, a risk refund, an account closure, or a crypto transfer? This classification is critical for financial reporting, compliance auditing, and withdrawal processing logic - different reasons trigger different routing in the withdrawal pipeline. Data flows from production `etoro.Dictionary.CashoutReason` via the Generic Pipeline (daily Override export to Bronze `general.bronze_etoro_dictionary_cashoutreason`), then through staging table `DWH_staging.etoro_Dictionary_CashoutReason`, and into DWH via `SP_Dictionaries_DL_To_Synapse` (TRUNCATE + INSERT). The DWH table is a clean passthrough of the production data with only `UpdateDate` replaced by `GETDATE()` at load time. See upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutReason.md`. `SP_Dicti...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CashoutReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason ALTER COLUMN CashoutReasonID COMMENT 'Primary key identifying the withdrawal reason. Values 1-19 in DWH. Stored in Billing.Withdraw and History.WithdrawAction on production. Special routing for IN (12, 14, 15) in Billing.WithdrawToFundingProcess. Default 16 (Requested by User) set in Billing.WithdrawRequestAdd. See Section 2.1 for full value map. (Tier 1 - upstream wiki, Dictionary.CashoutReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason ALTER COLUMN Name COMMENT 'Human-readable withdrawal reason label. E.g., "Requested by User" (most common), "PI Payment", "Foreclose account". Displayed in BackOffice withdrawal screens and used in audit trails. (Tier 1 - upstream wiki, Dictionary.CashoutReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() on each daily reload. Reflects when SP_Dictionaries_DL_To_Synapse last ran - NOT when the reason was added or changed in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason ALTER COLUMN CashoutReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:26:59 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
