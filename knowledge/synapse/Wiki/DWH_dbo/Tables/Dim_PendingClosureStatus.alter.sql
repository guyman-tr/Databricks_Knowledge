-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PendingClosureStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus SET TBLPROPERTIES (
    'comment' = 'Dim_PendingClosureStatus is a 3-row dictionary that defines the account closure approval workflow states. When a customer account is flagged for closure (due to regulatory action, fraud, inactivity, or customer request), it moves through a two-step approval process: first suggested (ID=2), then approved (ID=3). ID=1 (No) is the default active state for all customers. This two-step process ensures that account closures -- high-impact, irreversible operations -- require supervisor or compliance officer approval before being finalized. The data originates from `etoro.Dictionary.PendingClosureStatus` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override/full-load strategy) to `Bronze/etoro/Dictionary/PendingClosureStatus/` in the data lake, with UC Bronze table `general.bronze_etoro_dictionary_pendingclosurestatus`. Loaded by `SP_Dictionaries_DL_To_Synapse` via a TRUNCATE + INSERT pattern from `DWH_staging.etoro_Dictionary_PendingClosureStatus`. Refreshes daily. As ...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (PendingClosureStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus ALTER COLUMN PendingClosureStatusID COMMENT 'Primary key identifying the closure workflow state. 1=No (not pending -- default for all active accounts), 2=Suggested for Closure (flagged, awaiting approval), 3=Approved for Closure (approved, will close next cycle). FK target in Dim_Customer and Fact_SnapshotCustomer. Managed by BackOffice.AccountPendingClosureStatusChange on the production platform. (Tier 1 - upstream wiki, Dictionary.PendingClosureStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus ALTER COLUMN PendingClosureStatusName COMMENT 'Human-readable label for the closure state (''No'', ''Suggested for Closure'', ''Approved for Closure''). Displayed in BackOffice customer cards, closure reports, and regulatory compliance screens. (Tier 1 - upstream wiki, Dictionary.PendingClosureStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus ALTER COLUMN PendingClosureStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus ALTER COLUMN PendingClosureStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:24:55 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
