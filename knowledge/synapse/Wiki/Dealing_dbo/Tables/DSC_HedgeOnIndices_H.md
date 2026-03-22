# Dealing_dbo.DSC_HedgeOnIndices_H

> Hourly-granularity dealing desk report capturing unrealized P&L, realized P&L, hedge cost, and LP boundary metrics for four major index CFD instruments.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — computed from DWH_dbo dimensions |
| **Refresh** | Daily (reloads all hours from @Date forward) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

DSC_HedgeOnIndices_H is the hourly detail table underlying the `DSC_HedgeOnIndices` daily aggregate. It captures per-hour, per-instrument hedge performance metrics for four major index CFDs: SPX500/USD (27), NSDQ100/USD (28), DJ30/USD (29), and GER30/EUR (32).

The data is computed by `SP_Dealing_DSC_HedgeOnIndices`, which iterates hour-by-hour from the input `@Date` through the current time. For each hour, the SP calculates: (1) the net unrealized P&L change from open positions, (2) the realized P&L from positions closed during that hour, (3) the hedge cost from spreads, and (4) the LP boundary spread cost using a fixed spread factor. This table is the intermediate output — the SP then aggregates it by day into `DSC_HedgeOnIndices`.

Refreshed daily. The SP deletes and reloads from `@Date` forward, making it a full-reload pattern for the affected date range.

---

## 2. Business Logic

### 2.1 Hourly Unrealized P&L Calculation

**What**: Tracks the change in unrealized P&L for net open positions between consecutive hours, using currency-converted pricing.

**Columns Involved**: `Unreals`, `Unreale`, `units`, `AskLast`, `BidLast`

