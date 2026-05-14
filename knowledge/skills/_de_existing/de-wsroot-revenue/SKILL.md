---
id: revenue
name: "Revenue"
description: "All eToro revenue streams and their definitions: 15 fee types included in Total Net Revenue (FullCommission, Rollover, Ticket Fees, ConversionFee, DormantFee, Staking, ShareLending, Options PFOF, etc.) plus 3 excluded metrics (Commission, Dividends, SDRT). Three-layer architecture from atomic views to DDR reporting. Covers trade classification flags (IsCopy, IsSettled, IsICC, IsSQF)."
triggers:
  - revenue
  - total net revenue
  - commission
  - rollover
  - fee breakdown
  - staking revenue
  - share lending
  - PFOF
  - dormant fee
  - conversion fee
  - ticket fee
  - how much did we make
  - trading revenue
  - non-trading revenue
  - revenue by instrument
  - IncludedInTotalRevenue
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
  - main.etoro_kpi.vg_ddr_revenue
  - main.etoro_kpi_prep.mv_revenue_trading
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-07"
---

# Revenue

## When to Use
- "what's our total revenue?", "how much did we make this quarter?"
- "revenue breakdown by stream", "which fee type generates the most?"
- "revenue by asset class", "how much from crypto?"
- "daily revenue trend", "revenue over time"
- "trading vs non-trading revenue split"
- Any question about fee definitions, revenue composition, or IncludedInTotalRevenue logic

## Scope
In scope: All 19 revenue streams, Total Net Revenue calculation, revenue by instrument type, daily trends, trade classification flags, 3-layer architecture
Out of scope: Cost/expense data, P&L on customer positions (→ `portfolio-value` skill), deposit/withdrawal *flows* (→ `mimo` skill), trading *volumes* (→ `trading-volumes` skill)
Last verified: 2026-05-07

## Critical Warnings
1. SUM(Amount) without `IncludedInTotalRevenue = 1` includes Commission (double-counts FullCommission), Dividends (negative), and SDRT — produces silently wrong totals.
2. Metric IN ('FullCommission', 'Commission') double-counts — Commission is a subset of FullCommission (excludes partner share).
3. GROUP BY InstrumentTypeID without excluding -1 pollutes breakdown — account-level fees (ConversionFee, DormantFee) have InstrumentTypeID = -1.
4. StakingLagOneMonth is lagged 1 month — reported in the following month's DateID, not when earned.
5. CountTransactions is NULL for ShareLending and StakingLagOneMonth — no per-transaction grain for these streams.
6. Table has ~3.1B rows — always filter by DateID. The `vg_ddr_revenue` view adds enrichment but same performance rules apply.

---

## Architecture (3 Layers)

```
Layer 1: 19 Atomic Revenue Views (etoro_kpi_prep)
    └── Individual fee-type views (v_revenue_fullcommission, v_revenue_rollover, etc.)
          │
Layer 2: Materialized Trading Revenue (etoro_kpi_prep)
    └── mv_revenue_trading — unions 8 trading components + enriches with position/instrument dims
          │
Layer 3: DDR Revenue Reporting (etoro_kpi / bi_db)
    └── vg_ddr_revenue / bi_db_ddr_fact_revenue_generating_actions — all streams unified
```

**For most queries, use Layer 3** (the DDR fact table or view). Use Layer 2 (`mv_revenue_trading`) for instrument-level trading drilldowns with position flags.

---

## Tables

| Table | Use For |
|---|---|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | Primary fact table. All revenue streams. Filter by DateID. |
| `main.etoro_kpi.vg_ddr_revenue` | Same data as view with enrichment: `RevenueMetricCategory`, `InstrumentType` (name), `Date` (timestamp). Simpler column names. |
| `main.etoro_kpi_prep.mv_revenue_trading` | Trading revenue only (8 components) at instrument level. Has position-level flags (IsSettled, IsCopy, IsCopyFund, IsSQF, IBAN flags). |

---

## Core Concepts

### Total Net Revenue
```
SUM(Amount) WHERE IncludedInTotalRevenue = 1
```

### Revenue Streams

| Metric (exact value) | What It Is | In Total? |
|---|---|---|
| `FullCommission` | Spread markup on trades — includes partner/affiliate share. Primary driver. | Yes |
| `RollOverFee` | Overnight financing fee for holding CFD/FX positions past close. | Yes |
| `TicketFee` | Fixed ticket fee per trade. | Yes |
| `TicketFeeByPercent` | Percentage fee on trade's notional value. | Yes |
| `AdminFee` | Administrative fee (CompensationReasonID = 117). | Yes |
| `SpotPriceAdjustment` | Spot price adjustment fee (CompensationReasonID = 118). | Yes |
| `ConversionFee` | FX markup on deposit/withdrawal currency conversion vs USD. | Yes |
| `DormantFee` | Monthly inactivity fee (CompensationReasonID = 30). | Yes |
| `CashoutFeeExclRedeem` | Fee on fiat withdrawals (excludes crypto redeem). | Yes |
| `TransferCoinFee` | Crypto transfer fee (ActionTypeID=30, IsRedeem=1). | Yes |
| `ShareLending` | Revenue from lending real stocks to short-sellers. 40/40/20 split (eToro/user/broker). | Yes |
| `StakingLagOneMonth` | Crypto staking revenue. **Lagged 1 month.** | Yes |
| `InterestFee` | Historical margin interest (largely discontinued after Jul 2023). | Yes |
| `Options_PFOF` | Payment For Order Flow from options routing. | Yes |
| `CryptoToFiatFee` | Crypto-to-fiat conversion fee (C2F). | Yes |
| `Commission` | Spread markup EXCLUDING partner share. Subset of FullCommission. Informational. | **No** |
| `Dividends` | Paid TO customers on real stocks. Can be negative. | **No** |
| `SDRT` | UK Stamp Duty — tax collected, not fee earned. | **No** |

