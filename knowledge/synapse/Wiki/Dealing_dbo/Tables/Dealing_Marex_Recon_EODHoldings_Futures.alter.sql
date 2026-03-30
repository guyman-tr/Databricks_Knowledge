-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures SET TBLPROPERTIES (
    'comment' = 'Futures-specific EOD holdings reconciliation for Marex. Added in May 2025 to handle eToro''s futures product offering. Each row represents one futures position at CID (client) × Contract × IsBuy × OrderID granularity, comparing Marex''s EOD custodian lots against eToro''s aggregated client position. **Key structural difference from base Marex recon**: This table reconciles at **CID level** (individual client) rather than at the eToro hedge book level. There is no `eToro_Units` column - the comparison is Marex position vs Client position (`Clients_Lots` / `ClientUnits`). This reflects the futures model where client positions are passed through to Marex 1:1. `WA_Marex_Price` is the weighted average price from Marex''s position file. `MultiplicationFactor` is the futures contract multiplier (number of underlying units per lot). `LastTradingDay` stores the contract expiry date as an integer DateID. `ForexRate_AfterADJ` and `ADJ_Value` are ADJ (adjustment) FX columns added in July 2025. Written by `SP_Marex_Recon` ...'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'CLUSTERED INDEX (Date ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Date COMMENT 'EOD snapshot date. SP parameter; DELETE-INSERT by Date. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN PositionID COMMENT 'Marex position identifier. Unique identifier for the futures position in Marex''s system. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN CID COMMENT 'eToro client identifier. Granularity key - each client''s position is recorded separately. FK -> DWH_dbo.Dim_Customer. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN HedgeServerID COMMENT 'eToro hedge server. From eToro netting/history tables. NULL for Marex-only rows. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN CONTRACT COMMENT 'Marex futures contract code. Uppercase column name; maps to InstrumentID via SP logic. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ContractName COMMENT 'Human-readable futures contract name from Marex. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. Resolved from CONTRACT via mapping logic. FK -> DWH_dbo.Dim_Instrument. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Exchange COMMENT 'Futures exchange venue. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Symbol COMMENT 'Ticker symbol. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN SellCurrency COMMENT 'Settlement currency for the contract (P&L currency). (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN IsBuy COMMENT 'Position direction: 1=Long, 0=Short. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ConversionRate COMMENT 'eToro''s FX conversion rate for this instrument''s currency pair. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Clients_Lots COMMENT 'Client''s position in lots (integer lot count). From eToro client netting data. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_Lots COMMENT 'Marex''s EOD position in lots. From Marex futures position file. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN WA_Marex_Price COMMENT 'Weighted average Marex price for the position. From Marex position file. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ForexRate COMMENT 'Raw FX rate from Marex (local -> USD) before ADJ adjustment. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Trader COMMENT 'Marex trader identifier. Informational; identifies who manages this position at Marex. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ACCOUNT COMMENT 'Marex LP account code. Uppercase column name. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Currency COMMENT 'Underlying instrument currency (not settlement currency - see SellCurrency). (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN MultiplicationFactor COMMENT 'Futures contract multiplier: number of underlying units per lot. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN LastTradingDay COMMENT 'Contract expiry date as integer DateID. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ClientUnits COMMENT 'Client''s position in units (= Clients_Lots × MultiplicationFactor). From eToro client netting. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_Units COMMENT 'Marex''s position in units (= Marex_Lots × MultiplicationFactor). From Marex position file. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ClientsLocalAmount COMMENT 'Client NOP in local currency. From eToro client netting. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_LocalAmount COMMENT 'Marex position value in local currency. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ClientsUSDAmount COMMENT 'Client NOP in USD. From eToro client netting. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_USDAmount COMMENT 'Marex position value in USD. Note: named `Marex_USDAmount` here (vs `Marex_AmountUSD` in base tables). (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_Units COMMENT '**Recon diff**: `ISNULL(Marex_Units,0) - ISNULL(ClientUnits,0)`. Unit-level break. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_USDAmount COMMENT '**Recon diff**: `ISNULL(Marex_USDAmount,0) - ISNULL(ClientsUSDAmount,0)`. USD break. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_Lots COMMENT '**Recon diff**: `Marex_Lots - Clients_Lots`. Lot-level break. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_Price COMMENT '**Recon diff**: Marex price vs client price. Price discrepancy between Marex and client entry. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ForexRate_AfterADJ COMMENT 'FX rate after ADJ adjustment (added Jul 2025). NULL for rows before July 2025. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ADJ_Value COMMENT 'ADJ adjustment factor applied to FX rate (added Jul 2025). NULL for rows before July 2025. (Tier 2 - SP_Marex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN OrderID COMMENT 'Marex order identifier. Links to specific order in Marex system. (Tier 2 - SP_Marex_Recon)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN CONTRACT SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ContractName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Clients_Lots SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_Lots SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN WA_Marex_Price SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ForexRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Trader SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ACCOUNT SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN MultiplicationFactor SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN LastTradingDay SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ClientUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ClientsLocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_LocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ClientsUSDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex_USDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_USDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_Lots SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN Marex-Clients_Price SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ForexRate_AfterADJ SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN ADJ_Value SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures ALTER COLUMN OrderID SET TAGS ('pii' = 'none');
