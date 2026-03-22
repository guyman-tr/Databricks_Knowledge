-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_RedeemStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus SET TBLPROPERTIES (
    'comment' = 'Dim_RedeemStatus tracks the lifecycle of a "redeem" operation - the process of stopping a copy-trading relationship and returning funds to the copier. When a user stops copying another trader, all mirrored positions must be closed, PnL calculated, and remaining equity returned to the copier''s available balance. (Tier 1 - upstream wiki, Dictionary.RedeemStatus) The DWH version has significantly more granular states (13 rows, IDs 0-100) compared to what was documented in the upstream wiki (5 rows, IDs 1-3,5,6). The production Dictionary.RedeemStatus table appears to have evolved substantially since the upstream wiki was written. The DWH reflects the current production state with states covering the full position-closing and transaction processing sub-workflow (PositionPending -> Approved -> ReadyToRedeem -> PositionClosing -> PositionClosed -> TransactionInProcess -> TransactionDone). Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_RedeemStatus. ID=0 (N/A) ...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (RedeemStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN RedeemStatusID COMMENT 'Primary key identifying the redeem lifecycle state. Range: 0 (sentinel), 1-8, 20-21, 25, 100. See full state machine in Section 2. (Tier 1 - upstream wiki, Dictionary.RedeemStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN Name COMMENT 'Internal state code name used in procedures. Values: N/A(0), PositionPending(1), Rejected(2), Approved(3), ReadyToRedeem(4), PositionClosing(5), PositionClosed(6), TransactionInProcess(7), TransactionDone(8), Terminated(20), FailedToCancel(21), TransferNegativeBalance(25), New(100). DWH note: production has evolved significantly since upstream wiki documented 5 states. (Tier 1 concept, Tier 3 values - live data)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN DisplayName COMMENT 'User-facing label. Currently matches Name for most rows. Shown in copy-trading UI and notifications. (Tier 1 - upstream wiki, Dictionary.RedeemStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN IsCancelable COMMENT 'Whether user can cancel the redeem at this stage. True=cancelable, False=positions are closing or closed (point of no return). False: PositionClosed(6), TransactionInProcess(7), TransactionDone(8), Terminated(20). (Tier 1 - upstream wiki, Dictionary.RedeemStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN InsertDate COMMENT 'ETL insertion timestamp. ID=0 sentinel: midnight (CAST(GETDATE() AS DATE)). All other rows: SP execution time. DWH note: not present in production Dictionary.RedeemStatus - added by ETL. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN UpdateDate COMMENT 'ETL reload timestamp - set to GETDATE() on each daily reload. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN RedeemStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN DisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN IsCancelable SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
