-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.Mirror
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Mirror.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_trade_mirror
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_trade_mirror (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_trade_mirror SET TBLPROPERTIES (
    'comment' = 'Copy-trading mirror/follow relationship table that links copiers (CID) to leaders (ParentCID) with allocation amount, stop-loss, and copy-state settings. Source: etoro.Trade.Mirror on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.Mirror.md).'
);

ALTER TABLE main.trading.bronze_etoro_trade_mirror SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'Mirror',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN MirrorID COMMENT 'Primary key. Allocated by identity on INSERT via Trade.RegisterMirror. Referenced by Trade.Position.MirrorID, History.Mirror. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN CID COMMENT 'Copier customer ID. The user who allocates money to follow the leader. Trade.ValidateNumOfActiveMirrors counts mirrors per CID. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN ParentCID COMMENT 'Leader customer ID. The user whose trades are copied. Trade.GetActiveCopiersForParents filters by ParentCID. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN ParentUserName COMMENT 'Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN Amount COMMENT 'Allocation amount in dollars. Credit allocated to this mirror. Trade.RegisterMirror sets from @AmountInCents/100. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN Occurred COMMENT 'When the mirror was created. Default getutcdate(). Used for ordering and time-series. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN IsActive COMMENT '1=mirror is live (copier follows leader), 0=mirror closed. Trade.ChangeMirrorState, Trade.PostClosePositionActions update. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN MirrorTypeID COMMENT '1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType). Determines mirror behavior. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN IsOpenOpen COMMENT 'Flag for open-on-open copy behavior. NULL in sample data. Used by copy logic. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN GuruTPV COMMENT 'Guru/leader take-profit value. NULL in sample. Optional override. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN MirrorSL COMMENT 'Absolute mirror stop-loss threshold in dollars. Trade.RegisterMirror validates against MirrorSLPercentage. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN CloseMirrorActionType COMMENT 'Why mirror closed: 0=Customer, 1=Stop Loss, 2=BSL, 3=Manual Liquidation, 4=BackOffice, 5=Customer Detach, 6=BackOffice Detach (Dictionary.CloseMirrorActionType). NULL when active. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN RealizedEquity COMMENT 'Realized equity for this mirror. Used with MirrorCalculationType=0 for MSL. Updated on position close. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN PauseCopy COMMENT '0=copying, 1=paused. No new positions when paused. Trade.MirrorPauseCopy updates. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN MirrorSLPercentage COMMENT 'MSL as percentage. Default 2. Trade.RegisterMirror validates MirrorSL = Amount * (MirrorSLPercentage/100). (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN InitialInvestment COMMENT 'Initial allocation. Trade.RegisterMirror sets from @AmountInDollars or @InitialInvestment. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN DepositSummary COMMENT 'Sum of deposits into mirror. Trade.RegisterMirror accepts from caller. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN WithdrawalSummary COMMENT 'Sum of withdrawals from mirror. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN NetProfit COMMENT 'Net profit for mirror. Trade.RegisterMirror accepts from caller. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN UseCopyDividend COMMENT '1=copy dividends to copier, 0=do not. Trade.MirrorDividendWithdrawal checks. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN ReopenForMirrorID COMMENT 'When mirror reopened, points to closed MirrorID. Trade.MirrorReopen sets. Prevents duplicate reopens. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN MirrorCalculationType COMMENT '0=RealizedEquity, 1=UnrealizedEquity (Dictionary.MirrorCalculationType). Which equity drives MSL. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';
ALTER TABLE main.trading.bronze_etoro_trade_mirror ALTER COLUMN MirrorStatusID COMMENT '0=Active, 1=Pause, 2=PendingClose, 3=InAlignment (Dictionary.MirrorStatus). IX_MirrorStatusID supports lookups. (Tier 1 - upstream wiki, etoro.Trade.Mirror)';

