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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN RealizedEquity COMMENT 'Total account value including cash, positions, and pending cashouts. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise TotalCash + TotalPositionsAmount + InProcessCashouts. (Tier 1 - Fact_SnapshotEquity.RealizedEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalPositionsAmount COMMENT 'Sum of all open position amounts (NewAmount) for this CID on this date across all asset classes. (Tier 1 - Fact_SnapshotEquity.TotalPositionsAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCash COMMENT 'Customer total cash balance. Running balance: previous day TotalCash + sum of TotalCashChange from History.ActiveCredit. (Tier 1 - Fact_SnapshotEquity.TotalCash)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN InProcessCashouts COMMENT 'Sum of pending withdrawal amounts not yet finalized (excludes statuses 3=Processed, 4=Cancelled, 5, 6). (Tier 1 - Fact_SnapshotEquity.InProcessCashouts)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Sum of copy-trading position amounts (MirrorID > 0 AND ParentPositionID != 0). (Tier 1 - Fact_SnapshotEquity.TotalMirrorPositionsAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorCash COMMENT 'Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 1 - Fact_SnapshotEquity.TotalMirrorCash)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockOrders COMMENT 'Legacy column, hardcoded to 0 since 2019. Kept for schema compatibility. Still referenced in NetEquity formula but has no computational effect. (Tier 1 - Fact_SnapshotEquity.TotalStockOrders)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorStockOrders COMMENT 'Legacy column, hardcoded to 0 since 2019. Kept for schema compatibility. (Tier 1 - Fact_SnapshotEquity.TotalMirrorStockOrders)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Credit COMMENT 'Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. Used as cap in WA_Liabilities. (Tier 1 - Fact_SnapshotEquity.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN AUM COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. (Tier 1 - Fact_SnapshotEquity.AUM)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN BonusCredit COMMENT 'Bonus credit balance from History.ActiveCredit. Used as threshold in ActualNWA/Liabilities CASE logic: NetEquity is compared against BonusCredit to determine the split between NWA and liabilities. (Tier 1 - Fact_SnapshotEquity.BonusCredit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockPositionAmount COMMENT 'Sum of position amounts where InstrumentTypeID IN (5,6) AND NOT futures. Stocks (real + CFD). (Tier 1 - Fact_SnapshotEquity.TotalStockPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorStockPositionAmount COMMENT 'Copy-trading subset of TotalStockPositionAmount. MirrorID > 0 AND ParentPositionID != 0. (Tier 1 - Fact_SnapshotEquity.TotalMirrorStockPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnL COMMENT 'Total unrealized PnL in USD across all open positions. Uses V1 formula (PnLInDollars). "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence). (Tier 1 - Fact_CustomerUnrealized_PnL.PositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyPositionPnL COMMENT 'Unrealized PnL from copy-trading positions only (MirrorID > 0). (Tier 1 - Fact_CustomerUnrealized_PnL.CopyPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN StandardDeviation COMMENT 'Portfolio risk: standard deviation computed from instrument covariance matrix. Only for dates >= 2012-12-31. (Tier 1 - Fact_CustomerUnrealized_PnL.StandardDeviation)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionOnOpen COMMENT 'Sum of opening commissions across all open positions for this CID. (Tier 1 - Fact_CustomerUnrealized_PnL.CommissionOnOpen)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ActualNWA COMMENT 'Non-Withdrawable Amount (credit-capped net worth). CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END. NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0). Balance = Liabilities + ActualNWA. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Liabilities COMMENT 'Customer liabilities - what eToro owes in real money. ISNULL(InProcessCashouts,0) + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END. Balance = Liabilities + ActualNWA. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN WA_Liabilities COMMENT 'Credit-capped liabilities. MIN(Liabilities_excl_cashouts, Credit) - the portion of liabilities coverable by credit. "WA" etymology uncertain (possibly Withdrawal Available). (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Liabilities_InUsedMargin COMMENT 'Liabilities exceeding available credit. MAX(Liabilities_excl_cashouts - Credit, 0). When Liabilities_excl_cashouts > Credit, this is the uncovered portion. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN StocksPositionPnL COMMENT 'Unrealized PnL from stock positions (InstrumentTypeID IN (5,6) AND NOT futures). Both real and CFD, manual and copy. (Tier 1 - Fact_CustomerUnrealized_PnL.StocksPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockManualPosition COMMENT 'Manual stock position amount (excluding copy). TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualStockPositionPnL COMMENT 'Unrealized PnL from manually-opened stock positions. StocksPositionPnL - MirrorStocksPositionPnL. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN MirrorStocksPositionPnL COMMENT 'Unrealized PnL from copy-trading stock positions (InstrumentTypeID IN (5,6) AND NOT futures AND MirrorID > 0). (Tier 1 - Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CryptoPositionPnL COMMENT 'Unrealized PnL from all crypto positions (InstrumentTypeID = 10 AND NOT futures). Includes real, CFD, manual, and copy. (Tier 1 - Fact_CustomerUnrealized_PnL.CryptoPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualCryptoPositionPnL COMMENT 'Unrealized PnL from manually-opened crypto positions (MirrorID = 0). (Tier 1 - Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyCryptoPositionPnL COMMENT 'Unrealized PnL from copy-trading crypto positions (MirrorID > 0). (Tier 1 - Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoPositionAmount COMMENT 'Sum of crypto position amounts (InstrumentTypeID = 10 AND NOT futures). Real + CFD. (Tier 1 - Fact_SnapshotEquity.TotalCryptoPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoManualPosition COMMENT 'Manual crypto position amount. TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyFundAUM COMMENT 'Assets Under Management for copy-fund positions. (Tier 1 - Fact_SnapshotEquity.CopyFundAUM)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyFundPnL COMMENT 'Unrealized PnL from copy-fund positions (parent CID had AccountTypeID=9). (Tier 1 - Fact_CustomerUnrealized_PnL.CopyFundPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP COMMENT 'Net Open Position - total signed directional USD exposure across all instruments. Positive = net long, negative = net short. (Tier 1 - Fact_CustomerUnrealized_PnL.NOP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional COMMENT 'Total absolute USD exposure across all instruments. ABS(NOP) per instrument, summed. Always >= 0. (Tier 1 - Fact_CustomerUnrealized_PnL.Notional)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto COMMENT 'Net Open Position for crypto instruments only (InstrumentTypeID = 10 AND NOT futures). (Tier 1 - Fact_CustomerUnrealized_PnL.NOP_Crypto)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto COMMENT 'Absolute USD exposure for crypto instruments only. (Tier 1 - Fact_CustomerUnrealized_PnL.Notional_Crypto)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_CFD COMMENT 'Net Open Position for all CFD positions (IsSettled = 0), all asset classes. (Tier 1 - Fact_CustomerUnrealized_PnL.NOP_CFD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_CFD COMMENT 'Absolute USD exposure for all CFD positions. (Tier 1 - Fact_CustomerUnrealized_PnL.Notional_CFD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto_CFD COMMENT 'Net Open Position for crypto CFD positions (InstrumentTypeID = 10 AND IsSettled = 0). (Tier 1 - Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto_CFD COMMENT 'Absolute USD exposure for crypto CFD positions. (Tier 1 - Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLStocksReal COMMENT 'Unrealized PnL from real (settled) stock positions only (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 1 - Fact_CustomerUnrealized_PnL.PositionPnLStocksReal)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLCryptoReal COMMENT 'Unrealized PnL from real (settled) crypto positions only (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 1 - Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealStocks COMMENT 'Sum of real stock position amounts (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 1 - Fact_SnapshotEquity.TotalRealStocks)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealCrypto COMMENT 'Sum of real crypto position amounts (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 1 - Fact_SnapshotEquity.TotalRealCrypto)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesStockReal COMMENT 'Real stock liabilities. ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0). Combines position PnL with position amounts for settled stocks. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesCryptoReal COMMENT 'Real crypto liabilities. ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0). Combines position PnL with position amounts for settled crypto. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionByUnitsCrypto_TRS COMMENT 'Prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 1 - Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CopyCryptoPositionPnL_TRS COMMENT 'Unrealized PnL from copy-trading crypto TRS positions (InstrumentTypeID = 10 AND MirrorID > 0 AND SettlementTypeID = 2). (Tier 1 - Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CryptoPositionPnL_TRS COMMENT 'Unrealized PnL from all crypto TRS positions (InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 1 - Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullCommissionByUnitsCrypto_TRS COMMENT 'Full prorated commission for crypto TRS positions (before discounts). (Tier 1 - Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualCryptoPositionPnL_TRS COMMENT 'Unrealized PnL from manually-opened crypto TRS positions (MirrorID = 0 AND SettlementTypeID = 2). (Tier 1 - Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_Crypto_TRS COMMENT 'Net Open Position for crypto TRS positions (InstrumentTypeID = 10 AND IsSettled = 0 AND SettlementTypeID = 2). (Tier 1 - Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_Crypto_TRS COMMENT 'Absolute USD exposure for crypto TRS positions. (Tier 1 - Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Total_TRSCrypto COMMENT 'Crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto under TRS settlement. (Tier 1 - Fact_SnapshotEquity.Total_TRSCrypto)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoPositionAmount_TRS COMMENT 'Sum of crypto position amounts where SettlementTypeID = 2 (TRS) AND NOT futures. (Tier 1 - Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalCryptoManualPosition_TRS COMMENT 'Manual crypto TRS position amount. TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS. (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesCrypto_TRS COMMENT 'Crypto TRS liabilities. ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0). (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN MirrorRealFuturesPositionPnL COMMENT 'Unrealized PnL from copy-trading futures positions (IsFuture = 1 AND MirrorID > 0). (Tier 1 - Fact_CustomerUnrealized_PnL.MirrorRealFuturesPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN ManualRealFuturesPositionPnL COMMENT 'Unrealized PnL from manually-opened futures positions (IsFuture = 1 AND MirrorID = 0). (Tier 1 - Fact_CustomerUnrealized_PnL.ManualRealFuturesPositionPnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_FuturesReal COMMENT 'Net Open Position for futures instruments (IsFuture = 1). (Tier 1 - Fact_CustomerUnrealized_PnL.NOP_FuturesReal)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN Notional_FuturesReal COMMENT 'Absolute USD exposure for futures instruments. (Tier 1 - Fact_CustomerUnrealized_PnL.Notional_FuturesReal)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLFuturesReal COMMENT 'Total unrealized PnL from all futures positions (IsFuture = 1). (Tier 1 - Fact_CustomerUnrealized_PnL.PositionPnLFuturesReal)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN FullCommissionByUnitsFuturesReal COMMENT 'Full prorated commission for futures positions (before discounts). (Tier 1 - Fact_CustomerUnrealized_PnL.FullCommissionByUnitsFuturesReal)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN CommissionByUnitsFuturesReal COMMENT 'Prorated commission for futures positions (IsFuture = 1). (Tier 1 - Fact_CustomerUnrealized_PnL.CommissionByUnitsFuturesReal)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalMirrorRealFuturesPositionAmount COMMENT 'Sum of futures position amounts where MirrorID > 0. From Dim_Instrument_Snapshot.IsFuture = 1. (Tier 1 - Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalRealFutures COMMENT 'Sum of all futures position amounts (Dim_Instrument_Snapshot.IsFuture = 1). (Tier 1 - Fact_SnapshotEquity.TotalRealFutures)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalFuturesProviderMargin COMMENT 'Sum of provider margin for futures: LotCountDecimal x ProviderMarginPerLot. (Tier 1 - Fact_SnapshotEquity.TotalFuturesProviderMargin)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN LiabilitiesFuturesReal COMMENT 'Futures liabilities. ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0). (Tier 2 - V_Liabilities computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN NOP_StocksMargin COMMENT 'Net Open Position for stock margin positions (SettlementTypeID = 5). (Tier 1 - Fact_CustomerUnrealized_PnL.NOP_StocksMargin)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN PositionPnLStocksMargin COMMENT 'Unrealized PnL from stock margin positions (SettlementTypeID = 5). (Tier 1 - Fact_CustomerUnrealized_PnL.PositionPnLStocksMargin)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStocksMargin COMMENT 'Sum of stock margin position amounts (SettlementTypeID = 5). (Tier 1 - Fact_SnapshotEquity.TotalStocksMargin)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities ALTER COLUMN TotalStockMarginLoanValue COMMENT 'Loan value for leveraged stock margin positions: InitForexRate x AmountInUnitsDecimal x InitConversionRate - NewAmount (Leverage <> 1 only). (Tier 1 - Fact_SnapshotEquity.TotalStockMarginLoanValue)';

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
