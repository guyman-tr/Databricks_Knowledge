-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.OrdersExitTbl
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.OrdersExitTbl.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_ordersexittbl
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_ordersexittbl (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl SET TBLPROPERTIES (
    'comment' = 'Archive of closed copy-trading exit orders. When a CopyTrader exit order in Trade.OrdersExitTbl is closed, it is atomically moved here via DELETE...OUTPUT INTO by Trade.AsyncOrdersChangeLog (ExitOrderPostActions, OperationTypeID=2). Each row represents a completed exit order from the Copy Trading system, linking the copier (CID, MirrorID) to the specific position being closed (PositionID). Source: etoro.History.OrdersExitTbl on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.OrdersExitTbl.md).'
);

ALTER TABLE main.general.bronze_etoro_history_ordersexittbl SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'OrdersExitTbl',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN OrderID COMMENT 'Exit order ID, matching Trade.OrdersExitTbl.OrderID. Preserved via DELETE...OUTPUT INTO. PK. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN CID COMMENT 'Copier customer ID. NOT NULL (unlike History.OrdersEntryTbl.CID which is nullable). All 4,208 rows have CID. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN PositionID COMMENT 'The copier''s position being closed. bigint (changed from int in Nov 2021 for large position IDs). NC index (CID, PositionID) enables efficient lookup. 1,716 distinct positions in current data. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN OpenOccurred COMMENT 'When the exit order was created/opened (the start of the exit process). (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN CloseOccurred COMMENT 'When the exit order was completed. Set to GETUTCDATE() at close time; DEFAULT = getutcdate() as safety net. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN CloseActionType COMMENT 'How/why the exit order completed. Values: 0=default, 1=normal, 2=alternate, 3=mirror-stop or market-close, 4=parent-position-closed (dominant at 58%), 6=special. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN MirrorID COMMENT 'The copy relationship ID. Always populated in current data (all 4,208 rows). Links to Trade.Mirror. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN MirrorCloseActionType COMMENT 'How the mirror relationship was closed at the time of this exit order. 0 = mirror still active when position was exited. Non-zero = exit triggered by mirror deregistration with a specific reason code. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN OpenActionType COMMENT 'Type of the action that opened this exit order. DEFAULT=0. Most current rows have OpenActionType=1. Classifies the trigger for initiating the exit order. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN RedeemID COMMENT 'Links this exit order to a redemption operation if the close was triggered by a redeem event. NULL for all current rows (no redemption-triggered closes in this dataset). (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN RedeemReasonID COMMENT 'The reason for the redemption if RedeemID is set. NULL when RedeemID is NULL. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN UnitsToDeduct COMMENT 'For partial-close-by-units operations: the number of units being closed in this exit order. NULL = full position close. NULL for all current rows. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersexittbl ALTER COLUMN CloseByUnitsID COMMENT 'The identifier of the close-by-units operation that initiated this partial close. NULL when UnitsToDeduct is NULL. (Tier 1 - upstream wiki, etoro.History.OrdersExitTbl)';

