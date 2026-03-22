-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_dbo.Dealing_IndiciesIntraHour_Etoro
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro SET TBLPROPERTIES (
    'comment' = 'Minute-by-minute LP/eToro-side hedging activity for index instruments (SPX500=27, DJ30=28, NSDQ100=32). Shows the LP''s net open position, hedge volumes, and mark-to-market value at each minute, broken down by liquidity account and hedge server. | Property | Value | |----------|-------| | **Schema** | Dealing_dbo | | **Object Type** | Table | | **Distribution** | ROUND_ROBIN | | **Index** | Clustered (Date ASC) | | **Row Count** | ~8.4M | | **Date Range** | 2022-05-22 → present | | **Grain** | One row per Date × Minute × InstrumentID × LiquidityAccountID × HedgeServerID | | **Refresh** | Daily, via SP_IntraHourIndexReport |'
);

ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro SET TAGS (
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
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Date COMMENT 'Trading date';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN InstrumentID COMMENT 'Index instrument (mapped via PortfolioConversionConfigurations to hedge instruments)';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Minute_Start COMMENT 'Start of the 1-minute interval';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Minute_End COMMENT 'End of the 1-minute interval';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN LiquidityAccountName COMMENT 'LP account display name';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN LiquidityAccountID COMMENT 'LP account identifier';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN VolumeBuy COMMENT 'LP buy volume in USD for this minute. Formula: `SUM(CASE WHEN IsBuy=1 THEN Units*ExecutionRate) * ConversionFirst`';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN VolumeSell COMMENT 'LP sell volume in USD for this minute';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN Units_NOP COMMENT 'LP net open position in units. Formula: `SUM(Units * (2*IsBuy-1))` from netting tables';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN NOP COMMENT 'LP net open position in USD. Formula: `SUM(Units * ConversionFirst * (2*IsBuy-1) * (IsBuy?FirstBid:FirstAsk))`';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueStart COMMENT 'Mark-to-market value at minute start. Same formula as NOP';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueEnd COMMENT 'Mark-to-market value at minute end. Uses next minute''s ValueStart via self-join';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN ValueRealized COMMENT 'Realized value from LP executions. Formula: `SUM(VolumeSell*ConversionFirst - VolumeBuy*ConversionFirst)`';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN UpdateDate COMMENT 'Row write timestamp';
ALTER TABLE main.general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro ALTER COLUMN HedgeServerID COMMENT 'Hedge server for this LP position. Added SR-249626';

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
