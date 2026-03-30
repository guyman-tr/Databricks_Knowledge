-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CashoutMode
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode SET TBLPROPERTIES (
    'comment' = 'Dim_CashoutMode is the DWH version of etoro.Dictionary.CashoutMode. It classifies how a withdrawal request is processed -- whether it requires manual operator intervention, is automatically created and queued, is part of a mass automated batch, or is processed instantly. The CashoutModeWeight establishes processing priority -- higher weights get processed first. Instant Withdrawal (weight 30) takes precedence over Mass Auto Create (20), Auto Create (10), and Manual (0). The CashoutModeID is stored on withdrawal transaction records and flows through to BackOffice reporting and payout processing systems. Source: etoro.Dictionary.CashoutMode on etoroDB-REAL. Exported daily to Bronze/etoro/Dictionary/CashoutMode/ and staged into DWH_staging.etoro_Dictionary_CashoutMode. SP_Dictionaries_DL_To_Synapse loads using TRUNCATE + INSERT; all 3 production columns are passthrough; UpdateDate = GETDATE(). 4 rows: IDs 0-3. Synapse: REPLICATE, CLUSTERED INDEX (CashoutModeID).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CashoutModeID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN CashoutModeID COMMENT 'Primary key identifying the withdrawal processing mode. 0=Manual, 1=Auto Create, 2=Mass Auto Create, 3=Instant Withdrawal. Stored on withdrawal transaction records (Billing.WithdrawToFunding). Note: ID=0 is a legitimate value (Manual mode), NOT a DWH placeholder. (Tier 1 - upstream wiki, Dictionary.CashoutMode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN CashoutModeName COMMENT 'Human-readable mode name. ''Manual'', ''Auto Create'', ''Mass Auto Create'', ''Instant Withdrawal''. Used in BackOffice withdrawal management screens and payout processing reports. (Tier 1 - upstream wiki, Dictionary.CashoutMode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN CashoutModeWeight COMMENT 'Processing priority weight. Higher values are processed first: 0=Manual (lowest), 10=Auto Create, 20=Mass Auto Create, 30=Instant Withdrawal (highest). Used by payout processing to determine execution order. (Tier 1 - upstream wiki, Dictionary.CashoutMode)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN CashoutModeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN CashoutModeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN CashoutModeWeight SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutmode ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:26:56 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 10/10 succeeded
-- ====================
