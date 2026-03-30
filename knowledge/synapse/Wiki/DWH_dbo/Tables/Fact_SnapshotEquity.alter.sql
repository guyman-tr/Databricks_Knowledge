-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_SnapshotEquity
-- Synapse object: DWH_dbo.Fact_SnapshotEquity (base fact table)
-- UC Target:     main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity
--                (exported V_Fact_SnapshotEquity - _generic_pipeline_mapping.json generic_id=416)
-- Also exported: main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid (generic_id=1121)
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Resolved via: wiki Elements + mapping
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity SET TBLPROPERTIES (
    'comment' = 'Synapse table DWH_dbo.Fact_SnapshotEquity - daily customer equity snapshot (cash, positions, cashouts, realized equity, AUM, asset-class splits). UC object is the exported view V_Fact_SnapshotEquity (generic_id=416): adds DateKey via Dim_Range + Dim_Date; all fact columns pass through. Downstream: V_Liabilities and reporting. See wiki Fact_SnapshotEquity.md.'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity SET TAGS (
    'domain' = 'finance',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'synapse_object' = 'Fact_SnapshotEquity',
    'uc_export_view' = 'V_Fact_SnapshotEquity',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'CLUSTERED COLUMNSTORE; NCI on CID',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
-- View column DateKey (not on base Fact_SnapshotEquity table)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN DateKey COMMENT 'Calendar date key from Dim_Date (YYYYMMDD). One row per CID per day for each day in [Dim_Range.FromDateID, Dim_Range.ToDateID]; view filters DateKey < today. (Tier 2 - V_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CID COMMENT 'Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN DateRangeID COMMENT 'Encoded date range as 12-digit bigint (YYYYMMDDYYYY). FromDate in first 8 digits, ToDate suffix in last 4 digits. New rows get @date+1231; updated rows get end-date set to @daybefore. Decoded via Dim_Range. Part of PK. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalPositionsAmount COMMENT 'Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day closed positions (History.ClosePositionEndOfDay) minus History.Credit CreditTypeID=13 adjustments. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCash COMMENT 'Customer''s total cash balance for the day. Computed as: previous day''s TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN InProcessCashouts COMMENT 'Sum of pending withdrawal amounts for this CID that have not yet been finalized (statuses other than 3=Processed, 4=Cancelled, 5,6). Includes partially processed amounts for split-payment withdrawals plus associated fees. Computed by SP_Fact_SnapshotEquity_InProcessCashouts from Billing.Withdraw, History.WithdrawAction, and History.WithdrawToFundingAction. (Tier 2 - SP_Fact_SnapshotEquity_InProcessCashouts)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorPositionsAmount COMMENT 'Sum of position amounts where MirrorID > 0 AND ParentPositionID != 0 (copy-trading positions only, excluding the parent/guru''s own positions). Represents the CID''s total investment in copy relationships. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCash COMMENT 'Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockOrders COMMENT 'Legacy column, hardcoded to 0. Removed 2019-03-03 (Boris Slutski) - no data in PROD since 2015. Kept for schema compatibility. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockOrders COMMENT 'Legacy column, hardcoded to 0. Removed 2019-03-03 alongside TotalStockOrders. Kept for schema compatibility. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN RealizedEquity COMMENT 'Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: "Unrealized Equity - the total funds in the account, including profit/loss from open positions. The Portfolio value figure represented on the platform is Unrealized equity." (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Credit COMMENT 'Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day (selected via ROW_NUMBER partition by CID, ordered by Occurred DESC, CreditID DESC). Negative values represent outstanding obligations. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN AUM COMMENT 'Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. For MERGE INSERT: computed as TotalMirrorPositionsAmount + TotalMirrorCash. Confluence: "AUC (or AUM) on PI Dashboard: Total Unrealized Copy Amount of the Copiers." (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN BonusCredit COMMENT 'Bonus credit balance from History.ActiveCredit.BonusCredit. Confluence: "History.Credit.CreditTypeID = 5, 7 -> BackOffice.BonusType.BonusTypeID -> History.Credit.BonusTypeID". ISNULL to 0 in ETL. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN CreditID COMMENT 'Last CreditID for this CID on this date from History.ActiveCredit. Selected as the most recent credit event via ROW_NUMBER(PARTITION BY CID, DateID ORDER BY Occurred DESC, CreditID DESC). Used for auditing which credit record drives the snapshot. (Tier 2 - SP_Fact_SnapshotEquity_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (GETDATE() at MERGE/INSERT time). Used for detecting recent updates in the year-end carryover and IsSettled change handling. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockPositionAmount COMMENT 'Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6). Added with mutual exclusivity fix (Guy M, 2025-07-29). (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorStockPositionAmount COMMENT 'Mirror (copy-trading) subset of TotalStockPositionAmount. Adds MirrorID > 0 AND ParentPositionID != 0. Same mutual exclusivity fix with futures. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount COMMENT 'Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions. Confluence: "TotalCryptoPositionAmount + TotalStockPositionAmount = TotalPositionsAmount" (approximately, excluding other types). (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount COMMENT 'Mirror (copy-trading) subset of TotalCryptoPositionAmount. Same conditions plus MirrorID > 0 AND ParentPositionID != 0. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealStocks COMMENT 'Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND instrument is NOT a future. "Real" means the customer owns the underlying asset (settled/delivered). Updated via IsSettled change tracking from History.PositionChangeLog. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCrypto COMMENT 'Sum of position amounts where IsSettled = 1 AND InstrumentTypeID = 10 AND instrument is NOT a future. Real crypto ownership (settled positions). Updated via IsSettled change tracking. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealCryptoLoan COMMENT 'Sum of InitialAmount where IsSettled = 1 AND InstrumentTypeID = 10 AND NOT future AND Leverage = 2. Represents the initial investment in leveraged real crypto positions (the loan portion). Changed from Amount to InitialAmount on 2020-03-25. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCashCalculation COMMENT 'Parallel computation of TotalCash (same formula: TotalCashPreviousDate + TotalCashChangeAll). Exists as a validation/audit column to cross-check TotalCash. (Tier 2 - SP_Fact_SnapshotEquity)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalCryptoPositionAmount_TRS COMMENT 'Sum of crypto position amounts where SettlementTypeID = 2 (TRS - Total Return Swap) AND instrument is NOT a future. Added 2022-01-27 (Inbal BML). TRS positions have different regulatory treatment than settled positions. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorCryptoPositionAmount_TRS COMMENT 'Mirror (copy-trading) subset of TotalCryptoPositionAmount_TRS. TRS crypto positions in copy relationships. Added 2022-01-27. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN Total_TRSCrypto COMMENT 'Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto positions under TRS settlement (not yet settled to real ownership). Added 2022-01-27. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalMirrorRealFuturesPositionAmount COMMENT 'Sum of futures position amounts where MirrorID > 0. From Dim_Instrument_Snapshot.IsFuture = 1. Added 2024-10-30 (Daniel Kaplan). (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalRealFutures COMMENT 'Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID. Added 2024-10-30. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalFuturesProviderMargin COMMENT 'Sum of provider margin for futures positions: LotCountDecimal × Dim_Instrument_Snapshot.ProviderMarginPerLot. Represents the margin required by the futures provider. Added 2024-10-30. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalFuturesLockedCash COMMENT 'Cash locked in futures positions beyond provider margin: NewAmount - (LotCountDecimal × ProviderMarginPerLot). Represents customer cash tied up as additional margin. Added 2024-10-30. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStocksMargin COMMENT 'Sum of stock margin position amounts where SettlementTypeID = 5. Represents margin-traded stock positions (not fully settled). Added 2025-09-30 (Daniel Kaplan). (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockMarginLoanValue COMMENT 'Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1. Formula updated 2025-12-10 to use InitConversionRate. (Tier 2 - SP_Fact_SnapshotEquity_TotalPositionAmount)';

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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalFuturesProviderMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalFuturesLockedCash SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStocksMargin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity ALTER COLUMN TotalStockMarginLoanValue SET TAGS ('pii' = 'none');
