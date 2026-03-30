-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_dbo.Dealing_IndiciesIntraHour_Clients
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients SET TBLPROPERTIES (
    'comment' = 'Minute-by-minute client-side trading activity for index instruments (SPX500=27, DJ30=28, NSDQ100=32), capturing open positions, volumes, realized/unrealized P&L, and bid/ask prices at each minute of the trading day. Enables intraday analysis of client exposure and P&L dynamics. | Property | Value | |----------|-------| | **Schema** | Dealing_dbo | | **Object Type** | Table | | **Distribution** | ROUND_ROBIN | | **Index** | Clustered (Date ASC) | | **Row Count** | ~12.7M | | **Date Range** | 2022-05-22 -> present | | **Grain** | One row per Date × Minute × InstrumentID × HedgeServerID | | **Refresh** | Daily, via SP_IntraHourIndexReport |'
);

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Date COMMENT 'Trading date';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Minute_Start COMMENT 'Start of the 1-minute interval';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Minute_End COMMENT 'End of the 1-minute interval (= Minute_Start + 1 min)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN InstrumentID COMMENT 'Index instrument (27=SPX500, 28=DJ30, 32=NSDQ100)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN VolumeBuy COMMENT 'Count of new long positions opened/short positions closed in this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN VolumeSell COMMENT 'Count of new short positions opened/long positions closed in this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Buy_Units COMMENT 'Total open long position size in units at minute start';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Buy COMMENT 'Total open long position value in USD at minute start. Formula: `SUM(AmountInUnitsDecimal * FirstBid * ConversionFirst)` for IsBuy=1';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Sell_Units COMMENT 'Total open short position size in units at minute start';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Sell COMMENT 'Total open short position value in USD at minute start. Formula: `SUM(AmountInUnitsDecimal * FirstAsk * ConversionFirst)` for IsBuy=0';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UnrealizedStart COMMENT 'Unrealized P&L across all positions at minute start. Formula: `SUM(AmountInUnitsDecimal * ConversionFirst * (IsBuy?FirstBid-InitForexRate : InitForexRate-FirstAsk) + FullCommissionByUnits)` - excludes newly opened positions in this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UnrealizedEnd COMMENT 'Unrealized P&L at minute end. Uses next minute''s UnrealizedStart value. Formula: `o2.UnrealizedStart` from self-join on `o.toMinute = o2.fromMinute`';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Realized COMMENT 'Realized P&L from positions closed in this minute. Formula: `SUM(NetProfit + FullCommissionOnClose)` for positions with CloseDateID=@DateInt';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Bid COMMENT 'Bid price at minute start (forward-filled from PriceLog). Formula: `pf.FirstBid`';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Ask COMMENT 'Ask price at minute start (forward-filled)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UpdateDate COMMENT 'Row write timestamp';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN HedgeServerID COMMENT 'Hedge server identifier. Added SR-249626 (2024-04-30)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Minute_Start SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Minute_End SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN VolumeBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN VolumeSell SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Buy_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Sell_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UnrealizedStart SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UnrealizedEnd SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Realized SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Ask SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
