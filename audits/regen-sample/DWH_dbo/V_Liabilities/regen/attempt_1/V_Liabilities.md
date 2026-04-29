# DWH_dbo.V_Liabilities

> Daily per-customer liabilities view (~6.8M CIDs/day, data from 2007 onward) joining Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL, and Fact_Guru_Copiers via the V_M2M_Date_DateRange bridge — computing actual net withdrawable amounts (ActualNWA), total liabilities, credit-capped liabilities (WA_Liabilities), and margin-used liabilities, alongside passthrough equity, PnL, NOP/notional exposure, and commission breakdowns across all asset classes (stocks, crypto, futures, stock margin, TRS).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Production Source** | Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL + Fact_Guru_Copiers (multi-source aggregate view) |
| **Key Identifier** | CID + DateID (one row per customer per calendar day) |
| **Base Tables** | Fact_SnapshotEquity (a), V_M2M_Date_DateRange (b), Fact_CustomerUnrealized_PnL (c), Fact_Guru_Copiers (gc) |
| **Column Count** | 75 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` |
| **UC Format** | delta |
| **Generic Pipeline** | ID 464, SynapseSourceWithoutSecret, daily Append |
| **Refresh** | Computed view — reflects underlying table freshness (all daily) |

---

## 1. Business Meaning

`V_Liabilities` is the platform's primary liabilities reporting view. It combines three daily fact tables through a date-range bridge to produce a single row per customer per calendar day, answering: "What does the platform owe each customer, and how is that liability split between withdrawable cash, credit, bonus, unrealized PnL, and in-used margin?"

The view serves as the foundation for:
- **Regulatory balance reporting**: SP_Y_RBSF, SP_Client_Balance_New, SP_ASIC_ClientBalanceFinance
- **Risk monitoring**: NOP and notional exposure by asset class (all, crypto, CFD, futures, stock margin, TRS)
- **Portfolio analytics**: Unrealized PnL breakdowns by ownership (manual vs copy vs guru) and asset class
- **CopyTrader metrics**: CopyFundAUM from Fact_Guru_Copiers

The view filters to `DateKey < TODAY` (via `GETDATE()` cast), so it always shows completed days only — never intraday.

The four computed liability columns implement the core liability formula from the Confluence "Summary of V-Liabilities" page:
- **Equity** = TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL (all ISNULL to 0)
- **ActualNWA** = MIN(Equity, BonusCredit) clamped at 0 on the low end
- **Liabilities** = InProcessCashouts + MAX(Equity - BonusCredit, MIN(Equity, 0))
- **WA_Liabilities** = MIN(Liabilities_base, Credit)
- **Liabilities_InUsedMargin** = MAX(Liabilities_base - Credit, 0)

---

## 2. Business Logic

### 2.1 Liability Computation

**What**: Four CASE expressions compute the platform's financial obligation to each customer.
**Columns Involved**: TotalPositionsAmount, TotalCash, TotalStockOrders, PositionPnL, BonusCredit, InProcessCashouts, Credit
**Rules**:
- `Equity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0)`
- `ActualNWA`: IF Equity > BonusCredit → BonusCredit; IF Equity < 0 → 0; ELSE → Equity
- `Liabilities_base`: IF Equity - BonusCredit > 0 → Equity - BonusCredit; IF Equity < 0 → Equity; ELSE → 0
- `Liabilities` = ISNULL(InProcessCashouts,0) + Liabilities_base
- `WA_Liabilities`: IF Liabilities_base > Credit → Credit; ELSE → Liabilities_base
- `Liabilities_InUsedMargin`: IF Liabilities_base > Credit → Liabilities_base - Credit; ELSE → 0

### 2.2 Manual Position Derivation

**What**: Computes manual (non-copy) position amounts and PnL by subtracting mirror components.
**Columns Involved**: TotalStockPositionAmount, TotalStockOrders, TotalMirrorStockPositionAmount, StocksPositionPnL, MirrorStocksPositionPnL, TotalCryptoPositionAmount, TotalMirrorCryptoPositionAmount
**Rules**:
- `TotalStockManualPosition` = TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount
- `ManualStockPositionPnL` = StocksPositionPnL - MirrorStocksPositionPnL
- `TotalCryptoManualPosition` = TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount
- `TotalCryptoManualPosition_TRS` = TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS

### 2.3 Asset-Class Liabilities Aggregation

**What**: Computes total liabilities (position amount + PnL) for real stocks, real crypto, crypto TRS, and real futures.
**Columns Involved**: PositionPnLStocksReal, TotalRealStocks, PositionPnLCryptoReal, TotalRealCrypto, CryptoPositionPnL_TRS, Total_TRSCrypto, PositionPnLFuturesReal, TotalRealFutures
**Rules**:
- `LiabilitiesStockReal` = ISNULL(PositionPnLStocksReal,0) + ISNULL(TotalRealStocks,0)
- `LiabilitiesCryptoReal` = ISNULL(PositionPnLCryptoReal,0) + ISNULL(TotalRealCrypto,0)
- `LiabilitiesCrypto_TRS` = ISNULL(CryptoPositionPnL_TRS,0) + ISNULL(Total_TRSCrypto,0)
- `LiabilitiesFuturesReal` = ISNULL(PositionPnLFuturesReal,0) + ISNULL(TotalRealFutures,0)

### 2.4 JOIN Structure

**What**: Four-way JOIN with date range expansion and temporal alignment.
**Rules**:
- INNER JOIN `V_M2M_Date_DateRange b` on `a.DateRangeID = b.DateRangeID` — expands SCD-2 date ranges to individual dates
- LEFT JOIN `Fact_CustomerUnrealized_PnL c` on `a.CID = c.CID AND b.DateKey = c.DateModified` — PnL may not exist for every CID/day
- LEFT JOIN `Fact_Guru_Copiers gc` on `a.CID = gc.CID AND b.DateKey = gc.DateID` — CopyTrader data exists only for copiers (~1.4% of CIDs)
- WHERE `b.DateKey < CAST(CONVERT(VARCHAR(MAX),GETDATE(),112) AS INT)` — excludes today (incomplete day)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **No physical storage** — computed view reading from HASH(CID) tables (Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL, Fact_Guru_Copiers) and REPLICATE tables (Dim_Range, Dim_Date via V_M2M_Date_DateRange)
- CID-based queries are co-located (all base tables HASH on CID)
- Date-range queries across customers require data movement between distributions

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer liability on a specific date | `WHERE CID = @cid AND DateID = @date` — single-node |
| Platform total liabilities | `SELECT DateID, SUM(Liabilities) ... WHERE DateID = @date GROUP BY DateID` — full scan |
| NOP exposure monitoring | `SELECT DateID, SUM(NOP), SUM(Notional) WHERE DateID = @date` |
| Real stock/crypto liabilities | `SELECT SUM(LiabilitiesStockReal), SUM(LiabilitiesCryptoReal) WHERE DateID = @date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| Dim_Customer | CID = RealCID | Customer attributes (country, regulation, status) |
| Dim_Date | DateID = DateKey | Calendar attributes for the snapshot date |

