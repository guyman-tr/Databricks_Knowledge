-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_SAXORecon_EODHoldings
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings SET TBLPROPERTIES (
    'comment' = 'End-of-day (EOD) holdings reconciliation between SAXO Bank and eToro for **Real Stocks and Employee accounts**. Each row represents one instrument × HedgeServer × AccountNumber on a given date, showing SAXO''s reported position alongside eToro''s internal hedge netting position and the aggregate client-side exposure. The three-way comparison (`SAXO_Units` vs `eToro_Units` vs `Clients_Units`) and derived difference columns (`SAXO-eToro_Units`, `SAXO-Clients_Units`, `Reality-Supposed`, `Reality-Client`) are the primary tool for the Dealing desk to detect and investigate position discrepancies with the SAXO liquidity provider. SAXO is eToro''s LP for real stock execution - account numbers like `204400INETALM`, `204400INET4` map to specific SAXO sub-accounts. The SP uses a Fivetran-maintained mapping table (`Dealing_staging.External_Fivetran_dealing_active_hs_mappings`) to determine which HedgeServer IDs and LiquidityAccountIDs correspond to SAXO `activity IN (''Stocks - Real'', ''Employees'')`. The eToro-side holdings '
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings SET TAGS (
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
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Date COMMENT 'Reconciliation date. Adjusted to latest available SAXO LP file date if requested date has no data. Clustered index.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN InstrumentID COMMENT 'eToro instrument ID. NULL for SAXO-only rows (instruments eToro has no mapping for). (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name. ISNULL(eToro, SAXO) - eToro name preferred, falls back to SAXO LP description. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN ISINCode COMMENT 'ISIN code. Used as the primary JOIN key between eToro and SAXO sides. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Buy/Sell COMMENT 'Position direction: ''Buy'' or ''Sell''. Derived from eToro IsBuy flag or SAXO BuySell field. Special-character column name requires bracket quoting. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN CurrencyPrimary COMMENT 'Instrument''s primary trading currency. GBX converted to GBP in eToro side. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_Units COMMENT 'Units reported by SAXO LP at EOD. Negative for Sell positions. Aggregated across SAXO sub-accounts. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_Units COMMENT 'eToro''s internal hedge netting position in units. Computed as `SUM((2*IsBuy-1)*Units)` from Netting tables at EOD cutoff. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Clients_Units COMMENT 'Aggregate client-side net units from `Dim_Position`. `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal))` for open positions at cutoff. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO-eToro_Units COMMENT 'Discrepancy: SAXO_Units - eToro_Units. Non-zero indicates hedge imbalance between eToro''s books and SAXO''s records. Special-character column. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO-Clients_Units COMMENT 'Discrepancy: SAXO_Units - Clients_Units. Measures how much SAXO holds vs what clients own. Special-character column. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_LocalAmount COMMENT 'SAXO position value in the instrument''s local currency. `Amount × EODRate × FigureSize` from SAXO LP file. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_LocalAmount COMMENT 'eToro position value in local currency. `SUM((2*IsBuy-1)*Units*Bid_or_Ask)`. GBX adjusted by /100. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_AmountUSD COMMENT 'SAXO position value converted to USD. `SAXO_LocalAmount × InstrumentToAccountRate` from SAXO LP file. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_AmounUSD COMMENT '**Typo column name** (missing ''t''). eToro position USD value. `SUM((2*IsBuy-1)*Units*rate*ConvertRate)`. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Clients_AmountUSD COMMENT 'Client-side aggregate position USD value. `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal)*bid_or_ask*ConvertRate)`. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Reality-Supposed COMMENT 'SAXO_AmountUSD - eToro_AmountUSD. Primary reconciliation metric: eToro''s hedging vs what SAXO actually holds. Special-character column. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Reality-Client COMMENT 'SAXO_AmountUSD - Clients_AmountUSD. Secondary metric: SAXO holdings vs aggregate client exposure. Special-character column. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_Rate COMMENT 'eToro''s mid-price at EOD: `(Bid+Ask)/2` from `Fact_CurrencyPriceWithSplit`. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_Rate COMMENT 'SAXO''s EOD rate from LP file. `CASE WHEN InstrumentCurrency=''GBP'' THEN EODRate/100 ELSE EODRate END` (GBX adjustment). (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro-SAXO_Rate COMMENT 'eToro_Rate - SAXO_Rate. Rate discrepancy used to explain value differences. Special-character column. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN FX_Rate COMMENT 'USD conversion rate used. ISNULL(eToro FXratetoUSD, SAXO InstrumentToAccountRate). (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline.';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN HedgeServerID COMMENT 'HedgeServer identifier. Predominant values: 35 (most rows, Stocks-Real), 128 (Employee accounts). Cross-references `Dealing_staging.External_Fivetran_dealing_active_hs_mappings`. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN UnrealisedValueAccount COMMENT 'Unrealised P&L value from SAXO LP file (`UnrealisedValueAccount` / `UnrealisedPLAccount`). Used for internal SAXO position health monitoring. (Tier 2 - SAXO LP file)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN UpperBoundary COMMENT 'Risk limit in USD (HedgeRiskLimitUSD). Above this, the instrument triggers risk alerts. From `External_Etoro_Hedge_InstrumentBoundaries`. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN LowerBoundary COMMENT 'Lower threshold in USD (-OpenThresholdUSD). Equal to -1000 for illiquid instruments. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN illiquid/liquid COMMENT '''illiquid'' when LowerBoundary = -1000 (OpenThreshold = 1000); ''liquid'' otherwise. Special-character column. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN AccountNumber COMMENT 'SAXO LP account number (e.g., ''204400INETALM'', ''204400INET4''). From Fivetran mapping `lp_accounts` field. Identifies which SAXO sub-account holds the position. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Exchange COMMENT 'Stock exchange name (e.g., ''NASDAQ'', ''NYSE''). ISNULL(eToro Dim_Instrument.Exchange, SAXO ExchangeDescription). (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN MaxTradeDate COMMENT 'Maximum trade date in YYYYMMDD integer format. Latest SAXO LP TradeDate for this instrument/account. Indicates when last trade occurred. (Tier 2 - SAXO LP file)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN LastExecutionTime COMMENT 'Last execution timestamp from CopyFromLake.etoro_Hedge_ExecutionLog for this instrument × HS. (Tier 2 - SP_SAXO_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Symbol COMMENT 'Instrument ticker symbol (e.g., ''AAPL''). Added Feb 2025 (SR-301154). ISNULL(eToro, SAXO). (Tier 2 - SP_SAXO_Recon)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Buy/Sell SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN CurrencyPrimary SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Clients_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO-eToro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO-Clients_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_LocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_LocalAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_AmounUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Clients_AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Reality-Supposed SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Reality-Client SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN SAXO_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN eToro-SAXO_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN FX_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN UnrealisedValueAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN UpperBoundary SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN LowerBoundary SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN illiquid/liquid SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN AccountNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN MaxTradeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN LastExecutionTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
