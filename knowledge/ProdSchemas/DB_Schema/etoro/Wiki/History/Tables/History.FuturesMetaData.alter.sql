-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.FuturesMetaData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.FuturesMetaData.md
-- Layer: bronze
-- UC Target: main.trading.bronze_etoro_history_futuresmetadata
-- =============================================================================

-- ---- UC Target: main.trading.bronze_etoro_history_futuresmetadata (business_group=trading) ----
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata SET TBLPROPERTIES (
    'comment' = 'SQL Server system-versioned temporal history table for Trade.FuturesMetaData, recording every change to the contract specification parameters for futures instruments including contract size, tick size, expiration dates, and settlement type. Source: etoro.History.FuturesMetaData on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.FuturesMetaData.md).'
);

ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'FuturesMetaData',
    'business_group' = 'trading',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN InstrumentID COMMENT 'The futures instrument whose contract specification is recorded. PK in source (not IDENTITY). One row per instrument in the current table. Implicit FK to Trade.Instrument. 250 distinct instruments in history. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN Multiplier COMMENT 'Contract size multiplier. Defines how many units of the underlying one contract represents. Example: Multiplier=100 for crude oil means 1 contract = 100 barrels. Used in P&L and margin calculations. High precision (20,10) supports small-unit contracts. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN MinimalTick COMMENT 'Minimum price increment (tick size) for this futures instrument. Example: 0.01 for crude oil = minimum $0.01 per barrel price movement per tick. Determines the minimum P&L change per tick = MinimalTick Multiplier IndexPointValue. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN LastTradingDateTime COMMENT 'The last datetime when this futures contract can be actively traded. After this time, positions must be closed or they proceed to physical/cash settlement. Frequently updated as contracts roll to new expiration months. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN ExpirationDateTime COMMENT 'The datetime when the futures contract formally expires and final settlement pricing is calculated. Indexed in source (IX_ExpirationDateTime) for efficient expiration scans. ''2030-01-01'' serves as a sentinel for test/synthetic instruments. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN SettlementTime COMMENT 'The time of day at which the settlement price is determined on the settlement date. Example: ''16:00:00'' (4pm UTC) for InstrumentID=18. The "1970-01-01" date prefix from the MCP query is an artifact of time(7) display. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN IndexPointValue COMMENT 'Dollar value per single index point (or unit). Example: IndexPointValue=1.0 for crude oil means each $1.00 price move = $1 per unit. For index futures like E-mini S&P 500, IndexPointValue=50 means each index point = $50. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN DbLoginName COMMENT 'SQL Server login (suser_name()) at time of change. Observed: "DevTradingSTG" (development/staging service account - direct SQL updates, not a managed ops tool). (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN AppLoginName COMMENT 'Application context from context_info(). NULL in observed data - DevTradingSTG updates are made directly via SQL without setting context_info. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN SysStartTime COMMENT 'UTC timestamp when this contract specification version became active. For INSERT-trigger-captured rows, equals SysEndTime. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN SysEndTime COMMENT 'UTC timestamp when this version was superseded. CLUSTERED index leading column. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN SettlementMethod COMMENT 'How the futures contract settles at expiration. FK to Dictionary.SettlementMethodValues (ID column). 0=Cash settlement (no delivery, cash P&L), 1=Physical settlement (actual asset delivered). NULL for pre-2025 records (column added later). (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
ALTER TABLE main.trading.bronze_etoro_history_futuresmetadata ALTER COLUMN UnitOfMeasure COMMENT 'The physical unit of the underlying commodity or asset. FK to Dictionary.UnitOfMeasure (ID column). 0=Points (index), 1=Barrel, 2=Troy Ounce, 3=MMBtu, 4=Pounds, 5=Short Tons, 6=Euros, 7=Australian Dollars, 8=British Pounds, 9=Ether, 10=Bitcoin, 11=SOL, 12=XRP. NULL for pre-2025 records. (Tier 1 - upstream wiki, etoro.History.FuturesMetaData)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
