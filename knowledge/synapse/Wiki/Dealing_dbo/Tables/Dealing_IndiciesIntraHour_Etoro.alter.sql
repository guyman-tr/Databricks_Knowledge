-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_IndiciesIntraHour_Etoro
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro SET TBLPROPERTIES (
    'comment' = 'Dealing_dbo.Dealing_IndiciesIntraHour_Etoro > ~8.7M-row minute-level aggregation table capturing eToro''s hedge-side intra-hour activity for three index instruments (hedge IDs 254, 255, 259 mapping to S&P 500, DJ30, GER30) from 2022-05-22 to present - recording per-minute execution volumes, net open position (NOP) in units and USD, position values, and realized P&L per liquidity account, sourced from hedge execution logs and netting data via SP_IntraHourIndexReport daily. | Property | Value | |----------|-------| | **Schema** | Dealing_dbo | | **Object Type** | Table | | **Production Source** | etoro_Hedge_ExecutionLog + etoro_Hedge_Netting + PriceLog via SP_IntraHourIndexReport | | **Refresh** | Daily (1440 min, Append via Generic Pipeline) | | | | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX ([Date] ASC) | | | | | **UC Target** | `general.gold_sql_dp_'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro SET TAGS (
    'source_schema' = 'Dealing_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Date COMMENT 'Trading date extracted from the minute bucket. CONVERT(DATE, fromMinute). One row per instrument per minute per liquidity account per HedgeServerID per date. (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN InstrumentID COMMENT 'Hedge instrument ID. Represents the hedge-mapped instrument used for execution with liquidity providers, mapped from original index instruments (27/28/32) via PortfolioConversionConfigurations. Current hedge IDs: 254, 255, 259. FK to Trade.Instrument. (Tier 2 - etoro_Hedge_ExecutionLog / etoro_Hedge_PortfolioConversionConfigurations)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Minute_Start COMMENT 'Start of the 1-minute time bucket (e.g., ''2026-04-25 14:30:00''). Generated from a minute grid covering the full 24-hour day. (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Minute_End COMMENT 'End of the 1-minute time bucket (Minute_Start + 1 minute, e.g., ''2026-04-25 14:31:00''). (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN LiquidityAccountName COMMENT 'Name of the liquidity provider account used for hedge execution. Resolved from etoro_Trade_LiquidityAccounts via JOIN on LiquidityAccountID. Current values: ''EMSX Marex Indices Real'', ''EMSX Marex MAEX Real''. (Tier 2 - etoro_Trade_LiquidityAccounts)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN LiquidityAccountID COMMENT 'Liquidity provider account identifier. FK to Trade.LiquidityAccounts. Used as a grouping dimension - each row represents one liquidity account per minute. Current IDs: 275, 317. (Tier 2 - etoro_Hedge_ExecutionLog)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN VolumeBuy COMMENT 'USD-equivalent buy volume from hedge executions in the minute. SUM(Units * ExecutionRate) for IsBuy=1 from ExecutionLog, multiplied by USD ConversionFirst from PriceLog. ISNULL defaults to 0. (Tier 2 - etoro_Hedge_ExecutionLog / PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN VolumeSell COMMENT 'USD-equivalent sell volume from hedge executions in the minute. SUM(Units * ExecutionRate) for IsBuy=0 from ExecutionLog, multiplied by USD ConversionFirst from PriceLog. ISNULL defaults to 0. (Tier 2 - etoro_Hedge_ExecutionLog / PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Units_NOP COMMENT 'Net open position in units from netting data. SUM(Units * (2*IsBuy-1)): positive = net long, negative = net short. Sources: etoro_Hedge_Netting (current) UNION etoro_History_Netting_History (historical). ISNULL defaults to 0. (Tier 2 - etoro_Hedge_Netting / etoro_History_Netting_History)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN NOP COMMENT 'Net open position in USD equivalent. SUM(Units * ConversionFirst * (2*IsBuy-1) * CASE IsBuy=1 THEN FirstBid ELSE FirstAsk END). Uses direction-appropriate price from PriceLog. Identical formula to ValueStart. ISNULL defaults to 0. (Tier 2 - etoro_Hedge_Netting / PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueStart COMMENT 'USD value of eToro''s hedge position at start of this minute. Identical formula to NOP: SUM(Units * ConversionFirst * (2*IsBuy-1) * price). Always equals NOP for the same row. ISNULL defaults to 0. (Tier 2 - etoro_Hedge_Netting / PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueEnd COMMENT 'USD value of eToro''s hedge position at end of this minute. Equals the next minute''s ValueStart via self-join (te1.fromMinute = te.toMinute, same LiquidityAccountID and InstrumentID). Defaults to 0 for the last active minute of the day. (Tier 2 - etoro_Hedge_Netting / PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueRealized COMMENT 'Net realized value from hedge executions in the minute. SUM(VolumeSell * ConversionFirst) - SUM(VolumeBuy * ConversionFirst). Positive = net selling (reducing position); negative = net buying (adding position). ISNULL defaults to 0. (Tier 2 - etoro_Hedge_ExecutionLog / PriceLog_History_CurrencyPrice)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN UpdateDate COMMENT 'ETL execution timestamp. Set to GETDATE() at SP_IntraHourIndexReport run time. (Tier 2 - SP_IntraHourIndexReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN HedgeServerID COMMENT 'Hedge server identifier used as a grouping dimension. Added 2024-04-30 (SR-249626). NULL for pre-2024 rows. Current active values: 8, 25. Sourced from ExecutionLog and Netting data. (Tier 2 - etoro_Hedge_ExecutionLog / etoro_Hedge_Netting)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Minute_Start SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Minute_End SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN LiquidityAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN VolumeBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN VolumeSell SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Units_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueStart SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueEnd SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueRealized SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:20:27 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 9
-- Statements: 32/32 succeeded
-- ====================
