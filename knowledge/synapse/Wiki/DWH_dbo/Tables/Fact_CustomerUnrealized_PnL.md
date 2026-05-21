# DWH_dbo.Fact_CustomerUnrealized_PnL

> Daily customer-level unrealized PnL snapshot aggregating all open position profit/loss, commissions, Net Open Position (NOP) exposure, and notional values — broken down by asset class (stocks, crypto, futures, stock margin), settlement type (real vs CFD vs TRS), and ownership (manual vs copy vs copy-fund vs guru-connected) — with portfolio risk (standard deviation) computed from instrument covariance matrices.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | Trade.OpenPositionEndOfDay + History.ClosePositionEndOfDay + PriceLog (multi-source aggregate) |
| **Key Identifier** | CID + DateModified (PK NOT ENFORCED) |
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED COLUMNSTORE |
| **Column Count** | 57 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl` |
| **Refresh** | Daily |
| **ETL Pattern** | Multi-SP orchestration: staging extract → price lookup → PnL calculation → NOP/Notional → risk → INSERT |

---

## 1. Business Meaning

`Fact_CustomerUnrealized_PnL` stores a daily end-of-day unrealized profit/loss snapshot per customer. While `Fact_SnapshotEquity` captures the balance sheet (cash, positions, AUM), this table captures the income statement — how much each customer is up or down on their open positions.

The table answers:
- **How much is each customer making/losing today?** (PositionPnL — total unrealized PnL in USD)
- **Where is the PnL coming from?** — split by asset class (stocks, crypto, futures, stock margin), settlement type (real/CFD/TRS), and ownership (manual vs copy vs guru)
- **What is the platform's exposure?** — NOP (Net Open Position, signed directional exposure) and Notional (absolute exposure) per asset class
- **What is the commission revenue?** — CommissionOnOpen, CommissionByUnits broken down by asset class
- **How risky is each customer's portfolio?** — StandardDeviation computed from instrument covariance matrix

### Business Context (from Confluence)

- **Unrealized PnL**: "PnL of customer opened positions" — the difference between realized equity and unrealized equity (Confluence: Basic Concepts)
- **NOP**: "Net of positions — eToro holding of each instrument" — signed directional exposure in USD (Confluence: Basic Concepts)
- **V0 vs V1 PnL**: The PnL calculation underwent a major migration. PositionPnL_old uses the V0 formula (CalculatedNetProfit from price differences). PositionPnL uses V1 PnLInDollars from the staging view. Gaps are monitored via SP_PNL_Alerts_Gap_Old_VS_New (Confluence: PnL Milestone #2)
- **V_Liabilities**: "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence: Summary of V-Liabilities)

---

## 2. Business Logic

### 2.1 ETL Orchestration (SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse)

Extracts 8 staging tables then calls the main computation SP:

```
1. Ext_FCUPNL_History_SplitRatio      ← History.SplitRatio (stock split adjustment ratios)
2. Ext_FCUPNL_BackOfficeCustomer      ← History.BackOfficeCustomer (fund accounts: AccountTypeID=9)
3. Ext_FCUPNL_Dictionary_Instrument   ← Trade.GetInstrument (instrument metadata)
4. Ext_FCUPNL_History_Mirror          ← History.Mirror (MirrorOperationID=1: copy-open events)
5. Ext_FCUPNL_History_Position        ← History.ClosePositionEndOfDay (same-day closed, with GetInstrument)
6. Ext_FCUPNL_Trade_Position          ← Trade.OpenPositionEndOfDay (open positions, with GetInstrument)
7. Ext_FCUPNL_PositionChangeLog       ← History.PositionChangeLog (IsSettled changes)
8. Ext_FCUPNL_CurrencyPriceMaxDateWithSplit ← PriceLog_Candles_CurrencyPriceMaxDateWithSplitView
→ EXEC SP_Fact_CustomerUnrealized_PnL @dt
```

### 2.2 Main Computation (SP_Fact_CustomerUnrealized_PnL)

```
Phase 1: Revert IsSettled via PositionChangeLog (same as SnapshotEquity)
Phase 2: Get prices — spreaded bid/ask with split ratio adjustment
Phase 3: Identify CopyFund positions (parent CID had AccountTypeID=9 at position open time)
Phase 4: Build #OpenPositions — UNION of trade + history positions with prices, split-adjusted
Phase 5: Identify futures (Dim_Instrument.IsFuture=1)
Phase 6: Aggregate partial closes → #OpenPositionsFinal (GROUP BY OriginalPositionID)
Phase 7: Compute EndConvertionRate (USD conversion for non-USD instruments via currency pair chain)
Phase 8: Compute #UnrealizedPnL — per-position CalculatedNetProfit using V0 or V1 formula
Phase 9: Compute #final_NOP_Notional — per-CID NOP and Notional by asset class
Phase 10: Compute #CIDsRisk — portfolio standard deviation from covariance matrix
Phase 11: Final INSERT — aggregate per-position data into per-CID summaries
Phase 12: Copy subset to Fact_CustomerUnrealized_PnL_UserAPI
```

### 2.3 PnL Formula (V0 vs V1)

```sql
-- V0 (PnLVersion=0, PositionPnL_old):
CalculatedNetProfit = (RateBid/RateAsk - InitForexRate) × EndConvertionRate × AmountInUnitsDecimal

