-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_CustomerUnrealized_PnL
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl SET TBLPROPERTIES (
    'comment' = '`Fact_CustomerUnrealized_PnL` stores a daily end-of-day unrealized profit/loss snapshot per customer. While `Fact_SnapshotEquity` captures the balance sheet (cash, positions, AUM), this table captures the income statement — how much each customer is up or down on their open positions. The table answers: - **How much is each customer making/losing today?** (PositionPnL — total unrealized PnL in USD) - **Where is the PnL coming from?** — split by asset class (stocks, crypto, futures, stock margin), settlement type (real/CFD/TRS), and ownership (manual vs copy vs guru) - **What is the platform''s exposure?** — NOP (Net Open Position, signed directional exposure) and Notional (absolute exposure) per asset class - **What is the commission revenue?** — CommissionOnOpen, CommissionByUnits broken down by asset class - **How risky is each customer''s portfolio?** — StandardDeviation computed from instrument covariance matrix ### Business Context (from Confluence) - **Unrealized PnL**: "PnL of customer opened positions" '
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl SET TAGS (
    'domain' = 'customer',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CID COMMENT 'Customer ID. Grouping key for all PnL aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key, part of PK. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN DateModified COMMENT 'Date key in YYYYMMDD integer format. Part of PK. One row per CID per day. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnL COMMENT 'Total unrealized PnL in USD across all open positions for this CID on this date. Uses V1 formula (PnLInDollars from staging). This is the primary PnL metric. "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyPositionPnL COMMENT 'Unrealized PnL from copy-trading positions only (MirrorID > 0). Includes all asset classes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN MenualPositionPnL COMMENT 'Unrealized PnL from manually-opened positions only (MirrorID = 0). Note: column name is a typo for "Manual". (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN StocksPositionPnL COMMENT 'Unrealized PnL from stock positions (InstrumentTypeID IN (5,6) AND NOT futures). Includes both real and CFD stocks, both manual and copy. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (GETDATE() at INSERT time). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN TransURPnL COMMENT 'Transaction unrealized PnL. Not populated by the current ETL SP — always NULL. Legacy column. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN StandardDeviation COMMENT 'Portfolio risk measure: standard deviation of the customer''s weighted portfolio computed from instrument covariance matrix. Only calculated for dates >= 2012-12-31. Formula: √(Σ weight_a × weight_b × covariance). NULL for pre-2013 data. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionOnOpen COMMENT 'Sum of opening commissions (Commission) across all open positions for this CID. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN MirrorStocksPositionPnL COMMENT 'Unrealized PnL from copy-trading stock positions (InstrumentTypeID IN (5,6) AND NOT futures AND MirrorID > 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CryptoPositionPnL COMMENT 'Unrealized PnL from all crypto positions (InstrumentTypeID = 10 AND NOT futures). Includes real, CFD, manual, and copy. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN ManualCryptoPositionPnL COMMENT 'Unrealized PnL from manually-opened crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyCryptoPositionPnL COMMENT 'Unrealized PnL from copy-trading crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID > 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyFundPnL COMMENT 'Unrealized PnL from positions opened via copy-fund relationships (parent CID had AccountTypeID=9 at the time the copy was opened). Identified via History.BackOfficeCustomer + History.Mirror join. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionOnOpen COMMENT 'Sum of full opening commissions (FullCommission, before any discounts) across all open positions for this CID. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP COMMENT 'Net Open Position — total signed directional USD exposure across all instruments. Positive = net long, negative = net short. "eToro holding of each instrument" (Confluence). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional COMMENT 'Total absolute USD exposure across all instruments. ABS(NOP) per instrument, then summed. Always >= 0. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Crypto COMMENT 'Net Open Position for crypto instruments only (InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Crypto COMMENT 'Absolute USD exposure for crypto instruments only. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_CFD COMMENT 'Net Open Position for all CFD positions (IsSettled = 0), all asset classes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_CFD COMMENT 'Absolute USD exposure for all CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Crypto_CFD COMMENT 'Net Open Position for crypto CFD positions (InstrumentTypeID = 10 AND IsSettled = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Crypto_CFD COMMENT 'Absolute USD exposure for crypto CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnits COMMENT 'Sum of prorated commissions (CommissionByUnits) across all open positions. Accounts for partial closes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnits COMMENT 'Sum of full prorated commissions (FullCommissionByUnits, before discounts) across all open positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Stock COMMENT 'Net Open Position for stock instruments (InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Stock COMMENT 'Absolute USD exposure for stock instruments. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Stock_CFD COMMENT 'Net Open Position for stock CFD positions (InstrumentTypeID IN (5,6) AND IsSettled = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Stock_CFD COMMENT 'Absolute USD exposure for stock CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLStocksReal COMMENT 'Unrealized PnL from real (settled) stock positions only (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). Uses PnLInDollars. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLCryptoReal COMMENT 'Unrealized PnL from real (settled) crypto positions only (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). Uses PnLInDollars. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsStocksReal COMMENT 'Full prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsCryptoReal COMMENT 'Full prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN GuruCopiesPNL COMMENT 'Unrealized PnL from guru-connected copy positions (ConnectedGuruCopies = 1 AND MirrorID > 0). ConnectedGuruCopies = 1 means ParentPositionID != 0. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN GuruCopiesPNL_Dit COMMENT 'Unrealized PnL from non-guru-connected copy positions (ConnectedGuruCopies = 0 AND MirrorID > 0). "Dit" = direct copy without guru position linkage. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsStocksReal COMMENT 'Prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsCryptoReal COMMENT 'Prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsStocksCFD COMMENT 'Full prorated commission for stock CFD positions (IsSettled = 0 AND InstrumentTypeID IN (5,6)). Added 2021-12-19 (Adi F). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsCryptoCFD COMMENT 'Full prorated commission for crypto CFD positions (IsSettled = 0 AND InstrumentTypeID = 10). Added 2021-12-19 (Adi F). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsCrypto_TRS COMMENT 'Prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). Added 2022-01-27 (Inbal BML). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyCryptoPositionPnL_TRS COMMENT 'Unrealized PnL from copy-trading crypto TRS positions (InstrumentTypeID = 10 AND MirrorID > 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CryptoPositionPnL_TRS COMMENT 'Unrealized PnL from all crypto TRS positions (InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsCrypto_TRS COMMENT 'Full prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN ManualCryptoPositionPnL_TRS COMMENT 'Unrealized PnL from manually-opened crypto TRS positions (InstrumentTypeID = 10 AND MirrorID = 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Crypto_TRS COMMENT 'Net Open Position for crypto TRS positions (InstrumentTypeID = 10 AND IsSettled = 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Crypto_TRS COMMENT 'Absolute USD exposure for crypto TRS positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnL_old COMMENT 'Legacy PnL calculated using V0 formula (CalculatedNetProfit from bid/ask price differences). Kept for V0-vs-V1 gap monitoring (SP_PNL_Alerts_Gap_Old_VS_New). Will eventually be deprecated. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN MirrorRealFuturesPositionPnL COMMENT 'Unrealized PnL from copy-trading futures positions (IsFuture = 1 AND MirrorID > 0). Uses PnLInDollars. Added 2024-11-10 (Daniel Kaplan). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN ManualRealFuturesPositionPnL COMMENT 'Unrealized PnL from manually-opened futures positions (IsFuture = 1 AND MirrorID = 0). Uses PnLInDollars. Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_FuturesReal COMMENT 'Net Open Position for futures instruments (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_FuturesReal COMMENT 'Absolute USD exposure for futures instruments. Always positive (uses ABS for sell positions). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLFuturesReal COMMENT 'Total unrealized PnL from all futures positions (IsFuture = 1). Uses PnLInDollars. Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsFuturesReal COMMENT 'Full prorated commission for futures positions (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsFuturesReal COMMENT 'Prorated commission for futures positions (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_StocksMargin COMMENT 'Net Open Position for stock margin positions (SettlementTypeID = 5). Added 2025-09-25 (Daniel Kaplan). (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLStocksMargin COMMENT 'Unrealized PnL from stock margin positions (SettlementTypeID = 5). Uses PnLInDollars. Added 2025-09-25. (Tier 2 — SP_Fact_CustomerUnrealized_PnL)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN DateModified SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN MenualPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN StocksPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN TransURPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN StandardDeviation SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN MirrorStocksPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CryptoPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN ManualCryptoPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyCryptoPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyFundPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Crypto_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Crypto_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Stock SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Stock SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Stock_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Stock_CFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLStocksReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLCryptoReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsStocksReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsCryptoReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN GuruCopiesPNL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN GuruCopiesPNL_Dit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsStocksReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsCryptoReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsStocksCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsCryptoCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsCrypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CopyCryptoPositionPnL_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CryptoPositionPnL_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsCrypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN ManualCryptoPositionPnL_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_Crypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_Crypto_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnL_old SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN MirrorRealFuturesPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN ManualRealFuturesPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_FuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN Notional_FuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN FullCommissionByUnitsFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN CommissionByUnitsFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN NOP_StocksMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl ALTER COLUMN PositionPnLStocksMargin SET TAGS ('pii' = 'none');
