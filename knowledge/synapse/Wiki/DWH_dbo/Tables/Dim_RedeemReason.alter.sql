-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_RedeemReason
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason SET TBLPROPERTIES (
    'comment' = 'Dim_RedeemReason classifies why a redeem (copy-fund exit / CopyTrading liquidation) failed, was rejected, or was cancelled. When a copier exits a copy relationship, the system must close positions, calculate final value, and transfer funds - this multi-step process can fail at various points. The RedeemReasonID explains what went wrong or why the operation was blocked. (Tier 1 - upstream wiki, Dictionary.RedeemReason) The reasons fall into several categories: pre-validation blocks (trade blocked, funding blocked, dispute, internal user, verification level), processing failures (failed by trading, failed by wallet, server errors), operational decisions (rejected by ops, canceled by ops, canceled by user), and technical errors (data integrity, DB error, NWA validation). ID 20 (TransferNegativeBalanceTerminated) handles copy exits terminated due to negative balance conditions. (Tier 1 - upstream wiki, Dictionary.RedeemReason) Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.e...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (RedeemReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason ALTER COLUMN RedeemReasonID COMMENT 'Primary key identifying the failure/rejection reason (DDL nullable - PK not enforced). Range 1-20, gaps at 17. Referenced by Fact_BillingRedeem.RedeemReasonID. (Tier 1 - upstream wiki, Dictionary.RedeemReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason ALTER COLUMN RedeemReasonName COMMENT 'Internal reason code name. DWH note: renamed from Name in production source. Prefix convention: Rre = Redeem Rejection, ServerError = service failure, Failed = processing failure. Values: RreTradeBlocked(1), RreFundingBlocked(2), RreDisputeProcess(3), RreInternalUser(4), RreVerificationLevel(5), ValidationDataIntegrity(6), RejectedByOps(7), FailedByTrading(8), FailedByWallet(9), CanceledByOps(10), ServerErrorTrading(11), ServerErrorWallet(12), ServerErrorSettings(13), DbError(14), CanceledByUser(15), NwaValidation(16), CancelledByTrading(18), FailedByDelta(19), TransferNegativeBalanceTerminated(20). (Tier 1 - upstream wiki, Dictionary.RedeemReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason ALTER COLUMN UpdateDate COMMENT 'ETL reload timestamp - set to GETDATE() by SP_Dictionaries_DL_To_Synapse on each daily reload. Not a business date. Current value: 2026-03-11. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason ALTER COLUMN RedeemReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason ALTER COLUMN RedeemReasonName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
