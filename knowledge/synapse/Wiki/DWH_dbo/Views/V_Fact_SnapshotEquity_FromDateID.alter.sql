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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN FromDateID COMMENT 'Start date of the equity snapshot range (YYYYMMDD integer). (Tier 2 - view DDL)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN ToDateID COMMENT 'End date of the equity snapshot range (YYYYMMDD integer). Active rows have ToDateID = YYYY1231. (Tier 2 - view DDL)';
-- NOTE: Inherited Fact_SnapshotEquity columns omitted - bulk wildcard ALTER COLUMN not valid SQL.
-- Base table column descriptions live in Fact_SnapshotEquity.md and are applied via that table's alter.sql.

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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `CID` COMMENT 'Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `DateRangeID` COMMENT 'Encoded date range as 12-digit bigint (YYYYMMDDYYYY). FromDate in first 8 digits, ToDate suffix in last 4 digits. New rows get @date+1231; updated rows get end-date set to @daybefore. Decoded via Dim_Range. Part of PK. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalPositionsAmount` COMMENT 'Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCash` COMMENT 'Customer''s total cash balance for the day. Running-balance approach introduced 2020-06-07. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `InProcessCashouts` COMMENT 'Sum of pending withdrawal amounts not yet finalized. (Tier 2 - SP_Fact_SnapshotEquity_InProcessCashouts)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorPositionsAmount` COMMENT 'Sum of position amounts where MirrorID > 0 AND ParentPositionID != 0 (copy-trading positions only). (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCash` COMMENT 'Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalStockOrders` COMMENT 'Legacy column, hardcoded to 0. Removed 2019-03-03. Kept for schema compatibility. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorStockOrders` COMMENT 'Legacy column, hardcoded to 0. Removed 2019-03-03. Kept for schema compatibility. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `RealizedEquity` COMMENT 'Total account value: TotalCash + TotalPositionsAmount + InProcessCashouts (or direct from History.ActiveCredit.RealizedEquity if non-zero). (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `Credit` COMMENT 'Outstanding credit/bonus balance from History.ActiveCredit, last event per CID per day. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `AUM` COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `BonusCredit` COMMENT 'Bonus credit balance from History.ActiveCredit.BonusCredit. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `CreditID` COMMENT 'Last CreditID for this CID on this date from History.ActiveCredit. (Tier 2 - SP_Fact_SnapshotEquity_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `UpdateDate` COMMENT 'ETL load timestamp (GETDATE() at MERGE/INSERT time). (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalStockPositionAmount` COMMENT 'Sum of position amounts where InstrumentTypeID IN (5,6) AND not a future. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorStockPositionAmount` COMMENT 'Mirror subset of TotalStockPositionAmount. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCryptoPositionAmount` COMMENT 'Sum of position amounts where InstrumentTypeID = 10 AND not a future. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCryptoPositionAmount` COMMENT 'Mirror subset of TotalCryptoPositionAmount. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealStocks` COMMENT 'Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND not a future. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealCrypto` COMMENT 'Sum of position amounts where IsSettled = 1 AND InstrumentTypeID = 10 AND not a future. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalRealCryptoLoan` COMMENT 'Sum of InitialAmount where IsSettled = 1 AND InstrumentTypeID = 10 AND NOT future AND Leverage = 2. Changed from Amount to InitialAmount 2020-03-25. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCashCalculation` COMMENT 'Parallel computation of TotalCash for audit/validation purposes. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalCryptoPositionAmount_TRS` COMMENT 'Sum of crypto position amounts where SettlementTypeID = 2 (TRS). Added 2022-01-27. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `TotalMirrorCryptoPositionAmount_TRS` COMMENT 'Mirror subset of TotalCryptoPositionAmount_TRS. Added 2022-01-27. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid ALTER COLUMN `Total_TRSCrypto` COMMENT 'Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. Added 2022-01-27. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';

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
