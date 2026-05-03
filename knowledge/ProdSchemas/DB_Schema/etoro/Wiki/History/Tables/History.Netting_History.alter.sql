-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.Netting_History
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Netting_History.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_history_netting_history
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_history_netting_history (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_history_netting_history SET TBLPROPERTIES (
    'comment' = 'SQL Server temporal history table automatically maintained by the database engine, recording every past state of Hedge.Netting - the real-time net hedge position table that tracks eToro''s aggregated exposure per instrument per liquidity account. Source: etoro.History.Netting_History on the etoro production database, ingested via the Generic Pipeline (Append strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Netting_History.md).'
);

ALTER TABLE main.dealing.bronze_etoro_history_netting_history SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'Netting_History',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN LiquidityAccountID COMMENT 'The liquidity provider account holding this hedge position. FK to Trade.LiquidityAccounts (enforced on Hedge.Netting, not in history). Part of the composite PK on the live table. Examples: LiquidityAccountID=10 = specific broker/LP account. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN InstrumentID COMMENT 'The financial instrument being hedged. Part of the live table''s composite PK (LiquidityAccountID, InstrumentID, ValueDate). References Trade.Instrument/History.Instrument (no FK in history). (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN Units COMMENT 'The net number of units hedged at the liquidity provider for this (account, instrument, value date) combination. Positive values represent a net open position. The netting aggregates all customer positions to a single number. NULL theoretically possible but not expected. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN IsBuy COMMENT 'The direction of the net hedge: TRUE (1) = net long (eToro is long via the LP), FALSE (0) = net short. Represents the dominant direction of eToro''s aggregate customer exposure for this instrument. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN AvgRate COMMENT 'The volume-weighted average execution rate for the current net hedge position. dbo.dtPrice is a UDT (decimal) for price values. Used to calculate the cost basis of the hedge and to compute hedge P&L. Changes with each new hedge execution. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN ValueDate COMMENT 'The settlement date for this hedge position. For FX instruments: T+2 settlement. Part of the live table''s composite PK - multiple value dates may exist for the same (LiquidityAccountID, InstrumentID) pair. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN ExecTime COMMENT 'UTC timestamp when the hedge was executed at the liquidity provider. May differ from UpdateTime and SysStartTime due to processing pipeline latency. NULL if execution time was not captured. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN UpdateTime COMMENT 'UTC timestamp when the Hedge.Netting row was last modified. Tracks when the hedging server updated the netting position. May equal ExecTime for immediate updates or differ by processing latency. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN HedgeServerID COMMENT 'The identifier of the hedge server instance that manages this position. References the hedging infrastructure component responsible for executing and managing the hedge orders at this liquidity provider. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this row version became current in Hedge.Netting. Populated automatically by SQL Server SYSTEM_VERSIONING (GENERATED ALWAYS AS ROW START). (Tier 1 - upstream wiki, etoro.History.Netting_History)';
ALTER TABLE main.dealing.bronze_etoro_history_netting_history ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this hedge state was superseded. The interval [SysStartTime, SysEndTime) represents how long this particular net position existed before being updated. Short intervals indicate high-frequency position changes. (Tier 1 - upstream wiki, etoro.History.Netting_History)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