**Rules**:
- Unreals = unrealized PnL at start of hour for positions open at that timestamp
- Unreale = unrealized PnL at end of hour (next interval's prices)
- For long positions (units > 0): uses AskLast pricing
- For short positions (units < 0): uses BidLast pricing
- All values converted to USD via SellCurrencyID-based conversion factors from Dim_Instrument
- The FLIP factor handles inverse currency pairs (e.g., 1/AskLast for certain currencies)

### 2.2 Synthetic Account PnL vs Actual Zero

**What**: Compares a synthetic account-based hedge approach against the actual net P&L.

**Columns Involved**: `Zero`, `SyntheticAccountPnL`

**Rules**:
- Zero = Realized + (Unreale - Unreals) — the actual net P&L
- SyntheticAccountPnL = price delta * units * 0.8 * conversion - boundary volume * spread factor
- The 0.8 multiplier represents an 80% hedge ratio
- The difference (Zero - SyntheticAccountPnL) becomes `TheoreticalBoundaryCost` in the daily aggregate

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `DateID`. With ~163K rows, queries benefit from `DateID` filtering. For specific hour drilldowns, add a `Date` filter.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Hourly P&L for a specific index on a date | `WHERE DateID = @DateID AND InstrumentID = @InstID ORDER BY Date` |
| Intraday zero trend | `SELECT Date, Zero FROM ... WHERE DateID = @DateID AND InstrumentID = @InstID ORDER BY Date` |
| Hours with highest hedge cost | `ORDER BY ABS(HC_ALL) DESC` with date filter |
| Aggregate to daily | This is already done in `DSC_HedgeOnIndices` — use that table instead |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_dbo.DSC_HedgeOnIndices | ON DateID AND InstrumentID | Link hourly detail to daily aggregate |
| DWH_dbo.Dim_Instrument | ON InstrumentID | Full instrument metadata |

### 3.4 Gotchas

- `Date` is `datetime` here (not `date` like in the daily aggregate) — it includes the hour component
- Many columns may be NULL (Unreals, Unreale, Realised, AskLast, BidLast, units) for hours with no position activity — the LEFT JOINs in the SP produce NULLs when no positions were open/closed
- Recent data shows all zeros — same situation as the daily table
- Each day produces up to `4 instruments × N hours` rows where N = hours from @Date to GETDATE()

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — SP_Dealing_DSC_HedgeOnIndices)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date portion in YYYYMMDD integer format. `CAST(FORMAT(Se, 'yyyyMMdd') AS INT)` from the hourly timestamp. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 2 | Date | datetime | YES | Hourly interval start time. Generated by WHILE loop: `@StartOfWeek` incremented by 1 hour per iteration from input @Date to GETDATE(). (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 3 | InstrumentID | int | YES | Financial instrument identifier. Restricted to 4 major indices: 27=SPX500/USD, 28=NSDQ100/USD, 29=DJ30/USD, 32=GER30/EUR. Filtered by `InstrumentTypeID=4 AND Tradable=1 AND InstrumentID IN (27,28,29,32)`. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 4 | InstrumentType | varchar(50) | NO | Instrument asset class. Always 'Indices'. Joined from `DWH_dbo.Dim_Instrument.InstrumentType`. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 5 | Name | varchar(50) | NO | Instrument display name (SPX500/USD, NSDQ100/USD, DJ30/USD, GER30/EUR). Joined from `DWH_dbo.Dim_Instrument.Name`. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 6 | Unreals | decimal(16,2) | YES | Unrealized P&L at start of hour for open positions. `-units * ConversionRate * (InitForexRate - Price) * MULTIPLIER`. NULL when no positions open during this hour. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 7 | Unreale | decimal(16,2) | YES | Unrealized P&L at end of hour (next interval's prices). Same formula as Unreals applied to the following hour's pricing snapshot. NULL when no positions open. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 8 | Realised | float | YES | Realized P&L from positions closed during this hour. `ISNULL(SUM(NetProfit), 0) + ISNULL(SUM(Commission), 0)` from Dim_Position where CloseOccurred falls within this hourly interval. NULL when no positions closed. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 9 | AskLast | decimal(16,4) | YES | Ask price at end of hour from `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted`. Used for long position unrealized PnL calculation. NULL if no pricing data. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 10 | BidLast | decimal(16,4) | YES | Bid price at end of hour from `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted`. Used for short position unrealized PnL calculation. NULL if no pricing data. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 11 | units | decimal(16,2) | YES | Net position units open during this hour. `SUM(IsBuy * LotCount + (IsBuy-1) * LotCount)` — positive = net long, negative = net short, zero = fully hedged. NULL when no positions. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 12 | Spread | numeric(38,8) | NO | Average close spread for positions closed during this hour. `AVG(EndForex_Ask - EndForex_Bid)` from Dim_Position. Default 0 when no closes. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 13 | Commission | float | NO | Total commission from positions closed during this hour. `ISNULL(SUM(FullCommissionOnClose), 0)`. Default 0 when no closes. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 14 | Zero | float | YES | Net P&L zero for this hour. `ISNULL(Realised, 0) + ISNULL(Unreale - Unreals, 0)`. Combines realized from closes with unrealized change from open positions. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 15 | SyntheticAccountPnL | numeric(38,6) | YES | Synthetic account hedge PnL. `(BidLast_delta * units * 0.8) * ConversionRate - boundariesvolume * 0.00004125`. Represents what a synthetic hedge account would yield. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 16 | HC_ALL | numeric(38,6) | YES | Hedge cost from bid-ask spread at open/close events. `SUM(LotCount * Spread/2)` at opens + closes, converted to USD via SellCurrencyID-based conversion. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 17 | SpreadLPBoundary | numeric(38,6) | YES | LP boundary spread cost. `-boundariesvolume * 0.00004125` where boundariesvolume = `Conversion * ABS(units_delta) * BidLast * 0.8`. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 18 | UpdateDate | datetime | NO | ETL load timestamp — `GETDATE()` at SP execution time. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |

---

## 5. Lineage

### 5.1 Production Sources

This table has no direct production source. It is computed entirely within the DWH from position, instrument, customer, and pricing dimensions.

Full lineage: see [DSC_HedgeOnIndices_H.lineage.md](DSC_HedgeOnIndices_H.lineage.md)

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position ──┐
DWH_dbo.Dim_Instrument ┤──► SP_Dealing_DSC_HedgeOnIndices ──► DSC_HedgeOnIndices_H
DWH_dbo.Dim_Customer ──┤     (hourly loop: @Date to GETDATE())
DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted ─┘
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Position, Dim_Instrument, Dim_Customer, Dim_GetSpreadedPriceCandle60MinSplitted | Position, instrument, customer, and hourly pricing data |
| ETL | Dealing_dbo.SP_Dealing_DSC_HedgeOnIndices | Hour-by-hour position aggregation with currency conversion and PnL calculation |
| Target | Dealing_dbo.DSC_HedgeOnIndices_H | Hourly detail per instrument |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Financial instrument lookup |
| DateID | DWH_dbo.Dim_Date | Calendar date dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_dbo.DSC_HedgeOnIndices | DateID, InstrumentID | Daily aggregate reads from this hourly detail |

---

## 7. Sample Queries

### 7.1 Hourly P&L breakdown for SPX500 on a specific date

```sql
SELECT Date, Unreals, Unreale, Realised, Zero, units, AskLast, BidLast
FROM Dealing_dbo.DSC_HedgeOnIndices_H
WHERE DateID = 20260310 AND InstrumentID = 27
ORDER BY Date;
```

### 7.2 Peak hourly hedge cost across all indices

```sql
SELECT TOP 20 Date, Name, HC_ALL, Zero, SyntheticAccountPnL, units
FROM Dealing_dbo.DSC_HedgeOnIndices_H
WHERE HC_ALL <> 0
ORDER BY ABS(HC_ALL) DESC;
```

### 7.3 Hours with significant net position exposure

```sql
SELECT h.Date, i.Name, h.units, h.AskLast, h.BidLast, h.Zero
FROM Dealing_dbo.DSC_HedgeOnIndices_H h
JOIN DWH_dbo.Dim_Instrument i ON h.InstrumentID = i.InstrumentID
WHERE ABS(h.units) > 100
ORDER BY h.Date DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Diffusion](https://etoro-jira.atlassian.net/wiki/spaces/TKB/pages/11861295645/Diffusion) | Confluence | Indices hedge monitoring, NOP vs hedged deltas |
| [Dealing System Architecture](https://etoro-jira.atlassian.net/wiki/spaces/CTO/pages/11532107859/Dealing+System+Architecture) | Confluence | Hedge service architecture, price server integration |

---

*Generated: 2026-03-21 | Quality: 7.0/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 17 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10*
*Object: Dealing_dbo.DSC_HedgeOnIndices_H | Type: Table | Production Source: Derived (DWH-computed)*
