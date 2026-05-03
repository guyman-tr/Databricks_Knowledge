-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.ExecutionLog
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExecutionLog.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_hedge_executionlog
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_hedge_executionlog (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog SET TBLPROPERTIES (
    'comment' = 'High-volume append-only log of every hedge order execution event - each row captures a single state transition (sent, partial fill, fill, reject, cancel) from a liquidity provider, enabling fill rate analysis, latency measurement, and execution discrepancy detection. Source: etoro.Hedge.ExecutionLog on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.ExecutionLog.md).'
);

ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'ExecutionLog',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN LogTime COMMENT 'DB server UTC timestamp at row insert, set to GETUTCDATE() by LogExecution and ExecutionLogInsertBulk. Clustered index key - rows are physically ordered by log insert time. Used as the primary range filter for all time-window queries. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN HedgeServerID COMMENT 'FK to Trade.HedgeServer(HedgeServerID). The hedge server that generated and sent this execution order to the provider. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN LiquidityAccountID COMMENT 'FK to Trade.LiquidityAccounts(LiquidityAccountID). The liquidity provider account on which this order was executed. Used as a grouping key in the NC index and latency reports. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN InstrumentID COMMENT 'The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN OrderID COMMENT 'Internal hedge order identifier. Legacy path: positive bigint matching the hedge order system. EMS/HBC path: -1 (not applicable - EMSOrderID is the key instead). Not the OrderID from Trade.OpenedPositions - this is the hedge system''s own order tracking ID. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ParentOrderID COMMENT 'GUID identifying the parent hedge order that spawned this execution. EMS path: GUID(0) (all zeros = no parent). Legacy path: the parent hedge order GUID. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN IsBuy COMMENT 'Direction of the hedge order from eToro''s perspective: 1=Buy, 0=Sell. A hedge order direction is typically the opposite of the customer net position. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN OrderState COMMENT 'FK to Dictionary.HedgeOrderState (WITH NOCHECK). Current state of this order row: 0=None, 1=Sent, 2=New, 3=Partial, 4=Fill, 5=Reject, 6=Fail, 7=Cancelled. One order generates multiple rows as it transitions through states. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ProviderOrderID COMMENT 'The order ID assigned by the liquidity provider (typically a GUID from FIX protocol). Populated when the provider acknowledges the order (OrderState >= 2). Used for reconciliation with provider statements. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN SendTime COMMENT 'Precision timestamp when the order was dispatched to the liquidity provider. Used for Metric 1 (Request_Process_Time = RequestTime to SendTime) in latency analysis. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ProviderExecID COMMENT 'Execution confirmation ID from the liquidity provider (GUID format). Populated on fill or partial fill (OrderState 3/4). Used for trade reconciliation and dispute resolution with the provider. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ExecutionTime COMMENT 'The provider''s own timestamp for when the execution occurred. May differ from ReceivedTime due to network latency. Used as the authoritative trade timestamp for P&L calculations. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ExecutionRate COMMENT 'The actual execution price returned by the liquidity provider. Used in weighted average rate calculation: SUM(Units * ExecutionRate) / SUM(Units) by GetExecutionLogData. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN FailID COMMENT 'Numeric error/failure code from the provider or internal routing system. Populated when Success=0. Used for categorizing reject reasons in monitoring. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN FailReason COMMENT 'Free-text rejection reason from the provider. Populated when Success=0. Typical reasons include price stale, no liquidity, size exceeded, connection failure. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN Success COMMENT 'Indicates whether this execution event represents a successful outcome: 1=successful fill or partial fill; 0=rejection or failure. Used as a filter key in the NC index and fill rate calculations. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ProviderPartyIds COMMENT 'FIX protocol party identifiers from the execution report (e.g., clearing firm, broker, settlement IDs). Populated for providers using FIX party tags. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ReceivedTime COMMENT 'Precision timestamp when the hedge server received the execution response from the provider. Metric 2 = DATEDIFF(ms, SendTime, ReceivedTime) = Provider round-trip latency. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN RateIDAtSent COMMENT 'ID of the price rate snapshot that was active when the order was sent. Used for slippage analysis by comparing execution rate vs. rate at send time. NULL for EMS orders where rate tracking uses a different mechanism. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN OMSProviderExecID COMMENT 'OMS (Order Management System) execution confirmation ID. Populated for OMS-routed orders. NULL for direct EMS orders (OrderID=-1 in recent data). (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN OMSProviderOrderID COMMENT 'OMS order ID for orders routed through the OMS layer. NULL for direct EMS orders. Enables reconciliation with OMS-side execution records. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN Units COMMENT 'The quantity of units requested in the hedge order. High precision (22,8) to support both large quantities and fractional instruments (crypto). (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN ProviderUnits COMMENT 'The quantity actually executed by the provider in this event. For partial fills, ProviderUnits < Units. Sum of ProviderUnits across all OrderState=3 rows for an order gives total filled. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
ALTER TABLE main.dealing.bronze_etoro_hedge_executionlog ALTER COLUMN EMSOrderID COMMENT 'EMS (Execution Management System) order identifier. Format: "{ExternalID}_{sequence}" (e.g., "35564138_1"). The primary key for EMS/HBC flow orders (when OrderID=-1). Used as the join key in SSRS_Latency_Report and by GetExecutionLogData for partial fill aggregation. (Tier 1 - upstream wiki, etoro.Hedge.ExecutionLog)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
