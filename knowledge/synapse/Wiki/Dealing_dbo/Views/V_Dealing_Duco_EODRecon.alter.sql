-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.V_Dealing_Duco_EODRecon
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon SET TBLPROPERTIES (
    'comment' = 'Dealing_dbo.V_Dealing_Duco_EODRecon **Schema**: Dealing_dbo | **UC Target**: `dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon` **Row count**: ~18.6M (2023-01-02 -> 2026-05-06) | **Refresh**: daily (Merge generic pipeline, weekdays only) **Type**: VIEW | **Base table**: `Dealing_dbo.Dealing_Duco_EODRecon` ---'
);

-- ---- Table Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon SET TAGS (
    'source_schema' = 'Dealing_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Date COMMENT 'Report date (EOD reconciliation date). Weekdays only - no Sat/Sun rows.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountID COMMENT 'LP account identifier from `Dealing_staging.etoro_Trade_LiquidityAccounts`.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountName COMMENT 'LP account display name.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN HedgeServerID COMMENT 'Hedge server identifier associated with the LP position.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. Joins to `DWH_dbo.Dim_Instrument`.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN ISINCode COMMENT 'ISIN code from LP netting or instrument master.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN `Buy/Sell` COMMENT 'Position direction - ''Buy'' or ''Sell'' - derived from net units sign. Requires bracket quoting in T-SQL. Use `BuyOrSell` alias instead.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToro_Units COMMENT 'Total LP hedge units held at EOD on the eToro side.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN ClientUnits COMMENT 'Total client NOP units from `BI_DB_PositionPnL` for the instrument.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToroLocalAmount COMMENT 'LP hedge position value in the instrument''s local currency.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToroUSDAmount COMMENT 'LP hedge position value in USD (= `eToroLocalAmount * FXratetoUSD`).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN ClientAmount COMMENT 'Client NOP position value in USD.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToroRate COMMENT 'Average rate of the eToro hedge holding (LP-side weighted average price).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN HedgingPercent COMMENT '`eToro_Units / ClientUnits` - hedge coverage ratio. NULL when ClientUnits = 0.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN UpdateDate COMMENT 'Batch execution timestamp (`GETDATE()`).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Symbol COMMENT 'Instrument ticker symbol (from `Dim_Instrument.Symbol`).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN SellCurrency COMMENT 'Trade currency of the instrument.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Exchange COMMENT 'Exchange name for the instrument.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN MKTcap COMMENT 'Market capitalization of the instrument from external reference, used by downstream to size reconciliation thresholds.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Buy COMMENT 'Client units on the buy side (long positions).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Sell COMMENT 'Client units on the sell side (short positions).';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Buy COMMENT 'Client NOP USD value for buy/long positions.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Sell COMMENT 'Client NOP USD value for sell/short positions.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN FXratetoUSD COMMENT 'FX rate from instrument trade currency to USD for amount conversion.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN CUSIP COMMENT 'CUSIP identifier from the LP netting / external reference data source.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN BuyOrSell COMMENT '**Computed alias** for `[Buy/Sell]` - bracket-free name for BI tool compatibility. Same values as `[Buy/Sell]`.';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN `Buy/Sell` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN ClientUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToroLocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToroUSDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN ClientAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN eToroRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN HedgingPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN MKTcap SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN FXratetoUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN CUSIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon ALTER COLUMN BuyOrSell SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 11:27:22 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 11
-- Statements: 56/56 succeeded
-- ====================
