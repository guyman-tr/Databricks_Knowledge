-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Duco_ActivityRecon
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon SET TBLPROPERTIES (
    'comment' = '**Daily trade activity reconciliation** between eToro''s LP (liquidity provider) hedge executions and client trade activity. Each row compares what was executed on the hedge server side (from the execution log) against what client positions were opened or closed that day, aggregated by liquidity account and instrument. Together with `Dealing_Duco_EODRecon` (holdings), this table forms the two-part Duco reconciliation suite that all LP-specific recon pipelines consume. **Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `Buy/Sell` direction.'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Date COMMENT 'Report date (trade activity reconciliation date). (Tier 2 -- SP_DataForDuco, @Date)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN LiquidityAccountID COMMENT 'LP account identifier. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountID)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN LiquidityAccountName COMMENT 'LP account display name. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN HedgeServerID COMMENT 'Hedge server associated with the LP execution. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.HedgeServerID)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.InstrumentID)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN ISINCode COMMENT 'ISIN code from instrument master. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.ISINCode)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.InstrumentDisplayName)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Buy/Sell COMMENT 'Direction: ''Buy'' or ''Sell'', derived from net units sign. (Tier 2 -- SP_DataForDuco, computed from sign of eToro_Units / ClientUnits)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToro_Units COMMENT 'Total LP units executed on the hedge server for the date. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Units)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN ClientUnits COMMENT 'Total client position units opened/closed on the date. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToroLocalAmount COMMENT 'LP execution value in local instrument currency. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Amount)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToroUSDAmount COMMENT 'LP execution value converted to USD. (Tier 2 -- SP_DataForDuco, computed: eToroLocalAmount × FXratetoUSD)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN ClientAmount COMMENT 'Client activity value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToro_AvgRate COMMENT 'Weighted average execution rate on the LP/hedge side. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Rate weighted avg)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Client_AvgRate COMMENT 'Weighted average execution rate on the client side. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL rate weighted avg)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN UpdateDate COMMENT 'Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DataForDuco, GETDATE())';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Symbol COMMENT 'Instrument ticker symbol. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Symbol)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN SellCurrency COMMENT 'Trade currency of the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.SellCurrency)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Exchange COMMENT 'Exchange name for the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Exchange)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_Units_Buy COMMENT 'Client trade units on the buy side. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=1)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_Units_Sell COMMENT 'Client trade units on the sell side. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=0)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_NOP_Buy COMMENT 'Client buy-side activity value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP buy)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_NOP_Sell COMMENT 'Client sell-side activity value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP sell)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN FXratetoUSD COMMENT 'FX rate from instrument currency to USD. (Tier 2 -- SP_DataForDuco, DWH_dbo.Fact_CurrencyPriceWithSplit)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN CUSIP COMMENT 'CUSIP identifier from LP execution log or external source. (Tier 2 -- SP_DataForDuco, external source / LP execution log)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN LiquidityAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Buy/Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN ClientUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToroLocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToroUSDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN ClientAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN eToro_AvgRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Client_AvgRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_Units_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_Units_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_NOP_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Clients_NOP_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN FXratetoUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN CUSIP SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 14:01:14 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 50/52 succeeded
-- Error: [PARSE_SYNTAX_ERROR] Syntax error at or near '/'. SQLSTATE: 42601 (line 1, pos 100) == SQL == ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon ALTER COLUMN Buy/Sell SET TAGS ('pii' = 'none'); ----------------------------------------------------------------------------------------------------^^^
-- ====================
