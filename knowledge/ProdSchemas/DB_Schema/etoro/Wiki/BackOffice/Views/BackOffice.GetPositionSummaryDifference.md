# BackOffice.GetPositionSummaryDifference

> Risk reconciliation view that performs a full outer join between the open customer position summary and hedge position summary, surfacing lot and P&L discrepancies for every instrument/direction combination.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (Provider, Instrument, BUY/SELL) - composite from UNION ALL |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetPositionSummaryDifference` is the primary risk reconciliation view for eToro's trading desk. It compares two summaries side by side:
- `BackOffice.GetOpenPositionSummary` - aggregated open customer positions (what customers hold)
- `BackOffice.GetHedgePositionSummary` - aggregated hedge positions (what eToro has hedged with liquidity providers)

The view performs a full outer join (via UNION ALL of three SELECT blocks) on (Provider, Instrument, BUY/SELL) and computes the difference in lots and P&L between the two sides. Any non-zero `Lot Difference` or `P&L Difference` indicates a hedge gap - either under-hedged (more customer exposure than hedge coverage) or over-hedged (more hedge than customer exposure).

This view answers the risk team's core question: "Are our hedge positions properly sized relative to our customer book?" The three UNION ALL parts handle: (1) matched pairs, (2) customer positions with no hedge, and (3) hedge positions with no matching customer position.

---

## 2. Business Logic

### 2.1 Full Outer Join via UNION ALL (Three-Part Structure)

**What**: Implements a FULL OUTER JOIN between the open position summary and hedge position summary to identify all three reconciliation states.

**Columns/Parameters Involved**: `Lot Difference`, `P&L Difference`, `Open Total Lot`, `Hedge Total Lot`

**Rules**:
- **Part 1 (INNER JOIN)**: Matched (Provider, Instrument, BUY/SELL) in both summaries. Shows both sides and their differences.
- **Part 2 (LEFT ONLY)**: Open customer positions with NO matching hedge position. Hedge columns = 0, `Lot Difference` = Open Total Lot (fully unhedged exposure). Risk alert: customer exposure with no hedge.
- **Part 3 (RIGHT ONLY)**: Hedge positions with NO matching open customer position. Open columns = 0, `Lot Difference` = -Hedge Total Lot (excess hedge). May indicate hedge needs to be unwound.

**Diagram**:
```
GetOpenPositionSummary    GetHedgePositionSummary
  (customer side)           (hedge side)
        |                        |
        +---- INNER JOIN --------+  --> Lot Difference = Open Lots - Hedge Lots
        |                                P&L Difference = Open P&L - Hedge P&L
        |
        +---- LEFT ONLY (no hedge) -->  Lot Difference = Open Lots (fully unhedged)
        |
        +---- RIGHT ONLY (no open) -->  Lot Difference = -Hedge Lots (over-hedged)

Risk interpretation:
  Lot Difference > 0  = Under-hedged (customer exposure exceeds hedge)
  Lot Difference < 0  = Over-hedged (hedge exceeds customer exposure)
  Lot Difference = 0  = Perfectly hedged
