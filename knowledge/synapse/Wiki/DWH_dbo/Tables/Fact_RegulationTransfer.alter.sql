-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_RegulationTransfer
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer SET TBLPROPERTIES (
    'comment' = '`Fact_RegulationTransfer` captures the moment when a customer is transferred from one regulatory entity to another within the eToro platform. eToro operates under multiple regulatory frameworks globally (e.g., FCA in the UK, CySEC in Cyprus, ASIC in Australia, FinCEN in the US). When a customer''s regulatory jurisdiction changes - due to relocation, regulatory restructuring, or Brexit-related migrations - this table records: - **The transfer itself**: source and target regulation IDs, timestamp - **A complete financial snapshot**: the customer''s equity position as of the day before transfer, including cash, positions, PnL across asset classes (CFD, real stocks, crypto, futures, stock margin), liabilities, and AUM This enables: - **Regulatory reporting** - tracking customer migration between jurisdictions - **Financial reconciliation** - verifying asset values at point of transfer - **Risk analysis** - understanding the financial profile of migrating customers - **Audit trail** - complete record of when and ...'
);

ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer SET TAGS (
    'domain' = 'compliance',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'CLUSTERED INDEX (DateID ASC, CID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN FromRegulationID COMMENT 'Regulatory entity the customer was under BEFORE the transfer. JOINs to Dim_Regulation. (Tier 2 - SP_Fact_RegulationTransfer_DL_To_Synapse)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN ToRegulationID COMMENT 'Regulatory entity the customer was transferred TO. JOINs to Dim_Regulation. (Tier 2 - SP_Fact_RegulationTransfer_DL_To_Synapse)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN Occurred COMMENT 'Timestamp when the regulation transfer event occurred (ValidFrom of the new regulation record). (Tier 2 - SP_Fact_RegulationTransfer_DL_To_Synapse)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN DateID COMMENT 'Date of the regulation transfer in YYYYMMDD format. JOINs to Dim_Date. (Tier 2 - SP_Fact_RegulationTransfer_DL_To_Synapse)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN UnrealizedPnL COMMENT 'Total unrealized PnL across all open positions at time of transfer. From V_Liabilities.PositionPnL (day before). (Tier 2 - SP_Fact_RegulationTransfer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN ActualNWA COMMENT 'Net Withdrawable Amount - cash available for withdrawal. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN RealizedEquity COMMENT 'Realized equity balance - cash + realized PnL. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp - GETDATE() during SP execution. (Tier 2 - SP_Fact_RegulationTransfer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN CID COMMENT 'Customer ID (Real account). Distribution key. JOINs to Dim_Customer.RealCID. (Tier 2 - SP_Fact_RegulationTransfer_DL_To_Synapse)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalPositionsAmount COMMENT 'Total value of all open CFD positions. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalCash COMMENT 'Total cash balance in the account. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InProcessCashouts COMMENT 'Cash amount locked in pending withdrawal requests. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Total value of copy trading (mirror) positions. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalMirrorCash COMMENT 'Cash allocated to copy trading relationships. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalStockOrders COMMENT 'Total value of pending stock orders. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalMirrorStockOrders COMMENT 'Total value of pending stock orders via copy trading. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN Credit COMMENT 'Non-withdrawable promotional credit balance. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN AUM COMMENT 'Assets Under Management - total account value including positions, cash, and credits. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN BonusCredit COMMENT 'Bonus credit balance from promotional campaigns. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalLiability COMMENT 'Total liabilities owed by eToro to the customer. From V_Liabilities.Liabilities. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN WithdrawableLiability COMMENT 'Portion of liabilities that are withdrawable. From V_Liabilities.WA_Liabilities. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN LiabilityInUsedMargin COMMENT 'Liabilities locked as used margin. From V_Liabilities.Liabilities_InUsedMargin. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedRealStocks COMMENT 'Total invested in real stocks: PositionPnLStocksReal + TotalRealStocks. Computed in SP. (Tier 2 - SP_Fact_RegulationTransfer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedRealCrypto COMMENT 'Total invested in real crypto: PositionPnLCryptoReal + TotalRealCrypto. Computed in SP. (Tier 2 - SP_Fact_RegulationTransfer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLStocksReal COMMENT 'Unrealized PnL on real stock positions. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLCryptoReal COMMENT 'Unrealized PnL on real crypto positions. ISNULL to 0. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLFuturesReal COMMENT 'Unrealized PnL on real futures positions. ISNULL to 0. Added 2024-11. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedRealFutures COMMENT 'Total invested in real futures: PositionPnLFuturesReal + TotalRealFutures. Computed in SP. Added 2024-11. (Tier 2 - SP_Fact_RegulationTransfer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedStocksMargin COMMENT 'Total invested in margin stocks: PositionPnLStocksMargin + TotalStocksMargin. Computed in SP. Added 2025-10. (Tier 2 - SP_Fact_RegulationTransfer)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLStocksMargin COMMENT 'Unrealized PnL on stock margin positions. ISNULL to 0. Added 2025-10. (Tier 2 - V_Liabilities)';
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalStockMarginLoanValue COMMENT 'Total loan value for margin stock positions. ISNULL to 0. Added 2025-10. (Tier 2 - V_Liabilities)';

-- ---- Column PII Tags ----
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN FromRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN ToRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN UnrealizedPnL SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN ActualNWA SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalCash SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InProcessCashouts SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalMirrorPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalMirrorCash SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalStockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalMirrorStockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN AUM SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN BonusCredit SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalLiability SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN WithdrawableLiability SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN LiabilityInUsedMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedRealStocks SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedRealCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLStocksReal SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLCryptoReal SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLFuturesReal SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedRealFutures SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN InvestedStocksMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN PositionPnLStocksMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer ALTER COLUMN TotalStockMarginLoanValue SET TAGS ('pii' = 'none');
