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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. HASH distribution grain for this fact. Merge key `COALESCE(cb.CID, i.CID, ob.RealCID)` resolves TP + IBAN + Options shell customers. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN DateID COMMENT 'Business date encoded `YYYYMMDD`; matches `@dateID` CAST from `@date`; delete predicate key. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN Date COMMENT 'Calendar **`@date`** argument inserted literally; mirrors `DateID`. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealizedEquityTP COMMENT 'Customer''s **settled (realized) equity** - the realized portion of customer balance, **excluding unrealized PnL on open positions** (the unrealized component lives in `Fact_CustomerUnrealized_PnL.PositionPnL`). From `Fact_SnapshotEquity.RealizedEquity` via Client Balance. DDR transform: **SUM per CID/DateID** across Client Balance rows. (Tier 2 - SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalLiabilityTP COMMENT 'Total liability from open positions. From `V_Liabilities.Liabilities`. Represents the unrealized obligation (positive = amount owed to customer; negative = customer owes). DDR transform: SUM. (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InProcessCashout COMMENT 'Pending cashout amount not yet finalized. From `Fact_SnapshotEquity.InProcessCashouts`; excludes statuses 3=Processed, 4=Cancelled, 5, 6. DDR transform: SUM. (Tier 2 - SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOP COMMENT 'Total Net Open Position across all asset classes. From `V_Liabilities.NOP`. Net market exposure. DDR transform: SUM. (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPCrypto COMMENT 'Net Open Position for crypto instruments. From `V_Liabilities`. Represents the net market exposure in crypto. DDR transform: SUM. (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPCryptoCFD COMMENT 'NOP for crypto CFDs specifically (not settled/real crypto). DDR transform: SUM. (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPStocks COMMENT 'Net Open Position for stock instruments. DDR transform: SUM. (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN NOPStocksCFD COMMENT 'NOP for stock CFDs specifically. DDR transform: SUM. (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealCryptoLoan COMMENT 'Total leveraged real crypto loan amount. InitialAmount where `IsSettled=1` AND `InstrumentTypeID=10` AND `Leverage=2`. DDR transform: SUM. (Tier 2 - SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalPositionPNL COMMENT 'Total position PnL across all asset classes. From `V_Liabilities.PositionPnL`. Unrealized profit/loss on all open positions. DDR transform: SUM(`PositionPNL`). (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalInvestedAmount COMMENT 'Total position amount (`TotalPositionsAmount` lineage). Measures aggregate market value of exposures. DDR transform: SUM(`PositionAmount`). (Tier 2 - SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalEquityTP COMMENT 'Trading-platform **TotalEquity surrogate** summed as `SUM(ISNULL(TotalLiability,0) + ISNULL(actualNWA,0))` inside `#ClientBalance`. Not identical to interpreting “TP equity = liability view only”; treat as authoritative DDR column for `_TP` rollup. DDR transform: aggregate SUM pipeline. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN Bonus COMMENT 'Bonus credits (`ActionTypeID=9`). DDR transform: SUM. (Tier 2 - SP_Client_Balance_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CashInCopy COMMENT 'Allocation of **`TotalCash`** attributable to mirrored strategies - VL passes `Fact_SnapshotEquity.TotalMirrorCash`; represents copier-side cash earmarked inside copy envelopes. Passthrough VL daily snapshot filtered to `@dateID`. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorCash)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyInvestedAmount COMMENT '**`TotalMirrorPositionsAmount`** - mirrored strategy invested notionals aggregated at customer-day grain. Passthrough VL. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorPositionsAmount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyStockOrders COMMENT '**`TotalMirrorStockOrders`** - legacy pathway (documented VL as historically zero since 2019). Passthrough VL. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockOrders)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CopyPositionPnL COMMENT '**`CopyPositionPnL`** mirrored strategy unrealized incremental PnL component from **`Fact_CustomerUnrealized_PnL`** via VL. Passthrough VL. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.CopyPositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityCopy COMMENT '**Composite copy equity**: `TotalMirrorCash + TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`, null-guarded in SP verbatim block. Mirrors entire copy-trade economic bundle. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountCopy COMMENT '**`TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`** (copy invested + unrealized uplift). Cash excluded intentionally. SP-authored. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StockInvestedAmount COMMENT '**`TotalStockPositionAmount`** equities exposure aggregate from **`Fact_SnapshotEquity`** via VL. Passthrough VL. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockPositionAmount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StockOrders COMMENT '**`TotalStockOrders`** equity route (legacy zeros). VL passthrough. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalStockOrders)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN StocksPositionPnL COMMENT '**`StocksPositionPnL`** discretionary + house stock CFD PnL component from VL / FCUPNL join. Passthrough VL. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.StocksPositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN MirrorStockInvestedAmount COMMENT '**`TotalMirrorStockPositionAmount`** - stock exposure executed inside copy overlays. VL passthrough. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorStockPositionAmount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN MirrorStocksPositionPnL COMMENT '**`MirrorStocksPositionPnL`** VL field isolating mirrored stock PnL. Passthrough VL. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityStocksManual COMMENT 'Manual (non-copy) stock equity authored per SP verbatim difference of totals & mirrors (see lineage Phase 9). (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountStocksManual COMMENT 'Manual invested-only stock footprint **excluding** mirrored mirror stock leg (SP subtract). (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN InvestedAmountCryptoManual COMMENT '**`TotalCryptoManualPosition`** = `TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount` per VL formula; VL-classified Tier-2 derivation because computed inside view. Alias renamed in DDR inserts. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CryptoManualPositionPnL COMMENT '**`ManualCryptoPositionPnL`** from FCUPNL via VL passthrough representing manual-route crypto PnL. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityCryptoManual COMMENT '**Manual crypto bundle** sums `TotalCryptoManualPosition + ManualCryptoPositionPnL` with DDR null guards. Authored `#vl`. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealCrypto COMMENT '**`Fact_SnapshotEquity.TotalRealCrypto`** - outright crypto inventory dollars. VL passthrough. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealCrypto)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalRealStocks COMMENT '**`Fact_SnapshotEquity.TotalRealStocks`** - shares / cash equities inventories. VL passthrough. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalRealStocks)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CreditTP COMMENT 'Promotional **`Credit`** component from VL / `Fact_SnapshotEquity.Credit`; column renamed **`CreditTP`** for DDR clarity while identical numeric semantics. VL passthrough. (Tier 1 - DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN ActualNWA COMMENT 'VL-computed capped net-worth share: **`CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END`** where `NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0)` (VL section 2.2). Passthrough VL. (Tier 2 - DWH_dbo.V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN IBANBalance COMMENT '**Non-TP** IBAN-held balance aggregated `SUM(mcb.ClosingBalanceBO * mcb.USDApproxRate)` excluding `GCID IS NULL OR GCID=0`. Explicit USD approximation path. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN RealizedEquityGlobal COMMENT '**`RealizedEquityTP + IBANBalance`**; excludes Options equities per SP explanatory comment inability to split invested vs PnL. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN TotalLiabilityGlobal COMMENT '**`TotalLiabilityTP + IBANBalance + OptionsTotalEquity`** verbatim from `#final`. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN EquityGlobal COMMENT '**`TotalEquityTP + IBANBalance + OptionsTotalEquity`** - consolidated **DDR AUM / equity-under-management style metric**. Filter axis for primary INSERT. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN CreditGlobal COMMENT '**`CreditTP + IBANBalance + OptionsCashEquity`** - injects Apex **cash** component only (distinct from **`OptionsTotalEquity`** numerator). Authored verbatim in SP. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN UpdateDate COMMENT '**GETDATE()`** stamp aligning insert batch concurrency control. (Tier 2 - SP_DDR_Fact_AUM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum ALTER COLUMN OptionsTotalEquity COMMENT 'Apex options economic value from **`Function_AUM_OptionsPlatform(@OptionsMaxDateID,0)`** keyed on latest external buy-power close <= ingestion; merges by `FULL OUTER` on **`RealCID`**; precision widened DDL `decimal(18,6)` versus TP metrics. House IDs filtered inside downstream function lineage. (Tier 2 - SP_DDR_Fact_AUM)';

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

