-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PaymentStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_PaymentStatus` is the lookup table for payment/deposit transaction status codes on the eToro platform. Every deposit or funding transaction carries a PaymentStatusID that identifies where in the payment lifecycle it is, or how it was resolved. The 40 statuses span 6 functional categories: | Category | IDs | Examples | |----------|-----|---------| | **Active/Pending** | 1, 4, 5, 13, 36 | New, Technical, InProcess, Pending, PendingReview | | **Success** | 2, 7 | Approved, Confirmed | | **Generic Decline** | 3, 31-35 | Decline, DeclineBinConflictCountry, DeclineSecurityValidation | | **Block-based Decline** | 8-12, 14-24, 28-29 | DeclineBlockCard, DeclinedBlockedPayPal, DeclinedBlockedCountry | | **Chargeback/Refund** | 11, 12, 25-27, 37-39 | Chargeback, Refund, ChargebackReversal, MigratedToDepositTable | | **Cancellation** | 6 | Canceled | PaymentStatusID=-1 is a DWH null-sentinel (manually inserted, UpdateDate at midnight vs. 02:12 for SP-loaded rows). PaymentStatusIDs 1-39 are loaded from `et...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus SET TAGS (
    'domain' = 'billing',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (PaymentStatusID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN PaymentStatusID COMMENT 'Primary key identifying the payment state. 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed. (Tier 1 - Dictionary.PaymentStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN Name COMMENT 'Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. (Tier 1 - Dictionary.PaymentStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN DWHPaymentStatusID COMMENT 'Always equal to PaymentStatusID for IDs >= 1. Exception: PaymentStatusID=-1 has DWHPaymentStatusID=0 (manual sentinel). Standard DWH DWH{X}ID pattern. Do not use for JOINs. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 for all SP-loaded rows. Conveys no information. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- GETDATE() at load time for SP-loaded rows; midnight timestamp for PaymentStatusID=-1 (manually inserted). (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN InsertDate COMMENT 'ETL load timestamp -- GETDATE() at load time (same as UpdateDate). Midnight for PaymentStatusID=-1. (Tier 2 -- SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN PaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN DWHPaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');

