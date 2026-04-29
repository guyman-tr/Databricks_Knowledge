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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReasonID COMMENT 'Internal money movement reason identifier. DWH values: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 4=Airdrop (DWH-only label). Production has additional IDs 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment - all absent from DWH. ID=5 is critical: used in SP_Fact_CustomerAction to derive ActionTypeID 44 (internal deposit) and 45 (internal withdrawal). (Tier 1 - upstream wiki, Dictionary.MoveMoneyReason)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReason COMMENT 'Human-readable money movement reason label. DWH labels: Adjustment, Bonus Abuser, Staking, Airdrop. Column name intentionally matches table name (denormalized pattern per upstream wiki). Used in financial reporting and account statements. Note: DWH label "Airdrop" for ID=4 diverges from production where ID=4 is marked deprecated. (Tier 1 - upstream wiki, Dictionary.MoveMoneyReason + Tier 3 - live data sampling)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN UpdateDate COMMENT 'Last update timestamp for the row. IDs 1-3: 2022-03-27 (initial load batch); ID 4: 2022-11-13 (added 8 months later). Suggests manual DBA inserts; not populated by an automated pipeline. Not present in production Dictionary.MoveMoneyReason (DWH-specific audit field). (Tier 3 - live data sampling)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN MoveMoneyReason SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:24:46 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 8/8 succeeded
-- ====================
