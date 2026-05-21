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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CID COMMENT 'Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 - via Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN DateRangeID COMMENT 'Fact_SnapshotEquity.DateRangeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalPositionsAmount COMMENT 'Fact_SnapshotEquity.TotalPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCash COMMENT 'Fact_SnapshotEquity.TotalCash';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN InProcessCashouts COMMENT 'Fact_SnapshotEquity.InProcessCashouts';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCash COMMENT 'Fact_SnapshotEquity.TotalMirrorCash';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockOrders COMMENT 'Fact_SnapshotEquity.TotalStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockOrders COMMENT 'Fact_SnapshotEquity.TotalMirrorStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN RealizedEquity COMMENT 'Fact_SnapshotEquity.RealizedEquity';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Credit COMMENT 'Fact_SnapshotEquity.Credit';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN AUM COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. For MERGE INSERT: computed as TotalMirrorPositionsAmount + TotalMirrorCash. Confluence: "AUC (or AUM) on PI Dashboard: Total Unrealized Copy Amount of the Copiers.". (Tier 2 - via Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN BonusCredit COMMENT 'Fact_SnapshotEquity.BonusCredit';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CreditID COMMENT 'Fact_SnapshotEquity.CreditID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN UpdateDate COMMENT 'Fact_SnapshotEquity.UpdateDate';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockPositionAmount COMMENT 'Fact_SnapshotEquity.TotalStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealStocks COMMENT 'Fact_SnapshotEquity.TotalRealStocks';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCrypto COMMENT 'Fact_SnapshotEquity.TotalRealCrypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCryptoLoan COMMENT 'Fact_SnapshotEquity.TotalRealCryptoLoan';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCashCalculation COMMENT 'Fact_SnapshotEquity.TotalCashCalculation';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount_TRS COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount_TRS COMMENT 'Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Total_TRSCrypto COMMENT 'Fact_SnapshotEquity.Total_TRSCrypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorRealFuturesPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealFutures COMMENT 'Fact_SnapshotEquity.TotalRealFutures';

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
