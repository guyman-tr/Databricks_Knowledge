-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Duco_EODRecon
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon SET TBLPROPERTIES (
    'comment' = '**Daily end-of-day reconciliation** between eToro''s LP (liquidity provider) hedge holdings and client NOP (net open position). Each row compares what eToro''s hedge servers hold at EOD for a given liquidity account and instrument versus what the aggregated client position demands, expressed in units and USD amounts. The table is the **primary foundation for all LP broker reconciliation pipelines** — 11+ downstream recon tables (Apex, GS, IB, IG, JPM, SAXO, VISION, BNY VIRTU, CloseOnly) depend on it. **Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `Buy/Sell` direction.'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon SET TAGS (
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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Date COMMENT 'Report date (EOD reconciliation date). (Tier 2 -- SP_DataForDuco, @Date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountID COMMENT 'LP account identifier from etoro_Trade_LiquidityAccounts. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountName COMMENT 'LP account display name. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN HedgeServerID COMMENT 'Hedge server identifier associated with the LP position. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.HedgeServerID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN ISINCode COMMENT 'ISIN code from LP netting or instrument master. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.ISINCode)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.InstrumentDisplayName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Buy/Sell COMMENT 'Direction of the position: ''Buy'' or ''Sell'', derived from net units sign. (Tier 2 -- SP_DataForDuco, computed from eToro_Units / ClientUnits sign)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToro_Units COMMENT 'Total LP hedge units held at EOD on the eToro side. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Units)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN ClientUnits COMMENT 'Total client NOP units from BI_DB_PositionPnL for the instrument. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToroLocalAmount COMMENT 'LP hedge position value in the instrument''s local currency. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToroUSDAmount COMMENT 'LP hedge position value converted to USD via FXratetoUSD. (Tier 2 -- SP_DataForDuco, computed: eToroLocalAmount × FXratetoUSD)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN ClientAmount COMMENT 'Client NOP position value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToroRate COMMENT 'Average rate of the eToro hedge holding (LP-side weighted average price). (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Rate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN HedgingPercent COMMENT 'eToro_Units / ClientUnits — hedge coverage ratio (1.0 = fully hedged). (Tier 2 -- SP_DataForDuco, computed: eToro_Units / NULLIF(ClientUnits, 0))';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN UpdateDate COMMENT 'Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DataForDuco, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Symbol COMMENT 'Instrument ticker symbol. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Symbol)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN SellCurrency COMMENT 'Trade currency of the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.SellCurrency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Exchange COMMENT 'Exchange name for the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Exchange)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN MKTcap COMMENT 'Market capitalization of the instrument from external reference. (Tier 2 -- SP_DataForDuco, external reference table)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Buy COMMENT 'Client units on the buy side (long positions). (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Sell COMMENT 'Client units on the sell side (short positions). (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=0)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Buy COMMENT 'Client NOP USD value for buy (long) positions. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP buy-side)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Sell COMMENT 'Client NOP USD value for sell (short) positions. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP sell-side)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN FXratetoUSD COMMENT 'FX rate from instrument currency to USD for amount conversion. (Tier 2 -- SP_DataForDuco, DWH_dbo.Fact_CurrencyPriceWithSplit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN CUSIP COMMENT 'CUSIP identifier from the LP netting/external data source. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.CUSIP / external source)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN LiquidityAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Buy/Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN ClientUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToroLocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToroUSDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN ClientAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN eToroRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN HedgingPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN MKTcap SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_Units_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Buy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN Clients_NOP_Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN FXratetoUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon ALTER COLUMN CUSIP SET TAGS ('pii' = 'none');
