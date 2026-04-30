-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Trade.AdminPositionLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_trade_adminpositionlog
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_trade_adminpositionlog (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog SET TBLPROPERTIES (
    'comment' = 'Audit log of all administrative position operations (open/close/compensate), tracking the request lifecycle from creation through execution or rejection. Source: etoro.Trade.AdminPositionLog on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.AdminPositionLog.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Trade',
    'source_table' = 'AdminPositionLog',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN AdminPositionID COMMENT 'Auto-generated surrogate key. IDENTITY seed 3747184 indicates this table was re-seeded after data migration from AdminPositionLogOLD. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN AdminPositionRequestID COMMENT 'Correlation GUID grouping multiple admin position entries from the same batch request. Used for deduplication (CID + RequestID prevents duplicate execution) and for lookups via GetAdminPositionLogByRequestID. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN CID COMMENT 'Customer identifier for the account receiving the admin position. Implicit FK to Customer.CustomerStatic. Indexed for lookup performance. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN InstrumentID COMMENT 'Financial instrument for the position. Implicit FK to Trade.Instrument. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN OpenActionType COMMENT 'Why this admin position was created. Maps to Dictionary.OpenPositionActionType: 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 4=Stock Dividend, 5=Corporate Action, 6=Technical Issue, 7=Operational position adjustment, 8=Add Funds, 9=Reinvestment, 10=Admin, 11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 15=Technical, 16=Alignment, 17=Recurring Investment. Most common: 11 (Stacking). (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN AdminPositionEventID COMMENT 'Event correlation ID for the position creation event in the distributed system. Indexed for event-based lookups. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN AmountInUnits COMMENT 'Number of units/shares for the position. NULL when amount is specified in monetary terms instead. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN Amount COMMENT 'Monetary amount for the position. NULL when amount is specified in units instead. Mutually exclusive with AmountInUnits for most action types. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN HedgeServerID COMMENT 'Hedge server assigned to execute this position. Implicit FK to Trade.HedgeServer. NULL for positions that don''t require hedging. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN RequestOccurred COMMENT 'UTC timestamp when the admin position request was created. Indexed for time-range queries and monitoring. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN UserName COMMENT 'Username of the operator who initiated the request. For automated processes, often contains the CID as a string. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN ExecutionOccurred COMMENT 'UTC timestamp when the position was actually executed (filled). NULL for pending or rejected requests. Indexed for execution monitoring. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN PositionID COMMENT 'The resulting position ID in Trade.PositionTbl after successful execution. NULL until State=3 (Filled). Indexed for reverse lookups from position to admin request. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN State COMMENT 'Current lifecycle state: 1=Pending (created), 2=Placed (sent to execution), 3=Filled (succeeded), 4=Rejected (failed). Source: Dictionary.AdminPositionState. Most rows are State 4 (Rejected, 63%) or State 3 (Filled, 35%). (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN FailReason COMMENT 'Human-readable error description when State=4 (Rejected). Set by SetAdminPositionFailInfo. NULL for non-failed requests. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN ErrorCode COMMENT 'Numeric error code when State=4 (Rejected). Set by SetAdminPositionState or SetAdminPositionFailInfo. NULL for non-failed requests. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN Cusip COMMENT 'CUSIP identifier for US securities. Used for ACATS transfers and US regulatory reporting. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN ApexID COMMENT 'Apex Clearing account/transaction identifier for US brokerage integration. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN Rate COMMENT 'Execution rate/price for the position. NULL until execution occurs. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN RateTime COMMENT 'Timestamp of the rate used for execution. May differ from ExecutionOccurred if rate was captured earlier. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN CheckBalance COMMENT 'Whether to validate the customer has sufficient balance before opening the position. 0=Skip balance check (common for compensations), 1=Enforce balance check. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN IsComputeForHedge COMMENT 'Whether this position should be included in hedge exposure calculations. 0=Exclude from hedging, 1=Include in hedging. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN IsFunded COMMENT 'Whether this is a funded (real asset) position vs a CFD. 1=Funded/real, 0=CFD. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN CompensationReasonID COMMENT 'Reason code for the compensation or admin action. Sourced from Dictionary.CorporateAction.CompensationReasonID in airdrop flows. Most common: 91 (91% of rows). (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN ValidatePositionWorth COMMENT 'Whether to validate minimum position value before opening. 0=Skip validation, 1=Enforce minimum worth check. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN CompensationCreditID COMMENT 'Credit entry ID linking this admin position to a compensation credit record. Added after AdminPositionLogOLD was archived (not present in OLD table). (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';
ALTER TABLE main.bi_db.bronze_etoro_trade_adminpositionlog ALTER COLUMN OrderID COMMENT 'Associated order ID in Trade.Orders for this admin position. Added after AdminPositionLogOLD was archived. Indexed for order-based lookups. (Tier 1 - upstream wiki, etoro.Trade.AdminPositionLog)';