```

### 2.2 Discrepancy Metrics

**What**: Two computed columns measure the hedge gap in both lot and dollar terms.

**Columns/Parameters Involved**: `Lot Difference`, `P&L Difference`

**Rules**:
- `Lot Difference = Open Total Lot - Hedge Total Lot`
- `P&L Difference = Open P&L - Hedge P&L`
- For Part 2 (unhedged): Lot Difference = Open Total Lot (Hedge = 0)
- For Part 3 (over-hedged): Lot Difference = -Hedge Total Lot (Open = 0), sign is negative
- Monitoring threshold: any row where `ABS(Lot Difference) > tolerance_threshold` requires review

---

## 3. Data Overview

*Live data not available - view inherits timeout risk from GetOpenPositionSummary (crosses multiple large Trade tables).*

| Provider | Instrument | BUY/SELL | Open Avg Price | Hedge Avg Price | Open Total Lot | Hedge Total Lot | Lot Difference | Open P&L | Hedge P&L | P&L Difference |
|----------|------------|----------|----------------|-----------------|----------------|-----------------|----------------|----------|-----------|----------------|
| eToro | EUR/USD | BUY | 1.0920 | 1.0918 | 50.0 | 49.5 | 0.5 | 5000 | 4900 | 100 |
| eToro | BTC/USD | SELL | 42000 | 0 | 2.0 | 0 | 2.0 | 800 | 0 | 800 |

*Row 1: 0.5 lot under-hedged on EUR/USD BUY. Row 2: Unhedged SELL position on BTC/USD (no matching hedge entry).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Provider | NVARCHAR | YES | - | CODE-BACKED | Trading provider/liquidity provider name. From GetOpenPositionSummary or GetHedgePositionSummary. Trimmed name from Trade.Provider. |
| 2 | Instrument | NVARCHAR | YES | - | CODE-BACKED | Financial instrument name (e.g., "EUR/USD", "BTC/USD"). From Trade.GetInstrument via the base views. |
| 3 | BUY/SELL | VARCHAR(4) | NO | - | CODE-BACKED | Trade direction: 'BUY' (long) or 'SELL' (short). Determines which market price (Bid vs Ask) is used for current price. |
| 4 | Current Price | DECIMAL | YES | - | CODE-BACKED | Live market close-out price. From GetOpenPositionSummary (or GetHedgePositionSummary for right-only rows). BUY uses Bid, SELL uses Ask. |
| 5 | Open Avg Price | DECIMAL | YES | - | VERIFIED | Lot-weighted average entry price across all open customer positions for this (Provider, Instrument, Direction). From GetOpenPositionSummary.Avg Price. 0 for hedge-only rows (Part 3). |
| 6 | Hedge Avg Price | DECIMAL | YES | - | VERIFIED | Lot-weighted average entry price across all hedge positions for this (Provider, Instrument, Direction). From GetHedgePositionSummary.Avg Price. 0 for open-only rows (Part 2). |
| 7 | Open Total Lot | DECIMAL | YES | - | VERIFIED | Total open customer exposure in lots. From GetOpenPositionSummary.Total Lot. 0 for hedge-only rows (Part 3). |
| 8 | Hedge Total Lot | DECIMAL | YES | - | VERIFIED | Total hedge exposure in lots. From GetHedgePositionSummary.Total Lot. 0 for open-only rows (Part 2). |
| 9 | Lot Difference | DECIMAL (computed) | YES | - | VERIFIED | Hedge gap in lots: `Open Total Lot - Hedge Total Lot`. Positive = under-hedged (customer exposure > hedge). Negative = over-hedged (hedge > customer exposure). Zero = perfectly hedged. For unhedged positions (Part 2): equals Open Total Lot. For over-hedged (Part 3): equals -Hedge Total Lot. |
| 10 | Open P&L | DECIMAL | YES | - | VERIFIED | Unrealized P&L on the customer-side open positions, in USD. From GetOpenPositionSummary.P&L. 0 for hedge-only rows. |
| 11 | Hedge P&L | DECIMAL | YES | - | VERIFIED | Unrealized P&L on the hedge positions, in USD. From GetHedgePositionSummary.P&L. 0 for open-only rows. |
| 12 | P&L Difference | DECIMAL (computed) | YES | - | VERIFIED | P&L gap: `Open P&L - Hedge P&L`. Measures the dollar discrepancy in unrealized profit between the customer book and the hedge book. In a perfect hedge, Open P&L + Hedge P&L should sum to zero (they move in opposite directions). A non-zero P&L Difference may indicate imperfect hedging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Open side columns | BackOffice.GetOpenPositionSummary | Source (full outer join) | Customer position aggregation - provides Open Avg Price, Open Total Lot, Open P&L, and the matching key (Provider, Instrument, BUY/SELL). |
| Hedge side columns | BackOffice.GetHedgePositionSummary | Source (full outer join) | Hedge position aggregation - provides Hedge Avg Price, Hedge Total Lot, Hedge P&L. |

### 5.2 Referenced By (other objects point to this)

No active dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPositionSummaryDifference (view)
├── BackOffice.GetOpenPositionSummary (view)
│     ├── Trade.Position (cross-schema view)
│     ├── Trade.CurrencyPrice (cross-schema table)
│     ├── Trade.Provider (cross-schema table)
│     ├── Trade.GetInstrument (cross-schema view)
│     ├── Trade.ProviderToInstrument (cross-schema table)
│     └── Internal.GetOnePipValueDollar (cross-schema function)
└── BackOffice.GetHedgePositionSummary (view)
      ├── Trade.Hedge (cross-schema table)
      ├── Trade.CurrencyPrice (cross-schema table)
      ├── Trade.Provider (cross-schema table)
      ├── Trade.GetInstrument (cross-schema view)
      ├── Trade.ProviderToInstrument (cross-schema table)
      └── Internal.GetOnePipValueDollar (cross-schema function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetOpenPositionSummary | View | FROM clause (alias BOPS) - customer position side of reconciliation |
| BackOffice.GetHedgePositionSummary | View | FROM clause (alias BHPS) - hedge position side of reconciliation |

### 6.2 Objects That Depend On This

No active dependents found (typically queried directly by risk team).

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: The implicit INNER JOIN in Part 1 uses old-style comma syntax. Parts 2 and 3 use NOT EXISTS subqueries for left-only and right-only detection. This is a manual FULL OUTER JOIN implementation. Performance is expensive - both base views are themselves heavy queries against large Trade schema tables with scalar function calls per row.

---

## 8. Sample Queries

### 8.1 Find all unhedged open positions (no hedge coverage)

```sql
SELECT Provider, Instrument, [BUY/SELL], [Open Total Lot], [Open P&L]
FROM BackOffice.GetPositionSummaryDifference WITH (NOLOCK)
WHERE [Hedge Total Lot] = 0
ORDER BY [Open Total Lot] DESC
```

### 8.2 Find largest lot discrepancies requiring review

```sql
SELECT Provider, Instrument, [BUY/SELL],
       [Open Total Lot], [Hedge Total Lot], [Lot Difference],
       [P&L Difference]
FROM BackOffice.GetPositionSummaryDifference WITH (NOLOCK)
WHERE ABS([Lot Difference]) > 1.0
ORDER BY ABS([Lot Difference]) DESC
```

### 8.3 Check total P&L discrepancy across all instruments

```sql
SELECT SUM([Open P&L]) AS TotalOpenPnL,
       SUM([Hedge P&L]) AS TotalHedgePnL,
       SUM([P&L Difference]) AS TotalPnLGap
FROM BackOffice.GetPositionSummaryDifference WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this view. Related pages found for general reconciliation architecture (not specific to this object).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7 (Phase 2 skipped - inherits timeout risk)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPositionSummaryDifference | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetPositionSummaryDifference.sql*
