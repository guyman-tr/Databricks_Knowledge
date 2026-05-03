-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN DateID COMMENT 'Date as YYYYMMDD integer, derived from SP @dt parameter via DateToDateID(). Clustered index column. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed from @dt)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN Date COMMENT 'Calendar date of the reconciliation snapshot, derived from SP @dt parameter. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, @date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN InstrumentID COMMENT 'Instrument identifier. Distribution key. Resolved via ISNULL across client-side (#tp) and omnibus-side (#duco) to ensure coverage when one side has no data. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN InstrumentName COMMENT 'Internal instrument name with exchange suffix, e.g. "PHAR/USD", "FOX.RTH/USD", "MLX.ASX/AUD". From Dim_Instrument.Name. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN InstrumentDisplayName COMMENT 'Human-readable instrument display name, e.g. "Pharming Group NV", "Fox Corporation". From Dim_Instrument.InstrumentDisplayName. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.InstrumentDisplayName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN ISINCode COMMENT 'ISIN security identifier, e.g. "US71716E1055". From Dim_Instrument.ISINCode. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.ISINCode)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN CUSIP COMMENT 'CUSIP security identifier for US instruments, e.g. "71716E105". NULL for non-US instruments. From Dim_Instrument.CUSIP. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.CUSIP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN Exchange COMMENT 'Exchange name, e.g. "Nasdaq", "NYSE", "Sydney", "Borsa Italiana". From Dim_Instrument.Exchange. Drives settlement-date logic (T+1 for NYSE/Nasdaq/TSX, T+2 for others). (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.Exchange)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN HedgeServerID COMMENT 'Hedge server identifier. Part of the row grain. Values include 12 (Apex), 500 (BNYMellon), 501 (BNYMellon EU), 503 (BNYMellon APAC), etc. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL.HedgeServerID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN Provider COMMENT 'Bank/broker provider name derived from three-tier mapping: (1) per-instrument Karen file, (2) single-LA-per-hedge, (3) single-provider-per-hedge. Values: BNYMellon, Apex, IB, JPM, Saxo, IG, VisionTraffix, UBS, Marex, GS, NA. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, #mapping.Provider)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN LiquidityAccountID COMMENT 'Liquidity account identifier. Part of the row grain. Resolved via ISNULL across mapping sources and duco fallback. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, #mapping / #netting)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN LiquidityAccountName COMMENT 'Human-readable LA name, e.g. "Horizon OMS VIRTU1 - Unmanaged US Real 298393". From mapping tables or etoro_Trade_LiquidityAccounts. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, #mapping / etoro_Trade_LiquidityAccounts)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN LiquidityProviderName COMMENT 'Liquidity provider name from eToro hedge-server mapping, e.g. "OMS", "Trafix EXT", "Virtu". (Tier 2 -- SP_Finance_Non_US_Settlement_2025, etoro_Hedge_GetHedgeServerAccountMapping.LiquidityProviderName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToro_Units COMMENT 'Omnibus-side EOD unit balance from netting table. ISNULL(Balance, 0). This is the broker/custodian view of how many units eToro holds. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, External_BI_OUTPUT_Finance_BI_DB_Hedge_NettingBalance.Balance)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToroUSDAmount COMMENT 'Legacy column from Duco integration. Now always NULL after the Oct 2025 switch to direct netting tables. Retained for schema compatibility. (Tier 3 -- SP_Finance_Non_US_Settlement_2025, hardcoded NULL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToroUSDByPriceUnspreaded COMMENT 'Omnibus units valued in USD using the unspreaded EOD price. Computed: eToro_Units * Closing_Rate_Price_Unspreaded. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsTotal COMMENT 'Total client-side units across all validity/settlement segments. SUM(EOD_Units) from #output grouped by instrument x hedge server. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsValidCustomerReal COMMENT 'Client-side units for valid customers with settled (real) positions. SUM where IsValidCustomer=1 AND IsSettled=1. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsValidCustomerCFD COMMENT 'Client-side units for valid customers with CFD (unsettled) positions. SUM where IsValidCustomer=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsCreditReportValidReal COMMENT 'Client-side units for credit-report-valid customers with settled (real) positions. SUM where IsCreditReportValidCB=1 AND IsSettled=1. Key column for reconciliation. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsCreditReportValidCFD COMMENT 'Client-side units for credit-report-valid customers with CFD (unsettled) positions. SUM where IsCreditReportValidCB=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDTotal COMMENT 'Total client-side equity in USD across all segments. SUM(EOD_Equity_USD) = SUM(Amount + PositionPnL). (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL.Amount + PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsValidCustomerReal COMMENT 'Client-side equity USD for valid customers with real positions. SUM where IsValidCustomer=1 AND IsSettled=1. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsValidCustomerCFD COMMENT 'Client-side equity USD for valid customers with CFD positions. SUM where IsValidCustomer=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsCreditReportValidReal COMMENT 'Client-side equity USD for credit-report-valid customers with real positions. SUM where IsCreditReportValidCB=1 AND IsSettled=1. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsCreditReportValidCFD COMMENT 'Client-side equity USD for credit-report-valid customers with CFD positions. SUM where IsCreditReportValidCB=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_OrigCurr_BidSpreaded COMMENT 'End-of-day bid price with spread in original instrument currency. MAX(BidSpreaded) from Fact_CurrencyPriceWithSplit for the date. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Fact_CurrencyPriceWithSplit.BidSpreaded)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_OrigCurr_BidUnspreaded COMMENT 'End-of-day bid price without spread in original instrument currency. MAX(Bid) from Fact_CurrencyPriceWithSplit for the date. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Fact_CurrencyPriceWithSplit.Bid)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN USD_ConversionRate COMMENT 'USD conversion rate for the instrument''s sell currency. Most recent rate from Dim_GetSpreadedPriceUSDConversionRate. ISNULL(..., 1) defaults to 1 for USD-denominated instruments. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_GetSpreadedPriceUSDConversionRate.USD_ConversionRate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_PriceUSD_Spreaded COMMENT 'EOD bid price with spread converted to USD. Computed: BidSpreaded * USD_ConversionRate. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_PriceUSD_Unspreaded COMMENT 'EOD bid price without spread converted to USD. Computed: Bid * USD_ConversionRate. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN IsRelevantForRecon COMMENT 'Reconciliation relevance flag. 0 when provider-hedge combination has zero credit-valid real units (noise suppression). 1 otherwise. CASE logic checks Provider IN (Saxo, Apex, BNYMellon, IB) against specific HedgeServerIDs. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN SellCurrency COMMENT 'Currency code of the instrument, e.g. "USD", "EUR", "GBP", "AUD". From Dim_Instrument.SellCurrency. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.SellCurrency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp. GETDATE(). NOT NULL constraint in DDL. (Tier 3 -- SP_Finance_Non_US_Settlement_2025, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToro_Units_Plus1h COMMENT 'Omnibus-side unit balance one hour after EOD. Added Oct 2025 to handle DailyLight / midnight-bug price anomalies. From NettingBalance.BalancePlus1h. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, External_BI_OUTPUT_Finance_BI_DB_Hedge_NettingBalance.BalancePlus1h)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToroUSDPlus1hByPriceUnspreaded COMMENT '+1h omnibus units valued in USD using unspreaded EOD price. Computed: eToro_Units_Plus1h * Closing_Rate_Price_Unspreaded. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TotalStockMarginLoanIsCreditReportValid COMMENT 'Total stock margin loan value for credit-report-valid customers. SUM where IsCreditReportValidCB=1. Added Feb 2026 by Markos Chris. Computed from InitForexRate * AmountInUnitsDecimal * CurrentConversionRate - Amount for leveraged settled positions. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Dim_Position)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN CUSIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN Provider SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN LiquidityAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN LiquidityProviderName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToroUSDAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToroUSDByPriceUnspreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsTotal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsValidCustomerReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsValidCustomerCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsCreditReportValidReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_UnitsIsCreditReportValidCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDTotal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsValidCustomerReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsValidCustomerCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsCreditReportValidReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TP_EquityUSDIsCreditReportValidCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_OrigCurr_BidSpreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_OrigCurr_BidUnspreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN USD_ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_PriceUSD_Spreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN EOD_PriceUSD_Unspreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN IsRelevantForRecon SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN SellCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToro_Units_Plus1h SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN eToroUSDPlus1hByPriceUnspreaded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_etoro_vs_positions ALTER COLUMN TotalStockMarginLoanIsCreditReportValid SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:51:28 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 76/76 succeeded
-- ====================
