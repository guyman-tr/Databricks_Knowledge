-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_SnapshotEquity_FromDateID
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid SET TBLPROPERTIES (
    'comment' = '| Property | Value | |----------|-------| | **Full Name** | `[DWH_dbo].[V_Fact_SnapshotEquity_FromDateID]` | | **Type** | View | | **Base Tables** | `Fact_SnapshotEquity`, `Dim_Range` | | **Purpose** | Exposes Fact_SnapshotEquity with explicit `FromDateID` and `ToDateID` columns from `Dim_Range`, enabling date-range filtering without an additional join to Dim_Date. |'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN FromDateID COMMENT 'Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - via Dim_Range)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN ToDateID COMMENT 'End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - via Dim_Range)';
-- NOTE: Inherited Fact_SnapshotEquity columns omitted - bulk wildcard ALTER COLUMN not valid SQL.
-- Base table column descriptions live in Fact_SnapshotEquity.md and are applied via that table's alter.sql.

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN CID COMMENT 'Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 - via Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN DateRangeID COMMENT 'Fact_SnapshotEquity.DateRangeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalPositionsAmount COMMENT 'Fact_SnapshotEquity.TotalPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalCash COMMENT 'Fact_SnapshotEquity.TotalCash';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN InProcessCashouts COMMENT 'Fact_SnapshotEquity.InProcessCashouts';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalMirrorCash COMMENT 'Fact_SnapshotEquity.TotalMirrorCash';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalStockOrders COMMENT 'Fact_SnapshotEquity.TotalStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalMirrorStockOrders COMMENT 'Fact_SnapshotEquity.TotalMirrorStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN RealizedEquity COMMENT 'Fact_SnapshotEquity.RealizedEquity';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN Credit COMMENT 'Fact_SnapshotEquity.Credit';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN AUM COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. For MERGE INSERT: computed as TotalMirrorPositionsAmount + TotalMirrorCash. Confluence: "AUC (or AUM) on PI Dashboard: Total Unrealized Copy Amount of the Copiers.". (Tier 2 - via Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN BonusCredit COMMENT 'Fact_SnapshotEquity.BonusCredit';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN CreditID COMMENT 'Fact_SnapshotEquity.CreditID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN UpdateDate COMMENT 'Fact_SnapshotEquity.UpdateDate';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalStockPositionAmount COMMENT 'Fact_SnapshotEquity.TotalStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalMirrorStockPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalCryptoPositionAmount COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalMirrorCryptoPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalRealStocks COMMENT 'Fact_SnapshotEquity.TotalRealStocks';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalRealCrypto COMMENT 'Fact_SnapshotEquity.TotalRealCrypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalRealCryptoLoan COMMENT 'Fact_SnapshotEquity.TotalRealCryptoLoan';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalCashCalculation COMMENT 'Fact_SnapshotEquity.TotalCashCalculation';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalCryptoPositionAmount_TRS COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalMirrorCryptoPositionAmount_TRS COMMENT 'Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN Total_TRSCrypto COMMENT 'Fact_SnapshotEquity.Total_TRSCrypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalMirrorRealFuturesPositionAmount COMMENT 'Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN TotalRealFutures COMMENT 'Fact_SnapshotEquity.TotalRealFutures';
-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN FromDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN ToDateID SET TAGS ('pii' = 'none');
-- NOTE: Inherited column PII tags omitted (same reason as above).

-- == LAST EXECUTION ==
-- Timestamp: 2026-04-12 UTC
-- Fix: Removed invalid 'All Fact_SnapshotEquity columns' ALTER COLUMN lines (bulk wildcard not valid SQL).
-- Statements: 6/6 succeeded
-- ====================

-- ============================================================
-- Inherited from Fact_SnapshotEquity (propagated 2026-04-12)
-- Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid
-- 26 column(s) | source: knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotEquity.alter.sql
-- ============================================================

-- ---- Column Comments (inherited) ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `CID` COMMENT 'Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 - via Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `DateRangeID` COMMENT 'Fact_SnapshotEquity.DateRangeID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalPositionsAmount` COMMENT 'Fact_SnapshotEquity.TotalPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCash` COMMENT 'Fact_SnapshotEquity.TotalCash';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `InProcessCashouts` COMMENT 'Fact_SnapshotEquity.InProcessCashouts';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorPositionsAmount` COMMENT 'Fact_SnapshotEquity.TotalMirrorPositionsAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCash` COMMENT 'Fact_SnapshotEquity.TotalMirrorCash';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalStockOrders` COMMENT 'Fact_SnapshotEquity.TotalStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorStockOrders` COMMENT 'Fact_SnapshotEquity.TotalMirrorStockOrders';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `RealizedEquity` COMMENT 'Fact_SnapshotEquity.RealizedEquity';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `Credit` COMMENT 'Fact_SnapshotEquity.Credit';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `AUM` COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. For MERGE INSERT: computed as TotalMirrorPositionsAmount + TotalMirrorCash. Confluence: "AUC (or AUM) on PI Dashboard: Total Unrealized Copy Amount of the Copiers.". (Tier 2 - via Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `BonusCredit` COMMENT 'Fact_SnapshotEquity.BonusCredit';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `CreditID` COMMENT 'Fact_SnapshotEquity.CreditID';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `UpdateDate` COMMENT 'Fact_SnapshotEquity.UpdateDate';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalStockPositionAmount` COMMENT 'Fact_SnapshotEquity.TotalStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorStockPositionAmount` COMMENT 'Fact_SnapshotEquity.TotalMirrorStockPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCryptoPositionAmount` COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCryptoPositionAmount` COMMENT 'Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealStocks` COMMENT 'Fact_SnapshotEquity.TotalRealStocks';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealCrypto` COMMENT 'Fact_SnapshotEquity.TotalRealCrypto';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealCryptoLoan` COMMENT 'Fact_SnapshotEquity.TotalRealCryptoLoan';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCashCalculation` COMMENT 'Fact_SnapshotEquity.TotalCashCalculation';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCryptoPositionAmount_TRS` COMMENT 'Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCryptoPositionAmount_TRS` COMMENT 'Fact_SnapshotEquity.TotalMirrorCryptoPositionAmount_TRS';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `Total_TRSCrypto` COMMENT 'Fact_SnapshotEquity.Total_TRSCrypto';

-- ---- Column PII Tags (inherited) ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `DateRangeID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalPositionsAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCash` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `InProcessCashouts` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorPositionsAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCash` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalStockOrders` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorStockOrders` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `RealizedEquity` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `Credit` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `AUM` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `BonusCredit` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `CreditID` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalStockPositionAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorStockPositionAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCryptoPositionAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCryptoPositionAmount` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealStocks` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealCrypto` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealCryptoLoan` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCashCalculation` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCryptoPositionAmount_TRS` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCryptoPositionAmount_TRS` SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `Total_TRSCrypto` SET TAGS ('pii' = 'none');

-- == PROPAGATION EXECUTION ==
-- Timestamp: 2026-04-12 UTC
-- Statements: 52/52 succeeded
-- ====================