### Revenue Categories (from `vg_ddr_revenue`)
- **Trading Revenue**: FullCommission, RollOverFee, TicketFee, TicketFeeByPercent, AdminFee, SpotPriceAdjustment
- **Non-Trading Revenue**: ConversionFee, DormantFee, CashoutFeeExclRedeem, TransferCoinFee, ShareLending, StakingLagOneMonth, InterestFee, Options_PFOF, CryptoToFiatFee

### Trade Classification Flags

| Flag | Meaning | How Determined |
|---|---|---|
| `IsSettled` | 1 = real asset, 0 = CFD | SettlementTypeID or fallback: IsBuy=1 AND Leverage=1 AND TypeID IN (10,5,6) |
| `IsCopy` | 1 = copy-trade | MirrorID > 0 |
| `IsCopyFund` | 1 = Smart Portfolio | MirrorTypeID = 4 |
| `IsICC` | 1 = ICC instrument | IsFuture=1 OR InstrumentTypeID IN (1,2,4) |
| `IsSQF` | 1 = Special Qualifying Flag | Instrument in GroupID 59 |
| `IsMarginTrade` | 1 = margin trade | SettlementTypeID = 5 |

### Settlement Types
| SettlementTypeID | Meaning |
|---|---|
| 0 | CFD |
| 1 | Real asset |
| 2 | TRS |
| 3 | CMT (crypto settled) |
| 4 | Real Futures |
| 5 | Margin Trade |

### Reference Lookups

**ActionTypeID** (in source fact_customeraction):

| ActionTypeID | Meaning |
|---|---|
| 1, 2, 3, 39 | Position Opens |
| 4, 5, 6, 28, 40 | Position Closes |
| 30 | Cashout / Withdraw |
| 35 | Fee/Dividend (use IsFeeDividend to distinguish) |
| 36 | Compensation/Admin (use CompensationReasonID) |

**IsFeeDividend** (for ActionTypeID = 35):

| Value | Revenue Type |
|---|---|
| 1 | RolloverFee |
| 2 | Dividend |
| 4 | TicketFee (Fixed or ByPercent) |
| 5 | SDRT |

**CompensationReasonID** (for ActionTypeID = 36):

| Value | Revenue Type |
|---|---|
| 30 | DormantFee |
| 117 | AdminFee |
| 118 | SpotAdjustFee |
| 119 | ShareLending |

---

## Query Patterns

### Pattern 1 — Total Net Revenue
```sql
SELECT SUM(Amount) AS total_net_revenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE IncludedInTotalRevenue = 1 AND DateID BETWEEN 20260101 AND 20260331;
```
**Use when:** "what's our total revenue?", "how much did we make?", "total net revenue for Q1"

### Pattern 2 — Revenue by stream
```sql
SELECT Metric, SUM(Amount) AS revenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE IncludedInTotalRevenue = 1 AND DateID BETWEEN 20260101 AND 20260331
GROUP BY Metric ORDER BY revenue DESC;
```
**Use when:** "revenue breakdown", "which stream generates the most?", "revenue by type"

### Pattern 3 — Revenue by instrument type (use vg_ddr_revenue for names)
```sql
SELECT InstrumentType, SUM(Amount) AS revenue
FROM main.etoro_kpi.vg_ddr_revenue
WHERE IncludedInTotalRevenue = 1 AND InstrumentTypeID != -1
  AND DateID BETWEEN 20260101 AND 20260331
GROUP BY InstrumentType ORDER BY revenue DESC;
```
**Use when:** "revenue by asset class", "how much from crypto?", "stocks vs forex revenue"

### Pattern 4 — Trading vs Non-Trading split
```sql
SELECT RevenueMetricCategory, SUM(Amount) AS revenue
FROM main.etoro_kpi.vg_ddr_revenue
WHERE IncludedInTotalRevenue = 1 AND DateID BETWEEN 20260101 AND 20260331
GROUP BY RevenueMetricCategory;
```
**Use when:** "trading vs non-trading revenue", "revenue category split"

### Pattern 5 — Daily revenue time series
```sql
SELECT DateID, SUM(Amount) AS daily_revenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE IncludedInTotalRevenue = 1 AND DateID BETWEEN 20260301 AND 20260331
GROUP BY DateID ORDER BY DateID;
```
**Use when:** "daily revenue trend", "revenue over time", "revenue this month by day"
