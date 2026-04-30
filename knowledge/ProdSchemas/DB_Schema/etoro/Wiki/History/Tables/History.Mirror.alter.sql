-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.Mirror
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Mirror.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_mirror
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_mirror (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_mirror SET TBLPROPERTIES (
    'comment' = 'Complete audit log for all successful copy-trading mirror operations. Every operation on a mirror relationship (register, unregister, edit balance, change state, pause, resume, detach, alignment) is recorded here by the Mirror Operation Engine (MOE). Each row represents one completed operation, identified by MirrorOperationID. Companion to History.MirrorFail (unsuccessful operations); together they form the full operation audit trail queried by History.GetMirrorOperationDetails. Source: etoro.History.Mirror on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Mirror.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_mirror SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'Mirror',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ID COMMENT 'Auto-incremented audit row ID. CLUSTERED PK. Does NOT equal MirrorID. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MirrorID COMMENT 'The copy-trading relationship ID (FK to Trade.Mirror while active, or the historical MirrorID after deregistration). 71,151 distinct MirrorIDs in current data. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN CID COMMENT 'The copier customer ID. NC index IX_HistoryMirror_CID for efficient lookup of all operations by a copier. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ParentCID COMMENT 'The popular investor''s customer ID. NC index IX_HistoryMirror_ParentCIDCID for queries like "all copiers who ever copied this PI". (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ParentUserName COMMENT 'The popular investor''s username at the time of the operation. Snapshot value - may differ from current username if PI changed their name. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN Amount COMMENT 'The amount associated with this operation, in USD. Semantics vary by MirrorOperationID: registration=initial investment, unregister=realized equity, edit balance=new balance, detach=detached position equity. Can be negative (loss). Uses dbo.dtPrice precision decimal UDT. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN Occurred COMMENT 'When the mirror operation was processed by MOE (or legacy SP). NC index IX_HistoryMirror_Occurred for time-range queries. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN IsActive COMMENT 'Mirror state after this operation: 1=active, 0=deregistered/inactive. Enables reconstruction of mirror lifecycle from this table alone. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ModificationDate COMMENT 'When this row was written to History.Mirror. Defaults to getutcdate(). May differ from Occurred by milliseconds (async processing lag). (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MirrorOperationID COMMENT 'The operation type. FK to Dictionary.MirrorOperation WITH CHECK. Values: 1=Register, 2=UnRegister, 3=EditBalance, 4=ChangeState, 7=Pause, 8=Resume, 9=EditSLPct, 10=Detach, 11=UpdateCalcType, 12=AlignmentStarted, 13=AlignmentEnded. NULL very rare. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MirrorTypeID COMMENT 'Type of mirror (FK to Dictionary.MirrorType). DEFAULT=1. All current data has MirrorTypeID=1 (standard copy-trading mirror). (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN IsOpenOpen COMMENT 'Whether the "open-open" copy mode was enabled for this mirror. When true, the copier mirrors all future positions opened by the PI. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN GuruTPV COMMENT 'Total Portfolio Value of the popular investor at the time of operation. Used to calculate proportional position sizing for the copier. May be NULL for some operation types. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MirrorSL COMMENT 'The mirror-level stop-loss amount in USD at time of operation. DEFAULT=0 (no SL). The amount at which the entire copy relationship auto-closes. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN CloseMirrorActionType COMMENT 'How the mirror was closed, populated on UnRegister (ID=2) operations. NULL for all other operations. Values: 1=normal close (observed in recent data). (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN RealizedEquity COMMENT 'The cumulative realized P&L on the mirror at this operation''s time. The snapshot of closed-position profit/loss. Can be positive (profitable copying) or negative. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN PauseCopy COMMENT 'Whether copy was paused at time of this operation. Set to 1 by Pause (ID=7), 0 by Resume (ID=8). NULL for other operations. DEFAULT NOT specified - NULL means not explicitly set during this operation. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MirrorSLPercentage COMMENT 'The mirror stop-loss as a percentage of invested amount (e.g., 2.0 = 2%). Updated by EditSLPercentage (ID=9) operations. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN InitialInvestment COMMENT 'The original amount invested when the mirror was first registered. Preserved across subsequent operations for reference. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN DepositSummary COMMENT 'Cumulative deposits added to the mirror since registration. Updated on EditBalance (ID=3) operations. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN WithdrawalSummary COMMENT 'Cumulative withdrawals from the mirror since registration. Updated on EditBalance (ID=3) operations. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN SessionID COMMENT 'Browser/app session ID at time of operation. Used for analytics attribution of user actions. NULL for system-triggered operations. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN NetProfit COMMENT 'Net profit on the mirror at this operation''s time. = RealizedEquity + unrealized. Snapshot value. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN UseCopyDividend COMMENT 'Whether the mirror participates in copy dividends. DEFAULT=1 (enabled). When 1, dividends received by the PI''s positions are proportionally credited to the copier. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MIMOOperationTypeID COMMENT 'Mirror-Initiated Money Operation type. FK to Dictionary.MirrorMIMOOperation. DEFAULT=0 (Manual). Values: 0=Manual, 1=CopyDividend, 2=Fees, 3=IndexDividend. Non-zero when a balance change is triggered by a dividend or fee event. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MirrorDividendID COMMENT 'FK to History.MirrorDividend.ID. Populated when MIMOOperationTypeID=1 (CopyDividend), linking this operation to the specific dividend distribution event. 0 in some rows (Position Detach operations) - 0 indicates not linked, not NULL. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ClientRequestGuid COMMENT 'A GUID identifying the original client API request. Used for idempotency - prevents duplicate operations if the same request is retried. NULL for system-initiated operations. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ReopenForMirrorID COMMENT 'When a copier restarts copying the same PI, this references the previous MirrorID that was closed. NULL for initial registrations. Links the new mirror to its predecessor for lifecycle analysis. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN MirrorCalculationType COMMENT 'How the copy proportions are calculated. Updated by UpdateMirrorCalculationType (ID=11) operations. Values: 0=proportional (default), other values = alternative calculation modes. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ReferenceID COMMENT 'External reference identifier for the operation. Used for correlation with external systems (e.g., MOE event IDs). (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN ExternalOperationType COMMENT 'Classifies the external system or trigger that initiated this operation (from ExternalCopyRequestPreProcessor). NULL for internally-initiated operations. (Tier 1 - upstream wiki, etoro.History.Mirror)';
ALTER TABLE main.trading.bronze_etoro_history_mirror ALTER COLUMN (ParentUserName - see #5) COMMENT '(see above - column counted above) (Tier 1 - upstream wiki, etoro.History.Mirror)';

