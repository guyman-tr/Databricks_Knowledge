-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_MoveMoneyReason
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_MoveMoneyReason enumerates the business reasons for internal money movements - balance credits and debits that are not standard customer deposits or withdrawals. These are recorded in the ActiveCredit system (History.ActiveCredit) and flow into DWH_dbo.Fact_CustomerAction via the MoveMoneyReasonID column passthrough. In production, Dictionary.MoveMoneyReason has 9 reason codes spanning manual adjustments, bonus abuse reversals, crypto staking rewards, internal account transfers, and recurring automated investments. The DWH version is a truncated 4-row table covering only IDs 1-3 (Adjustment, Bonus Abuser, Staking) and ID 4 (Airdrop - which production marks as "missing/deprecated"). Critical gap: MoveMoneyReasonID=5 (InternalTransfer Trade) is used by SP_Fact_CustomerAction to classify ActionTypeID 44 (internal deposit) and 45 (internal withdrawal), but ID=5 does NOT appear in this DWH lookup table. Fact_CustomerAction rows with MoveMoneyReasonID=5 will not find a match in a JOIN to Dim_MoveMone...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (MoveMoneyReasonID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReasonID COMMENT 'Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures. (Tier 1 - Dictionary.MoveMoneyReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReason COMMENT 'Human-readable money movement reason label matching the denormalized table-name pattern noted in the upstream wiki. Production ID 4 is missing and only possibly deprecated per the upstream wiki - the DWH label ''Airdrop'' for that ID cannot be confirmed from Tier-1 sources.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN UpdateDate COMMENT 'ETL-added timestamp recording when each row was last loaded or refreshed by the generic dictionary pipeline. Not present in the production source table. (Tier 2 - Generic Pipeline ETL)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReason SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:24:46 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
