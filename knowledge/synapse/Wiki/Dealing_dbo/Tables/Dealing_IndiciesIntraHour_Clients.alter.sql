-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_IndiciesIntraHour_Clients
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients SET TBLPROPERTIES (
    'comment' = 'Dealing_dbo.Dealing_IndiciesIntraHour_Clients > ~13.3M-row minute-level aggregation table capturing client-side intra-hour hedging activity for three index instruments (IDs 27, 28, 32) from 2022-05-22 to present - recording per-minute buy/sell volumes, open position values, unrealized and realized P&L, and bid/ask prices, sourced from Dim_Position + PriceLog via SP_IntraHourIndexReport daily. | Property | Value | |----------|-------| | **Schema** | Dealing_dbo | | **Object Type** | Table | | **Production Source** | DWH_dbo.Dim_Position + CopyFromLake.PriceLog_History_CurrencyPrice via SP_IntraHourIndexReport | | **Refresh** | Daily (1440 min, Append via Generic Pipeline) | | | | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX ([Date] ASC) | | | | | **UC Target** | `general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients` | | **UC Format*'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients SET TAGS (
    'source_schema' = 'Dealing_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Date COMMENT 'Trading date extracted from the minute bucket. CONVERT(DATE, fromMinute). One row per instrument per minute per HedgeServerID per date. (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Minute_Start COMMENT 'Start of the 1-minute time bucket (e.g., ''2026-04-25 14:30:00''). Generated from a minute grid covering the full 24-hour day. (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Minute_End COMMENT 'End of the 1-minute time bucket (Minute_Start + 1 minute, e.g., ''2026-04-25 14:31:00''). (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. Financial instrument being traded. Filtered to three index instruments: 27 (S&P 500), 28 (DJ30), 32 (GER30). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN VolumeBuy COMMENT 'Aggregated USD buy volume for the minute. Combines new long opens (SUM of Volume where IsBuy=1) and short closes (SUM of VolumeOnClose where IsBuy=0). ISNULL defaults to 0. (Tier 2 - Dim_Position)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN VolumeSell COMMENT 'Aggregated USD sell volume for the minute. Combines new short opens (SUM of Volume where IsBuy=0) and long closes (SUM of VolumeOnClose where IsBuy=1). ISNULL defaults to 0. (Tier 2 - Dim_Position)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Buy_Units COMMENT 'Total units (AmountInUnitsDecimal) of all open buy positions at start of this minute. SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal). (Tier 2 - Dim_Position)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Buy COMMENT 'USD-equivalent value of all open buy positions at start of this minute. SUM(AmountInUnitsDecimal × Bid × USDConversionRate). (Tier 2 - Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Sell_Units COMMENT 'Total units of all open sell positions at start of this minute. SUM(CASE WHEN IsBuy=0 THEN AmountInUnitsDecimal). (Tier 2 - Dim_Position)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN OP_Sell COMMENT 'USD-equivalent value of all open sell positions at start of this minute. SUM(AmountInUnitsDecimal × Ask × USDConversionRate). (Tier 2 - Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UnrealizedStart COMMENT 'Aggregate unrealized P&L for all open client positions at start of this minute. SUM(AmountInUnitsDecimal × ConversionRate × (price - InitForexRate) + FullCommissionByUnits), direction-adjusted. Excludes positions opened in the same minute. (Tier 2 - Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UnrealizedEnd COMMENT 'Aggregate unrealized P&L at end of this minute. Equals UnrealizedStart of the next minute (self-join on toMinute=fromMinute). NULL for the last minute of the day. (Tier 2 - Dim_Position / CopyFromLake.PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Realized COMMENT 'Total realized P&L from positions closing in this minute. SUM(NetProfit + FullCommissionOnClose). ISNULL defaults to 0 when no positions close. (Tier 2 - Dim_Position)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Bid COMMENT 'Instrument bid price at start of this minute. LAG of last bid from PriceLog_History_CurrencyPrice, with NULL gap-filling via forward-fill. (Tier 2 - CopyFromLake.PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN Ask COMMENT 'Instrument ask price at start of this minute. LAG of last ask from PriceLog_History_CurrencyPrice, with NULL gap-filling via forward-fill. (Tier 2 - CopyFromLake.PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN UpdateDate COMMENT 'ETL execution timestamp. Set to GETDATE() at SP_IntraHourIndexReport run time. (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients ALTER COLUMN HedgeServerID COMMENT 'FK to Trade.HedgeServer. Hedge server managing this position. Added 2024-04-30 (SR-249626). NULL for pre-2024 rows. (Tier 1 - Trade.PositionTbl)';

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

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:20:06 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 9
-- Statements: 36/36 succeeded
-- ====================
