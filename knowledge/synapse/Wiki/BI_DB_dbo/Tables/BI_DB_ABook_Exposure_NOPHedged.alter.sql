-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged > ABook hedging NOP (Net Open Position) exposure snapshot - the active operational ABook exposure table providing per-instrument, per-hedge-server, per-liquidity-account net exposure metrics. Unlike its dormant sibling tables (`BI_DB_ABook_Exposure`, `BI_DB_ABook_Exposure_History`), this table is fed by **Generic Pipeline #471** (hourly Override strategy) and exported to Unity Catalog. Net-only table - no `_unhedged` column pairs. Adds `LiquidityAccountID`/`LiquidityAccountName` and proxy-hedge instrument columns (`InstrumentIDToHedge`, `InstrumentID_Final`) not present in siblings. Currently **stale (last updated 2024-02-15)** despite active pipeline configuration. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table - ABook hedging NOP exposure snapshot (net-only, per liquidity account) | | **Production '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Date COMMENT 'Trading date of this exposure snapshot. Clustered index key - date equality queries are efficient. All rows currently dated 2024-02-15 (stale Override snapshot). (Tier 3 - column name + Generic Pipeline Override pattern + live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. References DWH_dbo.Dim_Instrument.InstrumentID. (Tier 3 - Dim_Instrument pattern + SP_DailyNOP_ByInstrument context)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentIDToHedge COMMENT 'Instrument used as hedge proxy when different from InstrumentID. NULL for 85% of rows - hedge placed on the same instrument. Populated when a substitute/proxy instrument is used for hedging (e.g., proxy ETF for less-liquid stock). (Tier 3 - column name + ABook proxy hedging domain + live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentID_Final COMMENT 'Resolved instrument ID used for the actual hedge execution. = InstrumentIDToHedge when non-NULL, otherwise InstrumentID. Always populated - safe key for hedging execution joins. (Tier 3 - column name + ABook proxy hedge resolution pattern + live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentName COMMENT 'Instrument display name, truncated to 45 characters. Sourced from Dim_Instrument.InstrumentDisplayName. (Tier 3 - column name + Dim_Instrument pattern + live data: KRNY/USD, AVAX/USD, etc.)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentType COMMENT 'Instrument asset class/type (e.g., "Crypto", "Stocks", "Commodities"). Matches Dim_Instrument.InstrumentType taxonomy. (Tier 3 - column name + SP_DailyNOP_ByInstrument context)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN HedgeServerID COMMENT 'Identifier for the eToro ABook hedging engine or counterparty server. References External_etoro_Trade_HedgeServer.HedgeServerID. 38 distinct servers observed in live data. (Tier 3 - External_etoro_Trade_HedgeServer DDL + ABook domain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN LiquidityAccountID COMMENT 'Integer identifier of the liquidity provider account used for hedging. References External_etoro_Hedge_HedgeServerToLiquidityAccount.LiquidityAccountID. NULL for 25% of rows (positions without assigned LP). 44 distinct accounts observed. (Tier 3 - External_etoro_Hedge_HedgeServerToLiquidityAccount DDL + live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN LiquidityAccountName COMMENT 'Name of the liquidity provider account (e.g., "APEX Traffix Account Real 3EU05025 Real", "EMSX JPM Execution (CBH)"). De-normalized from LP account configuration. NULL when LiquidityAccountID is NULL. (Tier 3 - live data + LP account domain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN NOP COMMENT 'Net Open Position after applying external hedges - the residual ABook risk eToro carries with the liquidity provider. Relationship: NOP ≈ NOP_unhedged - NOPHedged. (Tier 3 - column name + ABook hedging model)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Nop_Units COMMENT 'Net NOP in instrument units after hedging. (Tier 3 - column name + ABook domain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN NOPHedged COMMENT 'Dollar value of NOP that has been successfully hedged externally with the liquidity provider. Can exceed NOP (over-hedging possible). When LiquidityAccountID IS NULL, typically 0. (Tier 3 - column name + ABook hedging model + live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN OpenPositions COMMENT 'Net total open position after hedging in notional dollar value. (Tier 3 - column name + ABook domain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Short COMMENT 'Net short position exposure in notional dollars after hedge orders. (Tier 3 - column name + ABook domain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Long COMMENT 'Net long position exposure in notional dollars after hedge orders. (Tier 3 - column name + ABook domain)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last loaded. (Tier 5 - propagation)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentIDToHedge SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentID_Final SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN LiquidityAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Nop_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN NOPHedged SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN OpenPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Short SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN Long SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:21:01 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 34/34 succeeded
-- ====================
