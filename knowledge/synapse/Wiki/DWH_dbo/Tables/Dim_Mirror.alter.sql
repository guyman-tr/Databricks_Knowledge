-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_Mirror
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Dim_Mirror` is the DWH''s primary record of all copy-trading relationships on the eToro platform. A "mirror" is the connection established when Customer A (the copier, `CID`) chooses to copy Customer B (the copied person, `ParentCID`/`ParentUserName`). Once established, trades opened by B are automatically mirrored proportionally in A''s account, scaled to the mirror''s `Amount`. The table covers the full history of eToro''s social trading product from its earliest CopyTrader relationships in 2011 through the present. It holds 11,145,368 rows across four mirror types: Regular copy (85.2%), Fund mirrors (14.1%), CopyMe/Popular Investor (0.7%), and Smart Portfolio/Social Index (0.001%). **ETL pattern**: Incremental daily differential. The SP (`SP_Dim_Mirror_DL_To_Synapse`) merges updates from two staging sources: 1. `etoro_Trade_Mirror` -- real-time active mirrors (open positions) 2. `etoro_History_Mirror` -- historical/closed mirrors (close events with final P&L) Rows are never deleted from Dim_Mirror ...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror SET TAGS (
    'domain' = 'trading',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (MirrorID)',
    'synapse_index' = 'CLUSTERED INDEX (OpenDateID ASC, MirrorID ASC) + 2 NC indexes (OpenOccurred, ParentCID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorID COMMENT 'Primary key. Allocated by identity on INSERT via Trade.RegisterMirror. Referenced by Trade.Position.MirrorID, History.Mirror. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CID COMMENT 'Copier customer ID. The user who allocates money to follow the leader. Trade.ValidateNumOfActiveMirrors counts mirrors per CID. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN ParentCID COMMENT 'Leader customer ID. The user whose trades are copied. Trade.GetActiveCopiersForParents filters by ParentCID. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN ParentUserName COMMENT 'Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN Amount COMMENT 'Allocation amount in dollars. Credit allocated to this mirror. Trade.RegisterMirror sets from @AmountInCents/100. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN OpenOccurred COMMENT 'Datetime the copy relationship was opened (started). From Trade.Mirror.Occurred. Covers back to 2011-06-13 (first CopyTrader launch). (Tier 2 - SP_Dim_Mirror_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN OpenDateID COMMENT 'yyyymmdd integer of OpenOccurred. Clustered index key -- use for efficient date-range filtering. ETL-computed: `convert(int, convert(varchar, dateadd(day, datediff(day, 0, Occurred), 0), 112))`. (Tier 2 - SP_Dim_Mirror_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CloseOccurred COMMENT 'Datetime the copy relationship was closed. ''1900-01-01 00:00:00'' sentinel = still open (CloseDateID=0). For closed mirrors, this is History.Mirror.ModificationDate at the close event. (Tier 2 - SP_Dim_Mirror_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CloseDateID COMMENT 'yyyymmdd integer of CloseOccurred. 0 = open mirror (active); > 0 = closed on that date. Primary filter for open/closed status. (Tier 2 - SP_Dim_Mirror_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorTypeID COMMENT '1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType). Determines mirror behavior. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CloseMirrorActionType COMMENT 'Why mirror closed: 0=Customer, 1=Stop Loss, 2=BSL, 3=Manual Liquidation, 4=BackOffice, 5=Customer Detach, 6=BackOffice Detach (Dictionary.CloseMirrorActionType). NULL when active. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN IsActive COMMENT '1=mirror is live (copier follows leader), 0=mirror closed. Trade.ChangeMirrorState, Trade.PostClosePositionActions update. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN IsOpenOpen COMMENT 'Flag for open-on-open copy behavior. NULL in sample data. Used by copy logic. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN PauseCopy COMMENT '0=copying, 1=paused. No new positions when paused. Trade.MirrorPauseCopy updates. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorSL COMMENT 'Absolute mirror stop-loss threshold in dollars. Trade.RegisterMirror validates against MirrorSLPercentage. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorSLPercentage COMMENT 'MSL as percentage. Default 2. Trade.RegisterMirror validates MirrorSL = Amount * (MirrorSLPercentage/100). (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN RealizedEquity COMMENT 'Realized equity for this mirror. Used with MirrorCalculationType=0 for MSL. Updated on position close. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN InitialInvestment COMMENT 'Initial allocation. Trade.RegisterMirror sets from @AmountInDollars or @InitialInvestment. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN WithdrawalSummary COMMENT 'Sum of withdrawals from mirror. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN DepositSummary COMMENT 'Sum of deposits into mirror. Trade.RegisterMirror accepts from caller. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN RealziedPnL COMMENT 'Net realized profit/loss of the mirror in USD. NOTE: column name has a typo (''Realzied'' not ''Realized'') - use exact spelling in queries. For closed mirrors: final P&L from History.Mirror.NetProfit. For open mirrors: running net profit. Upstream: DWH column RealziedPnL maps to Trade.Mirror.NetProfit. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN GuruTPV COMMENT 'Guru/leader take-profit value. NULL in sample. Optional override. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN UseCopyDividend COMMENT '1=copy dividends to copier, 0=do not. Trade.MirrorDividendWithdrawal checks. (Tier 1 - Trade.Mirror)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN UpdateDate COMMENT 'ETL run timestamp from the last SP update that touched this row. Set to GETDATE() on each UPDATE/INSERT by the SP. (Tier 2 - SP_Dim_Mirror_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN SessionID COMMENT 'Session identifier from History.Mirror.SessionID at the mirror open event (MirrorOperationID=1). Links the mirror opening to a specific trading session. NULL for older historical mirrors predating SessionID tracking. (Tier 2 - SP_Dim_Mirror_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN IsCopyFundMirror COMMENT '1 if the ParentCID is an eToro Fund account (BackOffice AccountTypeID=9); 0 or NULL for regular customer-to-customer copies. Derived post-load from BackOffice_Customer data. Fund mirrors (IsCopyFundMirror=1) overlap with MirrorTypeID=4. (Tier 2 - SP_Dim_Mirror_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN ParentCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN ParentUserName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN OpenOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN OpenDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CloseOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CloseDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN CloseMirrorActionType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN IsOpenOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN PauseCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorSL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN MirrorSLPercentage SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN InitialInvestment SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN WithdrawalSummary SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN DepositSummary SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN RealziedPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN GuruTPV SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN UseCopyDividend SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN SessionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror ALTER COLUMN IsCopyFundMirror SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:24:39 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 54/54 succeeded
-- ====================
