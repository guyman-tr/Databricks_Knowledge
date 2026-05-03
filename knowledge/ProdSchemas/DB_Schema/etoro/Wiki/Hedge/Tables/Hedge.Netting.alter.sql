-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Hedge.Netting
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.Netting.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_hedge_netting
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_hedge_netting (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_hedge_netting SET TBLPROPERTIES (
    'comment' = 'Live net hedge position table - stores the current aggregate open hedge position for each (liquidity account, instrument, value date) combination, enabling the hedge server to track what it has already hedged and compute unrealized P&L on the hedge book. Source: etoro.Hedge.Netting on the etoro production database, ingested via the Generic Pipeline (Override strategy, 60-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/Hedge.Netting.md).'
);

ALTER TABLE main.dealing.bronze_etoro_hedge_netting SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Hedge',
    'source_table' = 'Netting',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '60'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN LiquidityAccountID COMMENT 'First component of composite PK. FK to Trade.LiquidityAccounts - identifies which liquidity provider account holds this hedge position. In production, LiquidityAccountID=10 holds the dominant position (713/738 rows), representing the main execution account. Remaining accounts (2145-2152, 354541, etc.) are alternative or testing LP accounts. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN InstrumentID COMMENT 'Second component of composite PK. FK to Trade.Instrument (implicit - no declared constraint). The financial instrument being hedged. Each unique InstrumentID under a given LiquidityAccountID represents a separate hedge book entry. Indexed separately (IX_InstrumentID) to support instrument-level queries. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN Units COMMENT 'The net aggregate size of the open hedge position in units of the instrument. 2 decimal places (vs 6 in ManualOrderExecutionLog) reflects that netting positions are rounded to avoid micro-lot accumulation. Used directly in PnL formula: Units (Bid - AvgRate) UnitMargin/Bid. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN IsBuy COMMENT 'Direction of the net hedge position. true = net long (bought more than sold on the LP), false = net short (sold more than bought). 82% of current positions are long (IsBuy=true), reflecting that eToro''s customer book is predominantly long across most instruments - requiring the hedge server to hold corresponding long positions. Used as a sign multiplier in PnL calculation (1 for long, -1 for short). (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN AvgRate COMMENT 'Volume-weighted average entry rate of the current net position, using the custom dbo.dtPrice type. This is the blended price across all hedge executions that make up the current netting position. Used in PnL formula as cost basis: Bid - AvgRate gives the gain/loss per unit since entry. For positions built up over many trades, this will differ from the current market rate, reflecting accumulated execution. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN ValueDate COMMENT 'Third component of composite PK. The settlement/delivery date with the liquidity provider - when the actual transfer of underlying assets or cash occurs for the hedge position. DATE type (no time component) reflects that settlement dates are calendar-day boundaries. While included in the PK, the AddOrUpdateNetting upsert updates this column on each position change, so effectively one ValueDate exists per (LiquidityAccountID, InstrumentID) pair at any time. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN ExecTime COMMENT 'Timestamp of the last hedge execution that contributed to this position (nanosecond precision via datetime2(7)). Set by AddOrUpdateNetting from the @ExecTime parameter. Differs from UpdateTime in that ExecTime reflects when the market execution occurred, while UpdateTime reflects when the database was updated. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN UpdateTime COMMENT 'Timestamp when this netting position row was last written to the database. Set by AddOrUpdateNetting from the @UpdateTime parameter. In practice, ExecTime and UpdateTime are within milliseconds of each other (they''re set together in the same call). UpdateTime determines SysStartTime in the temporal versioning system. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN HedgeServerID COMMENT 'FK to Trade.HedgeServer (implicit). Identifies which hedge server instance manages this position. HedgeServerID=1 dominates (713/738 rows = the primary production hedge server). Additional server IDs (5, 8, 9, 12, 222, 1100, 5454) represent test environments or secondary hedge server instances. RemoveBadNetting uses this column to clean up positions that appear under the wrong LiquidityAccountID for a given HedgeServer. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN SysStartTime COMMENT 'System-generated temporal column. Records when this version of the row became current (UTC). Set automatically by SQL Server when the row is inserted or updated. Combined with SysEndTime enables FOR SYSTEM_TIME AS OF point-in-time queries across Hedge.Netting and History.Netting_History. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
ALTER TABLE main.dealing.bronze_etoro_hedge_netting ALTER COLUMN SysEndTime COMMENT 'System-generated temporal column. Records when this version of the row stopped being current. For all current (live) rows: value = 9999-12-31 23:59:59.9999999 (the "forever" sentinel meaning "currently valid"). When a row is updated or deleted, the old version is moved to History.Netting_History with SysEndTime = the update/delete timestamp. (Tier 1 - upstream wiki, etoro.Hedge.Netting)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