-- V1 (PnLVersion=1, PositionPnL):
CalculatedNetProfit = (Rate × EndConvertionRate - InitForexRate × InitConversionRate) × AmountInUnitsDecimal
```

V1 introduced 2024-01-03 (Katy F) to handle multi-currency PnL more accurately by separating init and end conversion rates.

### 2.4 NOP/Notional Computation

NOP = signed directional USD exposure: `AmountInUnitsDecimal × Rate × Direction × USDConversion`
Notional = ABS(NOP) — absolute exposure

Both are computed for each asset class filter (all, crypto, CFD, crypto-CFD, stock, stock-CFD, crypto-TRS, futures-real, stock-margin).

### 2.5 Portfolio Risk (StandardDeviation)

Computed only for dates >= 2012-12-31. Uses instrument covariance matrix from `Dim_Instrument_Correlation` (weekly, SampleSize > 100). Formula: `√(Σ(weight_a × weight_b × covariance))` where weights = position USD value / equity.

### 2.6 Asset Class Classification

Same mutual exclusivity rules as Fact_SnapshotEquity (Guy M fix, 2025-07-29):
- **Stocks**: InstrumentTypeID IN (5,6) AND NOT futures
- **Crypto**: InstrumentTypeID = 10 AND NOT futures
- **Futures**: Dim_Instrument.IsFuture = 1
- **Stock Margin**: SettlementTypeID = 5
- **Real**: IsSettled = 1
- **CFD**: IsSettled = 0
- **TRS**: SettlementTypeID = 2

---

## 3. Query Advisory

### 3.1 Distribution & Indexing

- **HASH(CID)**: Customer-specific queries are single-node. Date-range queries across customers require data movement.
- **CLUSTERED COLUMNSTORE**: Optimized for analytical aggregations across many customers. Many columns are zero for most rows (sparse data).
- **PK (CID, DateModified) NOT ENFORCED**: Logical uniqueness — one row per customer per day.

### 3.2 Data Freshness

- Daily load via SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse
- Depends on DWH_staging position tables and price data being loaded first
- After main fact INSERT, a subset is copied to Fact_CustomerUnrealized_PnL_UserAPI for API consumption

---

## 4. Elements

> Note: This is a fully DWH-computed table. All 57 columns are aggregated/computed by the ETL SPs from position data, price data, and risk matrices. No upstream production wikis exist for the primary sources. All columns are Tier 2.

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID. Grouping key for all PnL aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key, part of PK. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 2 | DateModified | int | NO | Date key in YYYYMMDD integer format. Part of PK. One row per CID per day. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 3 | PositionPnL | decimal(16,2) | NO | Total unrealized PnL in USD across all open positions for this CID on this date. Uses V1 formula (PnLInDollars from staging). This is the primary PnL metric. "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 4 | CopyPositionPnL | decimal(16,2) | NO | Unrealized PnL from copy-trading positions only (MirrorID > 0). Includes all asset classes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 5 | MenualPositionPnL | decimal(16,2) | NO | Unrealized PnL from manually-opened positions only (MirrorID = 0). Note: column name is a typo for "Manual". (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 6 | StocksPositionPnL | decimal(16,2) | NO | Unrealized PnL from stock positions (InstrumentTypeID IN (5,6) AND NOT futures). Includes both real and CFD stocks, both manual and copy. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 7 | UpdateDate | datetime | YES | ETL load timestamp (GETDATE() at INSERT time). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 8 | TransURPnL | decimal(16,2) | YES | Transaction unrealized PnL. Not populated by the current ETL SP — always NULL. Legacy column. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 9 | StandardDeviation | float | YES | Portfolio risk measure: standard deviation of the customer's weighted portfolio computed from instrument covariance matrix. Only calculated for dates >= 2012-12-31. Formula: √(Σ weight_a × weight_b × covariance). NULL for pre-2013 data. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 10 | CommissionOnOpen | decimal(16,2) | YES | Sum of opening commissions (Commission) across all open positions for this CID. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 11 | MirrorStocksPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading stock positions (InstrumentTypeID IN (5,6) AND NOT futures AND MirrorID > 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 12 | CryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from all crypto positions (InstrumentTypeID = 10 AND NOT futures). Includes real, CFD, manual, and copy. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 13 | ManualCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from manually-opened crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 14 | CopyCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID > 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 15 | CopyFundPnL | decimal(16,2) | YES | Unrealized PnL from positions opened via copy-fund relationships (parent CID had AccountTypeID=9 at the time the copy was opened). Identified via History.BackOfficeCustomer + History.Mirror join. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 16 | FullCommissionOnOpen | decimal(16,2) | YES | Sum of full opening commissions (FullCommission, before any discounts) across all open positions for this CID. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 17 | NOP | decimal(16,2) | YES | Net Open Position — total signed directional USD exposure across all instruments. Positive = net long, negative = net short. "eToro holding of each instrument" (Confluence). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 18 | Notional | decimal(16,2) | YES | Total absolute USD exposure across all positions. Computed as SUM(ABS(per-position signed USD exposure)) grouped by CID — ABS is applied per position, not per instrument. Always >= 0. |
| 19 | NOP_Crypto | decimal(16,2) | YES | Net Open Position for crypto instruments only (InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 20 | Notional_Crypto | decimal(16,2) | YES | Absolute USD exposure for crypto instruments only. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 21 | NOP_CFD | decimal(16,2) | YES | Net Open Position for all CFD positions (IsSettled = 0), all asset classes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 22 | Notional_CFD | decimal(16,2) | YES | Absolute USD exposure for all CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 23 | NOP_Crypto_CFD | decimal(16,2) | YES | Net Open Position for crypto CFD positions (InstrumentTypeID = 10 AND IsSettled = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 24 | Notional_Crypto_CFD | decimal(16,2) | YES | Absolute USD exposure for crypto CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 25 | CommissionByUnits | decimal(38,6) | YES | Sum of prorated commissions (CommissionByUnits) across all open positions. Accounts for partial closes. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 26 | FullCommissionByUnits | decimal(38,6) | YES | Sum of full prorated commissions (FullCommissionByUnits, before discounts) across all open positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 27 | NOP_Stock | decimal(16,2) | YES | Net Open Position for stock instruments (InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 28 | Notional_Stock | decimal(16,2) | YES | Absolute USD exposure for stock instruments. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 29 | NOP_Stock_CFD | decimal(16,2) | YES | Net Open Position for stock CFD positions (InstrumentTypeID IN (5,6) AND IsSettled = 0). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 30 | Notional_Stock_CFD | decimal(16,2) | YES | Absolute USD exposure for stock CFD positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 31 | PositionPnLStocksReal | decimal(16,2) | YES | Unrealized PnL from real (settled) stock positions only (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). Uses PnLInDollars. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 32 | PositionPnLCryptoReal | decimal(16,2) | YES | Unrealized PnL from real (settled) crypto positions only (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). Uses PnLInDollars. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 33 | FullCommissionByUnitsStocksReal | decimal(38,6) | YES | Full prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 34 | FullCommissionByUnitsCryptoReal | decimal(38,6) | YES | Full prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 35 | GuruCopiesPNL | decimal(16,2) | YES | Unrealized PnL from guru-connected copy positions (ConnectedGuruCopies = 1 AND MirrorID > 0). ConnectedGuruCopies = 1 means ParentPositionID != 0. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 36 | GuruCopiesPNL_Dit | decimal(16,2) | YES | Unrealized PnL from non-guru-connected copy positions (ConnectedGuruCopies = 0 AND MirrorID > 0). "Dit" = direct copy without guru position linkage. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 37 | CommissionByUnitsStocksReal | decimal(38,6) | YES | Prorated commission for real stock positions (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 38 | CommissionByUnitsCryptoReal | decimal(38,6) | YES | Prorated commission for real crypto positions (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 39 | FullCommissionByUnitsStocksCFD | decimal(38,6) | YES | Full prorated commission for stock CFD positions (IsSettled = 0 AND InstrumentTypeID IN (5,6)). Added 2021-12-19 (Adi F). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 40 | FullCommissionByUnitsCryptoCFD | decimal(38,6) | YES | Full prorated commission for crypto CFD positions (IsSettled = 0 AND InstrumentTypeID = 10). Added 2021-12-19 (Adi F). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 41 | CommissionByUnitsCrypto_TRS | decimal(38,6) | YES | Prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). Added 2022-01-27 (Inbal BML). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 42 | CopyCryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from copy-trading crypto TRS positions (InstrumentTypeID = 10 AND MirrorID > 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 43 | CryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from all crypto TRS positions (InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 44 | FullCommissionByUnitsCrypto_TRS | decimal(38,6) | YES | Full prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 45 | ManualCryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from manually-opened crypto TRS positions (InstrumentTypeID = 10 AND MirrorID = 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 46 | NOP_Crypto_TRS | decimal(16,2) | YES | Net Open Position for crypto TRS positions (InstrumentTypeID = 10 AND IsSettled = 0 AND SettlementTypeID = 2). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 47 | Notional_Crypto_TRS | decimal(16,2) | YES | Absolute USD exposure for crypto TRS positions. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 48 | PositionPnL_old | decimal(38,6) | YES | Legacy PnL calculated using V0 formula (CalculatedNetProfit from bid/ask price differences). Kept for V0-vs-V1 gap monitoring (SP_PNL_Alerts_Gap_Old_VS_New). Will eventually be deprecated. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 49 | MirrorRealFuturesPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading futures positions (IsFuture = 1 AND MirrorID > 0). Uses PnLInDollars. Added 2024-11-10 (Daniel Kaplan). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 50 | ManualRealFuturesPositionPnL | decimal(16,2) | YES | Unrealized PnL from manually-opened futures positions (IsFuture = 1 AND MirrorID = 0). Uses PnLInDollars. Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 51 | NOP_FuturesReal | decimal(16,2) | YES | Net Open Position for futures instruments (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 52 | Notional_FuturesReal | decimal(16,2) | YES | Absolute USD exposure for futures instruments. Always positive (uses ABS for sell positions). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 53 | PositionPnLFuturesReal | decimal(16,2) | YES | Total unrealized PnL from all futures positions (IsFuture = 1). Uses PnLInDollars. Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 54 | FullCommissionByUnitsFuturesReal | decimal(38,6) | YES | Full prorated commission for futures positions (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 55 | CommissionByUnitsFuturesReal | decimal(38,6) | YES | Prorated commission for futures positions (IsFuture = 1). Added 2024-11-10. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 56 | NOP_StocksMargin | decimal(16,2) | YES | Net Open Position for stock margin positions (SettlementTypeID = 5). Added 2025-09-25 (Daniel Kaplan). (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |
| 57 | PositionPnLStocksMargin | decimal(16,2) | YES | Unrealized PnL from stock margin positions (SettlementTypeID = 5). Uses PnLInDollars. Added 2025-09-25. (Tier 2 — SP_Fact_CustomerUnrealized_PnL) |

---

## 5. Lineage

### 5.1 Staging Sources

| DWH Staging Table | Production Source | Role |
|-------------------|-------------------|------|
| etoro_Trade_OpenPositionEndOfDay | Trade.OpenPositionEndOfDay | Open positions for PnL calculation |
| etoro_History_ClosePositionEndOfDay | History.ClosePositionEndOfDay | Same-day closed positions |
| etoro_Trade_GetInstrument | Trade.GetInstrument | InstrumentTypeID for asset class classification |
| etoro_History_PositionChangeLog | History.PositionChangeLog | IsSettled changes (ChangeTypeID=13) |
| etoro_History_SplitRatio | History.SplitRatio | Stock split adjustment ratios for price and amount |
| etoro_History_BackOfficeCustomer | History.BackOfficeCustomer | Fund account identification (AccountTypeID=9) |
| etoro_History_Mirror | History.Mirror | Copy-fund relationship detection (MirrorOperationID=1) |
| PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | PriceLog | End-of-day bid/ask prices (spreaded and unspreaded) |

### 5.2 Internal DWH Dependencies

| Table/Object | Role |
|------|------|
| Dim_Instrument | IsFuture flag for futures detection |
| Dim_Instrument_Correlation | Instrument covariance matrix for risk calculation |
| Fact_SnapshotEquity + V_M2M_Date_DateRange | Equity values for portfolio weight calculation in risk |
| Fact_CustomerUnrealized_PnL_UserAPI | Receives subset of columns after main INSERT (API consumption) |

### 5.3 Upstream Wiki Availability

No upstream production table wikis exist for the primary sources (History.ActiveCredit, PriceLog.Candles, etc.). All columns are DWH-computed aggregations — Tier 2.

---

## 6. Relationships

### 6.1 Dimension Lookups

| Column | Dimension Table | Join Pattern |
|--------|----------------|-------------|
| CID | Dim_Customer | CID = RealCID |
| DateModified | Dim_Date | DateModified = DateKey |

### 6.2 Downstream Consumers

| Object | Usage |
|--------|-------|
| V_Fact_CustomerUnrealized_PnL_For_DWH_Rep | Replication view for DWH_rep database |
| Fact_CustomerUnrealized_PnL_UserAPI | Subset table for UserStatsAPI consumption |
| V_Liabilities | Uses PositionPnL to compute unrealized equity |
| SP_Client_Balance_New | Customer balance reporting |
| SP_Y_RBSF | Regulatory balance reporting |

### 6.3 Referenced By

*To be populated during cross-object enrichment (Phase 12).*

---

## 7. Sample Queries

```sql
-- Customer PnL breakdown for today
SELECT CID, PositionPnL, StocksPositionPnL, CryptoPositionPnL,
       CopyPositionPnL, MenualPositionPnL, StandardDeviation