### 3.4 Gotchas

- **Massive view**: ~6.8M rows per day. Never `SELECT *` without DateID filter.
- **LEFT JOINs produce NULLs**: PositionPnL and all `c.*` columns are NULL when Fact_CustomerUnrealized_PnL has no row for that CID/day. CopyFundAUM is NULL for non-copiers (~98.6% of CIDs).
- **TotalStockOrders is legacy zero**: Hardcoded to 0 since 2019 in Fact_SnapshotEquity but still included in all liability formulas for schema compatibility.
- **Fact_Guru_Copiers is LEFT JOINed but only CopyFundAUM is selected** — the gc alias contributes exactly one column.
- **Today excluded**: The WHERE clause filters `DateKey < TODAY`, so the current day's data is never visible.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Passthrough from upstream wiki — description copied verbatim |
| Tier 2 | View-computed or ETL-derived with documented transform |
| Tier 3 | No upstream wiki, description from DDL/context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID. Grouping key for all equity aggregations. FK to Dim_Customer (CID = RealCID). HASH distribution key and part of PK. (Tier 1 — Fact_SnapshotEquity) |
| 2 | DateID | int | NO | Individual calendar date key in YYYYMMDD integer format. Falls within the range defined by Dim_Range.FromDateID and Dim_Range.ToDateID (inclusive). Renamed from DateKey. (Tier 1 — V_M2M_Date_DateRange) |
| 3 | FullDate | date | YES | Calendar date corresponding to DateKey in native DATE format. Provides the human-readable date for the YYYYMMDD integer key. (Tier 1 — V_M2M_Date_DateRange) |
| 4 | RealizedEquity | money | NO | Total account value. If History.ActiveCredit.RealizedEquity is non-zero, taken directly; otherwise computed as TotalCash + TotalPositionsAmount + InProcessCashouts. Confluence definition: "Unrealized Equity — the total funds in the account, including profit/loss from open positions. The Portfolio value figure represented on the platform is Unrealized equity." (Tier 1 — Fact_SnapshotEquity) |
| 5 | TotalPositionsAmount | money | NO | Sum of all open position amounts (NewAmount) for this CID on this date. Includes all asset classes: CFD, stocks, crypto, futures, margin. Source: open positions (Trade.OpenPositionEndOfDay) + same-day closed positions (History.ClosePositionEndOfDay) minus History.Credit CreditTypeID=13 adjustments. (Tier 1 — Fact_SnapshotEquity) |
| 6 | TotalCash | money | NO | Customer's total cash balance for the day. Computed as: previous day's TotalCash (from last row in current year) + sum of TotalCashChange from History.ActiveCredit for @dt. This running-balance approach was introduced 2020-06-07 replacing the direct History.Credit.TotalCash read. (Tier 1 — Fact_SnapshotEquity) |
| 7 | InProcessCashouts | money | NO | Sum of pending withdrawal amounts for this CID that have not yet been finalized (statuses other than 3=Processed, 4=Cancelled, 5,6). Includes partially processed amounts for split-payment withdrawals plus associated fees. Computed by SP_Fact_SnapshotEquity_InProcessCashouts from Billing.Withdraw, History.WithdrawAction, and History.WithdrawToFundingAction. (Tier 1 — Fact_SnapshotEquity) |
| 8 | TotalMirrorPositionsAmount | money | NO | Sum of position amounts where MirrorID > 0 AND ParentPositionID != 0 (copy-trading positions only, excluding the parent/guru's own positions). Represents the CID's total investment in copy relationships. (Tier 1 — Fact_SnapshotEquity) |
| 9 | TotalMirrorCash | money | NO | Cash available for copy-trading. Formula: TotalCash - Credit. (Tier 1 — Fact_SnapshotEquity) |
| 10 | TotalStockOrders | money | NO | Legacy column, hardcoded to 0. Removed 2019-03-03 (Boris Slutski) — no data in PROD since 2015. Kept for schema compatibility. (Tier 1 — Fact_SnapshotEquity) |
| 11 | TotalMirrorStockOrders | money | NO | Legacy column, hardcoded to 0. Removed 2019-03-03 alongside TotalStockOrders. Kept for schema compatibility. (Tier 1 — Fact_SnapshotEquity) |
| 12 | Credit | money | NO | Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day (selected via ROW_NUMBER partition by CID, ordered by Occurred DESC, CreditID DESC). Negative values represent outstanding obligations. (Tier 1 — Fact_SnapshotEquity) |
| 13 | AUM | money | NO | Assets Under Management. Formula: TotalMirrorPositionAmount + TotalCash - Credit. For MERGE INSERT: computed as TotalMirrorPositionsAmount + TotalMirrorCash. Confluence: "AUC (or AUM) on PI Dashboard: Total Unrealized Copy Amount of the Copiers." (Tier 1 — Fact_SnapshotEquity) |
| 14 | BonusCredit | money | YES | Bonus credit balance from History.ActiveCredit.BonusCredit. Confluence: "History.Credit.CreditTypeID = 5, 7 → BackOffice.BonusType.BonusTypeID → History.Credit.BonusTypeID". ISNULL to 0 in ETL. (Tier 1 — Fact_SnapshotEquity) |
| 15 | TotalStockPositionAmount | money | YES | Sum of position amounts where InstrumentTypeID IN (5,6) AND instrument is NOT a future. Represents CFD and real stock positions (excluding futures that also have InstrumentTypeID 5/6). (Tier 1 — Fact_SnapshotEquity) |
| 16 | TotalMirrorStockPositionAmount | money | YES | Mirror (copy-trading) subset of TotalStockPositionAmount. Adds MirrorID > 0 AND ParentPositionID != 0. Same mutual exclusivity fix with futures. (Tier 1 — Fact_SnapshotEquity) |
| 17 | PositionPnL | decimal(16,2) | YES | Total unrealized PnL in USD across all open positions for this CID on this date. Uses V1 formula (PnLInDollars from staging). This is the primary PnL metric. "The difference between Realized Equity and Unrealized Equity is the Position PnL" (Confluence). NULL when no Fact_CustomerUnrealized_PnL row exists for the CID/day. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 18 | CopyPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading positions only (MirrorID > 0). Includes all asset classes. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 19 | StandardDeviation | float | YES | Portfolio risk measure: standard deviation of the customer's weighted portfolio computed from instrument covariance matrix. Only calculated for dates >= 2012-12-31. Formula: √(Σ weight_a × weight_b × covariance). NULL for pre-2013 data or when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 20 | CommissionOnOpen | decimal(16,2) | YES | Sum of opening commissions (Commission) across all open positions for this CID. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 21 | ActualNWA | money | YES | Actual Net Withdrawable Amount. Capped at BonusCredit when equity exceeds BonusCredit; 0 when equity is negative; otherwise equals equity. Equity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0). ~0.06% of CIDs have nonzero values (4,145 of 6.8M). (Tier 2 — View-computed) |
| 22 | Liabilities | money | YES | Total platform liability to the customer: ISNULL(InProcessCashouts,0) + Liabilities_base, where Liabilities_base = MAX(Equity - BonusCredit, MIN(Equity, 0)). This is the headline liability metric. 64.5% of CIDs have nonzero values. (Tier 2 — View-computed) |
| 23 | WA_Liabilities | money | YES | Credit-capped liabilities: MIN(Liabilities_base, Credit). Represents the portion of liabilities covered by the customer's credit line. 54.3% of CIDs have nonzero values. (Tier 2 — View-computed) |
| 24 | Liabilities_InUsedMargin | money | YES | Excess liabilities beyond credit: MAX(Liabilities_base - Credit, 0). Represents the portion of liabilities that exceeds the customer's credit and consumes used margin. 39.5% of CIDs have nonzero values. (Tier 2 — View-computed) |
| 25 | StocksPositionPnL | decimal(16,2) | YES | Unrealized PnL from stock positions (InstrumentTypeID IN (5,6) AND NOT futures). Includes both real and CFD stocks, both manual and copy. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 26 | TotalStockManualPosition | money | YES | Manual (non-copy) stock position amount: TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount. TotalStockOrders is legacy 0. (Tier 2 — View-computed) |
| 27 | ManualStockPositionPnL | decimal(16,2) | YES | Manual stock PnL: StocksPositionPnL - MirrorStocksPositionPnL. NULL when no PnL row exists. (Tier 2 — View-computed) |
| 28 | MirrorStocksPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading stock positions (InstrumentTypeID IN (5,6) AND NOT futures AND MirrorID > 0). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 29 | CryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from all crypto positions (InstrumentTypeID = 10 AND NOT futures). Includes real, CFD, manual, and copy. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 30 | ManualCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from manually-opened crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID = 0). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 31 | CopyCryptoPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading crypto positions (InstrumentTypeID = 10 AND NOT futures AND MirrorID > 0). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 32 | TotalCryptoPositionAmount | money | YES | Sum of position amounts where InstrumentTypeID = 10 AND instrument is NOT a future. Represents CFD and real crypto positions. (Tier 1 — Fact_SnapshotEquity) |
| 33 | TotalCryptoManualPosition | money | YES | Manual (non-copy) crypto position amount: TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount. (Tier 2 — View-computed) |
| 34 | CopyFundAUM | money | YES | Total Assets Under Copy: Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL. Computed in SP_Fact_Guru_Copiers, not stored at source. This is the headline metric for copy-trading portfolio value. NULL for non-copiers (~98.6% of CIDs). (Tier 1 — Fact_Guru_Copiers) |
| 35 | CopyFundPnL | decimal(16,2) | YES | Unrealized PnL from positions opened via copy-fund relationships (parent CID had AccountTypeID=9 at the time the copy was opened). Identified via History.BackOfficeCustomer + History.Mirror join. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 36 | NOP | decimal(16,2) | YES | Net Open Position — total signed directional USD exposure across all instruments. Positive = net long, negative = net short. "eToro holding of each instrument" (Confluence). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 37 | Notional | decimal(16,2) | YES | Total absolute USD exposure across all instruments. ABS(NOP) per instrument, then summed. Always >= 0. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 38 | NOP_Crypto | decimal(16,2) | YES | Net Open Position for crypto instruments only (InstrumentTypeID = 10 AND NOT futures). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 39 | Notional_Crypto | decimal(16,2) | YES | Absolute USD exposure for crypto instruments only. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 40 | NOP_CFD | decimal(16,2) | YES | Net Open Position for all CFD positions (IsSettled = 0), all asset classes. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 41 | Notional_CFD | decimal(16,2) | YES | Absolute USD exposure for all CFD positions. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 42 | NOP_Crypto_CFD | decimal(16,2) | YES | Net Open Position for crypto CFD positions (InstrumentTypeID = 10 AND IsSettled = 0). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 43 | Notional_Crypto_CFD | decimal(16,2) | YES | Absolute USD exposure for crypto CFD positions. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 44 | PositionPnLStocksReal | decimal(16,2) | YES | Unrealized PnL from real (settled) stock positions only (IsSettled = 1 AND InstrumentTypeID IN (5,6) AND NOT futures). Uses PnLInDollars. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 45 | PositionPnLCryptoReal | decimal(16,2) | YES | Unrealized PnL from real (settled) crypto positions only (IsSettled = 1 AND InstrumentTypeID = 10 AND NOT futures). Uses PnLInDollars. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 46 | TotalRealStocks | decimal(16,2) | YES | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID IN (5,6) AND instrument is NOT a future. "Real" means the customer owns the underlying asset (settled/delivered). Updated via IsSettled change tracking from History.PositionChangeLog. (Tier 1 — Fact_SnapshotEquity) |
| 47 | TotalRealCrypto | decimal(16,2) | YES | Sum of position amounts where IsSettled = 1 AND InstrumentTypeID = 10 AND instrument is NOT a future. Real crypto ownership (settled positions). Updated via IsSettled change tracking. (Tier 1 — Fact_SnapshotEquity) |
| 48 | LiabilitiesStockReal | decimal(16,2) | YES | Total real stock liabilities: ISNULL(PositionPnLStocksReal,0) + ISNULL(TotalRealStocks,0). Combines settled stock PnL with settled stock position amounts. (Tier 2 — View-computed) |
| 49 | LiabilitiesCryptoReal | decimal(16,2) | YES | Total real crypto liabilities: ISNULL(PositionPnLCryptoReal,0) + ISNULL(TotalRealCrypto,0). Combines settled crypto PnL with settled crypto position amounts. (Tier 2 — View-computed) |
| 50 | CommissionByUnitsCrypto_TRS | decimal(38,6) | YES | Prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 51 | CopyCryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from copy-trading crypto TRS positions (InstrumentTypeID = 10 AND MirrorID > 0 AND SettlementTypeID = 2). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 52 | CryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from all crypto TRS positions (InstrumentTypeID = 10 AND SettlementTypeID = 2). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 53 | FullCommissionByUnitsCrypto_TRS | decimal(38,6) | YES | Full prorated commission for crypto TRS positions (IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 54 | ManualCryptoPositionPnL_TRS | decimal(16,2) | YES | Unrealized PnL from manually-opened crypto TRS positions (InstrumentTypeID = 10 AND MirrorID = 0 AND SettlementTypeID = 2). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 55 | NOP_Crypto_TRS | decimal(16,2) | YES | Net Open Position for crypto TRS positions (InstrumentTypeID = 10 AND IsSettled = 0 AND SettlementTypeID = 2). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 56 | Notional_Crypto_TRS | decimal(16,2) | YES | Absolute USD exposure for crypto TRS positions. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 57 | Total_TRSCrypto | decimal(16,2) | YES | Sum of crypto position amounts where IsSettled = 0 AND InstrumentTypeID = 10 AND SettlementTypeID = 2. CFD-style crypto positions under TRS settlement (not yet settled to real ownership). (Tier 1 — Fact_SnapshotEquity) |
| 58 | TotalCryptoPositionAmount_TRS | decimal(16,2) | YES | Sum of crypto position amounts where SettlementTypeID = 2 (TRS — Total Return Swap) AND instrument is NOT a future. TRS positions have different regulatory treatment than settled positions. (Tier 1 — Fact_SnapshotEquity) |
| 59 | TotalCryptoManualPosition_TRS | decimal(16,2) | YES | Manual (non-copy) crypto TRS position amount: TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS. (Tier 2 — View-computed) |
| 60 | LiabilitiesCrypto_TRS | decimal(16,2) | YES | Total crypto TRS liabilities: ISNULL(CryptoPositionPnL_TRS,0) + ISNULL(Total_TRSCrypto,0). Combines TRS crypto PnL with TRS crypto position amounts. (Tier 2 — View-computed) |
| 61 | MirrorRealFuturesPositionPnL | decimal(16,2) | YES | Unrealized PnL from copy-trading futures positions (IsFuture = 1 AND MirrorID > 0). Uses PnLInDollars. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 62 | ManualRealFuturesPositionPnL | decimal(16,2) | YES | Unrealized PnL from manually-opened futures positions (IsFuture = 1 AND MirrorID = 0). Uses PnLInDollars. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 63 | NOP_FuturesReal | decimal(16,2) | YES | Net Open Position for futures instruments (IsFuture = 1). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 64 | Notional_FuturesReal | decimal(16,2) | YES | Absolute USD exposure for futures instruments. Always positive (uses ABS for sell positions). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 65 | PositionPnLFuturesReal | decimal(16,2) | YES | Total unrealized PnL from all futures positions (IsFuture = 1). Uses PnLInDollars. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 66 | FullCommissionByUnitsFuturesReal | decimal(38,6) | YES | Full prorated commission for futures positions (IsFuture = 1). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 67 | CommissionByUnitsFuturesReal | decimal(38,6) | YES | Prorated commission for futures positions (IsFuture = 1). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 68 | TotalMirrorRealFuturesPositionAmount | decimal(16,2) | YES | Sum of futures position amounts where MirrorID > 0. From Dim_Instrument_Snapshot.IsFuture = 1. (Tier 1 — Fact_SnapshotEquity) |
| 69 | TotalRealFutures | decimal(16,2) | YES | Sum of all futures position amounts. Identified via JOIN to Dim_Instrument_Snapshot where IsFuture = 1 for the snapshot DateID. (Tier 1 — Fact_SnapshotEquity) |
| 70 | TotalFuturesProviderMargin | decimal(16,2) | YES | Sum of provider margin for futures positions: LotCountDecimal × Dim_Instrument_Snapshot.ProviderMarginPerLot. Represents the margin required by the futures provider. (Tier 1 — Fact_SnapshotEquity) |
| 71 | LiabilitiesFuturesReal | decimal(16,2) | YES | Total futures liabilities: ISNULL(PositionPnLFuturesReal,0) + ISNULL(TotalRealFutures,0). Combines futures PnL with futures position amounts. (Tier 2 — View-computed) |
| 72 | NOP_StocksMargin | decimal(16,2) | YES | Net Open Position for stock margin positions (SettlementTypeID = 5). NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 73 | PositionPnLStocksMargin | decimal(16,2) | YES | Unrealized PnL from stock margin positions (SettlementTypeID = 5). Uses PnLInDollars. NULL when no PnL row exists. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 74 | TotalStocksMargin | decimal(16,2) | YES | Sum of stock margin position amounts where SettlementTypeID = 5. Represents margin-traded stock positions (not fully settled). (Tier 1 — Fact_SnapshotEquity) |
| 75 | TotalStockMarginLoanValue | decimal(16,2) | YES | Loan value for leveraged stock margin positions: InitForexRate × AmountInUnitsDecimal × InitConversionRate - NewAmount. Only computed when SettlementTypeID = 5 AND Leverage <> 1. (Tier 1 — Fact_SnapshotEquity) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Source Table | Source Columns | Transform |
|---------------------|-------------|---------------|-----------|
| CID, RealizedEquity, TotalPositionsAmount, TotalCash, InProcessCashouts, TotalMirrorPositionsAmount, TotalMirrorCash, TotalStockOrders, TotalMirrorStockOrders, Credit, AUM, BonusCredit, TotalStockPositionAmount, TotalMirrorStockPositionAmount, TotalCryptoPositionAmount, TotalRealStocks, TotalRealCrypto, Total_TRSCrypto, TotalCryptoPositionAmount_TRS, TotalMirrorRealFuturesPositionAmount, TotalRealFutures, TotalFuturesProviderMargin, TotalStocksMargin, TotalStockMarginLoanValue | Fact_SnapshotEquity (a) | Same names | Passthrough |
| DateID, FullDate | V_M2M_Date_DateRange (b) | DateKey, FullDate | DateKey renamed to DateID |
| PositionPnL, CopyPositionPnL, StandardDeviation, CommissionOnOpen, StocksPositionPnL, MirrorStocksPositionPnL, CryptoPositionPnL, ManualCryptoPositionPnL, CopyCryptoPositionPnL, CopyFundPnL, NOP, Notional, NOP_Crypto, Notional_Crypto, NOP_CFD, Notional_CFD, NOP_Crypto_CFD, Notional_Crypto_CFD, PositionPnLStocksReal, PositionPnLCryptoReal, CommissionByUnitsCrypto_TRS, CopyCryptoPositionPnL_TRS, CryptoPositionPnL_TRS, FullCommissionByUnitsCrypto_TRS, ManualCryptoPositionPnL_TRS, NOP_Crypto_TRS, Notional_Crypto_TRS, MirrorRealFuturesPositionPnL, ManualRealFuturesPositionPnL, NOP_FuturesReal, Notional_FuturesReal, PositionPnLFuturesReal, FullCommissionByUnitsFuturesReal, CommissionByUnitsFuturesReal, NOP_StocksMargin, PositionPnLStocksMargin | Fact_CustomerUnrealized_PnL (c) | Same names | Passthrough (LEFT JOIN) |
| CopyFundAUM | Fact_Guru_Copiers (gc) | CopyFundAUM | Passthrough (LEFT JOIN) |
| ActualNWA, Liabilities, WA_Liabilities, Liabilities_InUsedMargin, TotalStockManualPosition, ManualStockPositionPnL, TotalCryptoManualPosition, TotalCryptoManualPosition_TRS, LiabilitiesStockReal, LiabilitiesCryptoReal, LiabilitiesCrypto_TRS, LiabilitiesFuturesReal | — | Multiple source columns | View CASE/arithmetic |

### 5.2 ETL Pipeline

```
History.ActiveCredit + Trade.OpenPositionEndOfDay + Billing.Withdraw + ...
  |-- SP_Fact_SnapshotEquity_DL_To_Synapse (daily) ---|
  v
DWH_dbo.Fact_SnapshotEquity (~6.8M CIDs)
  |
  |  Trade.OpenPositionEndOfDay + History.ClosePositionEndOfDay + PriceLog
  |    |-- SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse (daily) ---|
  |    v
  |  DWH_dbo.Fact_CustomerUnrealized_PnL (~2.7M CIDs/day)
  |
  |  History.GuruCopiers
  |    |-- SP_Fact_Guru_Copiers_DL_To_Synapse (daily) ---|
  |    v
  |  DWH_dbo.Fact_Guru_Copiers (~94K CIDs/day)
  |
  |  Dim_Range + Dim_Date
  |    v
  |  DWH_dbo.V_M2M_Date_DateRange (date range bridge)
  |
  |-- VIEW: V_Liabilities (4-way JOIN + 12 computed columns) ---|
  v
DWH_dbo.V_Liabilities (~6.8M rows/day)
  |-- Generic Pipeline ID 464 (Gold, daily Append, delta) ---|
  v
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities (UC)
```

---

## 6. Relationships

### 6.1 References To (this view points to)

| Element | Related Object | Description |
|---------|----------------|-------------|
| a.* | DWH_dbo.Fact_SnapshotEquity | INNER JOIN on DateRangeID via V_M2M_Date_DateRange — equity snapshot |
| b.* | DWH_dbo.V_M2M_Date_DateRange | INNER JOIN on DateRangeID — date range expansion |
| c.* | DWH_dbo.Fact_CustomerUnrealized_PnL | LEFT JOIN on CID + DateKey = DateModified — unrealized PnL |
| gc.CopyFundAUM | DWH_dbo.Fact_Guru_Copiers | LEFT JOIN on CID + DateKey = DateID — CopyTrader AUM |
| CID | DWH_dbo.Dim_Customer | FK (CID = RealCID) — customer dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Schema | Usage |
|--------|--------|-------|
| SP_Client_Balance_New | BI_DB_dbo | Customer balance reporting |
| SP_Y_RBSF | BI_DB_dbo | Regulatory balance reporting (RBSF) |
| SP_ASIC_ClientBalanceFinance | BI_DB_dbo | ASIC regulatory client balance calculations |
| SP_CashRiskMatrix | BI_DB_dbo | Cash risk analysis |

---

## 7. Sample Queries

### 7.1 Customer Liabilities on a Specific Date

```sql
SELECT CID, Liabilities, WA_Liabilities, Liabilities_InUsedMargin,
       ActualNWA, RealizedEquity, TotalCash, PositionPnL
FROM DWH_dbo.V_Liabilities
WHERE CID = 12345
  AND DateID = 20260426;
```

### 7.2 Platform Total Liabilities Trend

```sql
SELECT DateID,
       SUM(Liabilities) AS TotalLiabilities,
       SUM(WA_Liabilities) AS TotalWA_Liabilities,
       SUM(Liabilities_InUsedMargin) AS TotalMarginLiabilities,
       COUNT(DISTINCT CID) AS ActiveCIDs
FROM DWH_dbo.V_Liabilities
WHERE DateID >= 20260401
GROUP BY DateID
ORDER BY DateID;
```

### 7.3 NOP Exposure by Asset Class

```sql
SELECT DateID,
       SUM(NOP) AS TotalNOP,
       SUM(NOP_Crypto) AS CryptoNOP,
       SUM(NOP_CFD) AS CFD_NOP,
       SUM(NOP_FuturesReal) AS FuturesNOP,
       SUM(NOP_StocksMargin) AS StockMarginNOP,
       SUM(Notional) AS TotalNotional
FROM DWH_dbo.V_Liabilities
WHERE DateID = 20260426
GROUP BY DateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Summary of V-Liabilities (Confluence/BI) | Core liability formula: "The difference between Realized Equity and Unrealized Equity is the Position PnL"; NOP calculations for Real and CFD |
| DWH View Fact_SnapshotEquity (Confluence/DROD) | Equity column definitions: TotalCash, RealizedEquity, AUM, InProcessCashouts |
| AUM Life Cycle (Confluence/DROD) | AUM = Cash + Investment; CopyFundAUM calculation |
| Basic Concepts (Confluence/DROD) | "Unrealized PnL = PnL of customer opened positions", "NOP = Net of positions — eToro holding of each instrument" |

---
*Generated: 2026-04-27 | Quality: 9.0/10*
*Tiers: 51 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Phases: 1,2,3,5,6,7,9B,10A,10B,11*
*Object: DWH_dbo.V_Liabilities | Type: View | Base Tables: Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL, V_M2M_Date_DateRange, Fact_Guru_Copiers*
