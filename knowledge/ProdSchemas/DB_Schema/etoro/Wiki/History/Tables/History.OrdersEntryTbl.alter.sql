-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.OrdersEntryTbl
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.OrdersEntryTbl.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_ordersentrytbl
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_ordersentrytbl (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl SET TBLPROPERTIES (
    'comment' = 'Archive of closed copy-trading "open-open" entry orders. When a CopyTrader entry order in Trade.OrdersEntryTbl is closed, it is atomically moved here via DELETE...OUTPUT INTO by Trade.AsyncOrdersChangeLog (OperationTypeID=2). Every row represents a completed entry order from the Copy Trading open-open flow, linking the copier (CID, MirrorID) to the parent position being copied (ParentPositionID). Source: etoro.History.OrdersEntryTbl on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.OrdersEntryTbl.md).'
);

ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'OrdersEntryTbl',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN OrderID COMMENT 'Copy-trading entry order ID, matching Trade.OrdersEntryTbl.OrderID. Preserved from the live table via DELETE...OUTPUT INTO. PK of this table. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN CID COMMENT 'Copier customer ID. Always populated in current data (all 3,762 rows have CID). Indexed via IX_HOrdersEntry_CID for efficient copier-based lookups. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN InstrumentID COMMENT 'The instrument being copied. In current data, all rows have InstrumentID=5 (EURUSD). Represents the parent position''s instrument. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN Leverage COMMENT 'Leverage applied to this entry order. All current rows have Leverage=30 (30x, consistent with EURUSD standard leverage). (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN Amount COMMENT 'The copier''s proportional dollar amount for this entry order (the copier''s share of the parent position size). $3.52-$4.94 in observed data, reflecting small proportional shares. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN IsBuy COMMENT 'Direction: 1=Buy (long), 0=Sell. All current rows are IsBuy=true (matching the parent''s long position). (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN StopLosPercentage COMMENT 'Stop-loss as a percentage of the copy amount. 0 for all observed rows (no percentage-based SL configured). (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN TakeProfitPercentage COMMENT 'Take-profit as a percentage of the copy amount. 0 for all observed rows. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN OpenOccurred COMMENT 'When the entry order was opened. Copied from Trade.OrdersEntryTbl.Occurred (column renamed in history). For observed rows, this is at the start of each 60-minute interval. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN CloseActionType COMMENT 'How the entry order was closed. Values: 0=default/no reason, 1=normal close (dominant), 2=alternate close, 4=exit order created for parent (triggers SynchOrdersEntry). (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN ClosedOccurred COMMENT 'When the entry order was closed. Set by Trade.OrderEntryClose via CloseOccurred=GETUTCDATE() before archival. DEFAULT = getutcdate() (safety net). (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN ParentPositionID COMMENT 'The popular investor''s position ID being copied. Always populated in current data. Bigint since positionIDs exceed int range (changed in Nov 2021 per SP comment). (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN MirrorID COMMENT 'The copy relationship ID. Always populated in current data. Links to Trade.Mirror which holds the copier-popular-investor pairing. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN InitialMirrorAmountInCents COMMENT 'The total allocated copy amount for this mirror relationship, in cents (e.g., 35000 = $350). Used as the basis for calculating the proportional copy amount for this entry order. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN IsTslEnabled COMMENT 'Whether trailing stop-loss was enabled. DEFAULT=0. All current rows have IsTslEnabled=0. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN AmountInUnitsDecimal COMMENT 'Amount expressed in fractional units. 0 for all observed rows in current data. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN OrderTypeID COMMENT 'Type of the entry order. DEFAULT=13 (used for all 3,762 rows). OrderTypeID=13 represents the copy-trading "open-open" entry order type. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN OpenOpenOperationTypeID COMMENT 'Type of the open-open operation that created this entry. All current rows have OpenOpenOperationTypeID=1. Classifies the trigger for the copy position opening. (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';
ALTER TABLE main.general.bronze_etoro_history_ordersentrytbl ALTER COLUMN IsDiscounted COMMENT 'Whether a discounted spread was applied. false=no discount for all observed rows. Added in FB 53719 (Free Stocks). (Tier 1 - upstream wiki, etoro.History.OrdersEntryTbl)';

