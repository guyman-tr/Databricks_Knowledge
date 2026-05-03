-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_SnapshotEquity
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.V_Fact_SnapshotEquity'
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity SET TAGS (
    'source_schema' = 'DWH_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN DateKey COMMENT 'Specific date within the snapshot range (YYYYMMDD integer). One row per day per customer. (Tier 2 - view DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CID COMMENT 'Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN DateRangeID COMMENT 'Encoded date range as 12-digit bigint (YYYYMMDDYYYY). Decoded via Dim_Range. Part of PK. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalPositionsAmount COMMENT 'Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCash COMMENT 'Customer''s total cash balance for the day. Running-balance approach. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN InProcessCashouts COMMENT 'Sum of pending withdrawal amounts not yet finalized. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Sum of copy-trading position amounts (MirrorID > 0 AND ParentPositionID != 0). (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCash COMMENT 'Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockOrders COMMENT 'Legacy column, hardcoded to 0. Kept for schema compatibility. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockOrders COMMENT 'Legacy column, hardcoded to 0. Kept for schema compatibility. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN RealizedEquity COMMENT 'Total account value. From History.ActiveCredit.RealizedEquity if non-zero; otherwise TotalCash + TotalPositionsAmount + InProcessCashouts. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Credit COMMENT 'Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN AUM COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN BonusCredit COMMENT 'Bonus credit balance from History.ActiveCredit.BonusCredit. ISNULL to 0 in ETL. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CreditID COMMENT 'Last CreditID for this CID on this date from History.ActiveCredit. Audit column. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (GETDATE() at MERGE/INSERT time). (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockPositionAmount COMMENT 'Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockPositionAmount COMMENT 'Mirror (copy-trading) subset of TotalStockPositionAmount. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount COMMENT 'Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount COMMENT 'Mirror subset of TotalCryptoPositionAmount. MirrorID > 0 AND ParentPositionID != 0. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealStocks COMMENT 'Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT future. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCrypto COMMENT 'Settled crypto positions (IsSettled = 1, InstrumentTypeID = 10, NOT future). (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCryptoLoan COMMENT 'Sum of InitialAmount for leveraged real crypto (IsSettled = 1, Leverage = 2). (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCashCalculation COMMENT 'Parallel computation of TotalCash for validation/audit. Cross-check column. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount_TRS COMMENT 'Crypto positions where SettlementTypeID = 2 (TRS). (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount_TRS COMMENT 'Mirror subset of TRS crypto positions. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Total_TRSCrypto COMMENT 'CFD-style crypto under TRS settlement (IsSettled = 0, SettlementTypeID = 2). (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorRealFuturesPositionAmount COMMENT 'Futures position amounts where MirrorID > 0. (Tier 1 - inherited from Fact_SnapshotEquity wiki)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealFutures COMMENT 'Sum of all futures position amounts (IsFuture = 1). (Tier 1 - inherited from Fact_SnapshotEquity wiki)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN DateKey SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN DateRangeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCash SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN InProcessCashouts SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorPositionsAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCash SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockOrders SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN AUM SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN BonusCredit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CreditID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealStocks SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCryptoLoan SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCashCalculation SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount_TRS SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Total_TRSCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorRealFuturesPositionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealFutures SET TAGS ('pii' = 'none');
