-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_PnL
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Fact_PnL > 8.8B-row granular daily P&L fact table tracking unrealized PnL changes and realized net profit per customer × instrument type × position flags since 2015. Sourced from `Function_PnL_Single_Day` (which reads `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument`), aggregated by `SP_DDR_Fact_PnL` with daily DELETE/INSERT by DateID. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Multiple - `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument` via `Function_PnL_Single_Day` TVF | | **Refresh** | Daily (DELETE/INSERT by DateID) | | | | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX | | | | | **UC Target** | _Pending - resolved during write-objects_ | | **UC Format** | _Pending - resolved during write-objects_ | | **UC Partitioned By** | _Pend'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN DateID COMMENT 'Date key in YYYYMMDD integer format. Partition/filter key for daily DELETE/INSERT. Direct from `Function_PnL_Single_Day.DateID`. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN Date COMMENT 'Calendar date corresponding to DateID. `@date` SP input parameter. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN RealCID COMMENT 'Customer identifier. Renamed from `CID` in `Function_PnL_Single_Day`. Distribution key. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN InstrumentTypeID COMMENT 'Instrument asset class. Join-enriched from `Dim_Instrument.InstrumentTypeID` via `frfc.InstrumentID = di.InstrumentID`. Common values: 4=Indices, 5=Stocks, 6=Commodities, 10=Crypto, 12=ETFs, 73=Currencies. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopy COMMENT 'Copy-trade flag. `CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END`. 1=position opened via CopyTrader, 0=manual/independent. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UnrealizedPnLChange COMMENT 'Day-over-day change in unrealized P&L in USD. `SUM(frfc.UnrealizedPnLChange)` aggregated across all positions in the group. Represents the daily mark-to-market movement for open positions. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN NetProfit COMMENT 'Realized net profit in USD from positions closed on this date. `SUM(frfc.NetProfit)` aggregated across closed positions in the group. Zero for groups with no closes. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN CountPositions COMMENT 'Number of positions contributing to this row''s PnL. `COUNT(frfc.PositionID)` within the group. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsFuture COMMENT 'Futures contract flag. `ISNULL(frfc.IsFuture, 0)`. 1=futures position, 0=non-futures. NULL coerced to 0. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsLeveraged COMMENT 'Leverage flag. `CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END`. 1=leveraged position (leverage multiplier > 1×), 0=unleveraged. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsBuy COMMENT 'Trade direction. 1=long (buy), 0=short (sell). Direct from `Function_PnL_Single_Day.IsBuy`. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopyFund COMMENT 'Smart Portfolio / Fund position flag. `ISNULL(frfc.IsCopyFund, 0)`. 1=position belongs to a Smart Portfolio or Fund vehicle, 0=regular. Derived from `BI_DB_CopyFund_Positions` lookup in the function. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSQF COMMENT 'Sustainable & Quality-Focused instrument flag. `ISNULL(frfc.IsSQF, 0)`. 1=instrument is SQF-classified via `Function_Instrument_Snapshot_Enriched`, 0=non-SQF. (Tier 2 - SP_DDR_Fact_PnL)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UnrealizedPnLChange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN NetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN CountPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsLeveraged SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopyFund SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSQF SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:45:34 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 32/32 succeeded
-- ====================