FROM DWH_dbo.Fact_CustomerUnrealized_PnL
WHERE DateModified = CONVERT(INT, CONVERT(VARCHAR, GETDATE(), 112))
  AND CID = 12345;

-- Platform NOP exposure by asset class
SELECT DateModified,
       SUM(NOP) AS TotalNOP,
       SUM(NOP_Stock) AS StockNOP,
       SUM(NOP_Crypto) AS CryptoNOP,
       SUM(NOP_FuturesReal) AS FuturesNOP,
       SUM(Notional) AS TotalNotional
FROM DWH_dbo.Fact_CustomerUnrealized_PnL
WHERE DateModified = 20260318
GROUP BY DateModified;

-- V0 vs V1 PnL gap monitoring
SELECT DateModified,
       SUM(PositionPnL) AS V1_PnL,
       SUM(PositionPnL_old) AS V0_PnL,
       SUM(PositionPnL) - SUM(PositionPnL_old) AS Gap
FROM DWH_dbo.Fact_CustomerUnrealized_PnL
WHERE DateModified >= 20260301
GROUP BY DateModified
ORDER BY DateModified;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| DWH View Fact_CustomerUnrealized_PnL (Confluence/DROD) | Column-level insert examples with business explanations |
| PnL Milestone #2: From New Views to Staging Tables (Confluence/BDP) | V0 vs V1 PnL migration documentation; PositionPnL_old vs PositionPnL gap monitoring |
| Basic Concepts (Confluence/DROD) | Definitions: "Unrealized PnL = PnL of customer opened positions", "NOP = Net of positions — eToro holding of each instrument" |
| Summary of V-Liabilities (Confluence/BI) | "The difference between Realized Equity and Unrealized Equity is the Position PnL"; NOP calculations for Real and CFD |
| PNL_Alerts_Gap_Old_VS_New (Confluence/BDP) | Monitoring SP that compares PositionPnL vs PositionPnL_old for gap detection |

---
*Generated: 2026-03-19 | Quality: 9.0/10*
*Tiers: 0 T1, 57 T2, 0 T3, 0 T4, 0 T5 | Phases: 1,5,8,9,9B,10,10.5,13,11*
