-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Liabilities
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities
-- Resolved via: Generic Pipeline mapping (_generic_pipeline_mapping.json)
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities SET TBLPROPERTIES (
    'comment' = 'Daily customer liabilities view combining Fact_SnapshotEquity (equity balances, cash, positions) with Fact_CustomerUnrealized_PnL (unrealized PnL, NOP, notional) via V_M2M_Date_DateRange to compute ActualNWA (credit-capped net worth: clamped to [0, BonusCredit] of NetEquity), Liabilities (InProcessCashouts + excess of NetEquity above BonusCredit - what eToro owes the customer in real money), WA_Liabilities (credit-capped liabilities), and Liabilities_InUsedMargin (liabilities beyond credit). NetEquity = TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL. Balance = Liabilities + ActualNWA = RealizedEquity + PositionPnL. Provides 75 output columns with asset-class breakdowns (stocks, crypto, futures, stock margin, TRS) for liabilities, PnL, NOP, and notional values. Excludes today''s data (DateKey < today). Central view for 20+ downstream SPs covering regulatory balance reporting, AML monitoring, dormant fee calculations, and client balance dashboards.'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities SET TAGS (
    'domain' = 'finance',
    'object_type' = 'view',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase',
    'semantic_grade' = '9.2'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CID COMMENT 'Customer ID. Join key to Dim_Customer (CID = RealCID). Combined with DateID forms the logical PK. (Tier 1 - Fact_SnapshotEquity.CID)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN DateID COMMENT 'Date key in YYYYMMDD integer format. Aliased from V_M2M_Date_DateRange.DateKey. Always < today (excludes current day). (Tier 1 - V_M2M_Date_DateRange.DateKey)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullDate COMMENT 'Calendar date (datetime). From the date dimension via V_M2M_Date_DateRange. (Tier 1 - V_M2M_Date_DateRange.FullDate)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN RealizedEquity COMMENT 'Fact_SnapshotEquity.RealizedEquity';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalPositionsAmount COMMENT 'Fact_SnapshotEquity.TotalPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCash COMMENT 'Customer total cash balance. Running balance: previous day TotalCash + sum of TotalCashChange from History.ActiveCredit. (Tier 1 - Fact_SnapshotEquity.TotalCash)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN InProcessCashouts COMMENT 'Fact_SnapshotEquity.InProcessCashouts';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorCash COMMENT 'Fact_SnapshotEquity.TotalMirrorCash';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockOrders COMMENT 'Fact_SnapshotEquity.TotalStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorStockOrders COMMENT 'Fact_SnapshotEquity.TotalMirrorStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Credit COMMENT 'Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. Used as cap in WA_Liabilities. (Tier 1 - Fact_SnapshotEquity.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN AUM COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. (Tier 1 - Fact_SnapshotEquity.AUM)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN BonusCredit COMMENT 'Fact_SnapshotEquity.BonusCredit';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockPositionAmount COMMENT 'Fact_SnapshotEquity.TotalStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorStockPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.PositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.CopyPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN StandardDeviation COMMENT 'Fact_CustomerUnrealized_PnL.StandardDeviation';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionOnOpen COMMENT 'Fact_CustomerUnrealized_PnL.CommissionOnOpen';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ActualNWA COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Liabilities COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN WA_Liabilities COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Liabilities_InUsedMargin COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN StocksPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.StocksPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockManualPosition COMMENT 'Manual stock position amount (excluding copy). TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualStockPositionPnL COMMENT 'Unrealized PnL from manually-opened stock positions. StocksPositionPnL - MirrorStocksPositionPnL. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN MirrorStocksPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CryptoPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.CryptoPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualCryptoPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyCryptoPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoPositionAmount COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoManualPosition COMMENT 'Manual crypto position amount. TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyFundAUM COMMENT 'Fact_SnapshotEquity.CopyFundAUM';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyFundPnL COMMENT 'Fact_CustomerUnrealized_PnL.CopyFundPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP COMMENT 'Fact_CustomerUnrealized_PnL.NOP';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional COMMENT 'Fact_CustomerUnrealized_PnL.Notional';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto COMMENT 'Fact_CustomerUnrealized_PnL.NOP_Crypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto COMMENT 'Fact_CustomerUnrealized_PnL.Notional_Crypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_CFD COMMENT 'Fact_CustomerUnrealized_PnL.NOP_CFD';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_CFD COMMENT 'Fact_CustomerUnrealized_PnL.Notional_CFD';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto_CFD COMMENT 'Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto_CFD COMMENT 'Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLStocksReal COMMENT 'Fact_CustomerUnrealized_PnL.PositionPnLStocksReal';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLCryptoReal COMMENT 'Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealStocks COMMENT 'Fact_SnapshotEquity.TotalRealStocks';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealCrypto COMMENT 'Fact_SnapshotEquity.TotalRealCrypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesStockReal COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesCryptoReal COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionByUnitsCrypto_TRS COMMENT 'Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyCryptoPositionPnL_TRS COMMENT 'Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CryptoPositionPnL_TRS COMMENT 'Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullCommissionByUnitsCrypto_TRS COMMENT 'Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualCryptoPositionPnL_TRS COMMENT 'Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto_TRS COMMENT 'Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto_TRS COMMENT 'Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Total_TRSCrypto COMMENT 'Fact_SnapshotEquity.Total_TRSCrypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoPositionAmount_TRS COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoManualPosition_TRS COMMENT 'Manual crypto TRS position amount. TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesCrypto_TRS COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN MirrorRealFuturesPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.MirrorRealFuturesPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualRealFuturesPositionPnL COMMENT 'Fact_CustomerUnrealized_PnL.ManualRealFuturesPositionPnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_FuturesReal COMMENT 'Fact_CustomerUnrealized_PnL.NOP_FuturesReal';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_FuturesReal COMMENT 'Fact_CustomerUnrealized_PnL.Notional_FuturesReal';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLFuturesReal COMMENT 'Fact_CustomerUnrealized_PnL.PositionPnLFuturesReal';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullCommissionByUnitsFuturesReal COMMENT 'Fact_CustomerUnrealized_PnL.FullCommissionByUnitsFuturesReal';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionByUnitsFuturesReal COMMENT 'Fact_CustomerUnrealized_PnL.CommissionByUnitsFuturesReal';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorRealFuturesPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealFutures COMMENT 'Fact_SnapshotEquity.TotalRealFutures';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalFuturesProviderMargin COMMENT 'Fact_SnapshotEquity.TotalFuturesProviderMargin';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesFuturesReal COMMENT 'Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_StocksMargin COMMENT 'Fact_CustomerUnrealized_PnL.NOP_StocksMargin';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLStocksMargin COMMENT 'Fact_CustomerUnrealized_PnL.PositionPnLStocksMargin';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStocksMargin COMMENT 'Fact_SnapshotEquity.TotalStocksMargin';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockMarginLoanValue COMMENT 'Fact_SnapshotEquity.TotalStockMarginLoanValue';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CID SET TAGS ('pii' = 'indirect_identifier');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCash SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN InProcessCashouts SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorCash SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorStockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN AUM SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN BonusCredit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorStockPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN StandardDeviation SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ActualNWA SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Liabilities SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN WA_Liabilities SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Liabilities_InUsedMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN StocksPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockManualPosition SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualStockPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN MirrorStocksPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CryptoPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualCryptoPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyCryptoPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoManualPosition SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyFundAUM SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyFundPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLStocksReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLCryptoReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealStocks SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesStockReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesCryptoReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionByUnitsCrypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyCryptoPositionPnL_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CryptoPositionPnL_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullCommissionByUnitsCrypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualCryptoPositionPnL_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Total_TRSCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoPositionAmount_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoManualPosition_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesCrypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN MirrorRealFuturesPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualRealFuturesPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_FuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_FuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullCommissionByUnitsFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionByUnitsFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorRealFuturesPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealFutures SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalFuturesProviderMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_StocksMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLStocksMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStocksMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockMarginLoanValue SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:37:46 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 152/152 succeeded
-- ====================
