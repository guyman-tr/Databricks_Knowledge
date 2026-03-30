-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_AUM
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Fact_AUM > 7.4B-row DDR Assets Under Management fact table - daily per-customer snapshot of equity, invested amounts, NOP, PnL, and credit breakdowns across Trading Platform, CopyTrading, manual stocks/crypto, IBAN (eMoney), and Options (Apex), providing a unified AUM view for the Daily Data Report framework. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (Fact - DDR daily AUM snapshot) | | **Production Source** | Derived - multi-source aggregate via `SP_DDR_Fact_AUM` from `BI_DB_Client_Balance_CID_Level_New`, `V_Liabilities`, `eMoneyClientBalance`, `Function_AUM_OptionsPlatform` | | **Refresh** | Daily - `DELETE WHERE DateID = @dateID` + `INSERT` per business date | | | | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX | | | | | **UC Target** | _Pending - resolved during wr'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealCID COMMENT 'Real customer ID. COALESCE(cb.CID, i.CID, ob.RealCID) across TP, IBAN, and Options sources. HASH distribution key. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN DateID COMMENT 'Business date as YYYYMMDD integer. Delete/replace key for the daily load. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN Date COMMENT 'Calendar date for the batch - equals parameter `@date` in SP_DDR_Fact_AUM. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealizedEquityTP COMMENT 'Trading Platform realized equity. SUM(realizedEquity) from BI_DB_Client_Balance_CID_Level_New per CID/DateID. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalLiabilityTP COMMENT 'Trading Platform total liability. SUM(TotalLiability) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InProcessCashout COMMENT 'TP in-process cashout amount. SUM(InProcessCashout) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOP COMMENT 'Net Open Position - total notional exposure. SUM(NOP) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPCrypto COMMENT 'NOP for crypto positions. SUM(NOPCrypto) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPCryptoCFD COMMENT 'NOP for crypto CFD positions. SUM(NOPCryptoCFD) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPStocks COMMENT 'NOP for stock positions. SUM(NOPStocks) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPStocksCFD COMMENT 'NOP for stock CFD positions. SUM(NOPStocksCFD) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealCryptoLoan COMMENT 'Real crypto loan amount. SUM(TotalRealCryptoLoan) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalPositionPNL COMMENT 'Total position PnL (renamed from PositionPNL). SUM(PositionPNL) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalInvestedAmount COMMENT 'Total invested amount (renamed from PositionAmount). SUM(PositionAmount) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalEquityTP COMMENT 'Trading Platform total equity. SUM(ISNULL(TotalLiability,0) + ISNULL(actualNWA,0)) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN Bonus COMMENT 'Promotional bonus amount. SUM(Bonus) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CashInCopy COMMENT 'Cash allocated to copy trades. From V_Liabilities.TotalMirrorCash - total mirror cash held by copiers. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyInvestedAmount COMMENT 'Invested amount in copy trades. From V_Liabilities.TotalMirrorPositionsAmount - total mirror position amount. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyStockOrders COMMENT 'Stock orders within copy trades. From V_Liabilities.TotalMirrorStockOrders (legacy - always 0 since 2019). (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyPositionPnL COMMENT 'Unrealized PnL on copy positions. From V_Liabilities.CopyPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityCopy COMMENT 'Total copy equity. TotalMirrorCash + TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL from V_Liabilities. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountCopy COMMENT 'Invested amount in copy (excl cash). TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL from V_Liabilities. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StockInvestedAmount COMMENT 'Total stock position amount. From V_Liabilities.TotalStockPositionAmount via Fact_SnapshotEquity. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StockOrders COMMENT 'Total stock orders. From V_Liabilities.TotalStockOrders via Fact_SnapshotEquity (legacy - always 0 since 2019). (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StocksPositionPnL COMMENT 'Unrealized PnL on stock positions. From V_Liabilities.StocksPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN MirrorStockInvestedAmount COMMENT 'Stock position amount in copy trades. From V_Liabilities.TotalMirrorStockPositionAmount via Fact_SnapshotEquity. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN MirrorStocksPositionPnL COMMENT 'Stock PnL in copy trades. From V_Liabilities.MirrorStocksPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityStocksManual COMMENT 'Manual (non-copy) stock equity. TotalStockPositionAmount + TotalStockOrders + StocksPositionPnL - TotalMirrorStockPositionAmount - MirrorStocksPositionPnL. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountStocksManual COMMENT 'Manual stock invested amount (excl PnL). TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountCryptoManual COMMENT 'Manual crypto invested amount. From V_Liabilities.TotalCryptoManualPosition (= TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount). (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CryptoManualPositionPnL COMMENT 'Manual crypto unrealized PnL. From V_Liabilities.ManualCryptoPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityCryptoManual COMMENT 'Manual crypto total equity. TotalCryptoManualPosition + ManualCryptoPositionPnL from V_Liabilities. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealCrypto COMMENT 'Total real (non-CFD) crypto position amount. From V_Liabilities.TotalRealCrypto via Fact_SnapshotEquity. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealStocks COMMENT 'Total real (non-CFD) stock position amount. From V_Liabilities.TotalRealStocks via Fact_SnapshotEquity. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CreditTP COMMENT 'Trading Platform credit (promotional). From V_Liabilities.Credit via Fact_SnapshotEquity. Renamed from Credit. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN ActualNWA COMMENT 'Non-Withdrawable Amount - credit-capped net worth. From V_Liabilities.ActualNWA: CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END. (Tier 1 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN IBANBalance COMMENT 'IBAN (eMoney) balance in USD. SUM(ClosingBalanceBO × USDApproxRate) from eMoney_dbo.eMoneyClientBalance for the date. Excludes GCID=0 and NULL GCID. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealizedEquityGlobal COMMENT 'Global realized equity. RealizedEquityTP + IBANBalance. Options excluded because options cannot differentiate invested vs PnL. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalLiabilityGlobal COMMENT 'Global total liability. TotalLiabilityTP + IBANBalance + OptionsTotalEquity. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityGlobal COMMENT 'Global total equity across all platforms. TotalEquityTP + IBANBalance + OptionsTotalEquity. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CreditGlobal COMMENT 'Global credit. CreditTP + IBANBalance + OptionsCashEquity. Uses options cash component (not total). (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE() at insert time. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN OptionsTotalEquity COMMENT 'Options platform total equity from Apex buy-power summary. From Function_AUM_OptionsPlatform -> External_Sodreconciliation_apex_EXT981_BuyPowerSummary.TotalEquity. Uses latest available Apex date <= @dateID. Excludes house accounts (4GS43999, 4GS00100-104). (Tier 2 - SP_DDR_Fact_AUM)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealizedEquityTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalLiabilityTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InProcessCashout SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPCryptoCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPStocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPStocksCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealCryptoLoan SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalPositionPNL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalInvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalEquityTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN Bonus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CashInCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyInvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyStockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StockInvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StocksPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN MirrorStockInvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN MirrorStocksPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityStocksManual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountStocksManual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountCryptoManual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CryptoManualPositionPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityCryptoManual SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealStocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CreditTP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN ActualNWA SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN IBANBalance SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealizedEquityGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalLiabilityGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CreditGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN OptionsTotalEquity SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 16:03:52 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 88/88 succeeded
-- ====================
