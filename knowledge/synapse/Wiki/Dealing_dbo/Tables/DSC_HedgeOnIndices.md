# Dealing_dbo.DSC_HedgeOnIndices

> Daily aggregate dealing desk report showing hedge cost, PnL zero, and LP boundary spread for the four major indices instruments traded on eToro.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — no single production source; computed from DWH_dbo dimensions |
| **Refresh** | Daily |
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

DSC_HedgeOnIndices is a daily-level dealing desk report that tracks eToro's hedge performance on four major index CFD instruments: SPX500/USD (InstrumentID 27), NSDQ100/USD (28), DJ30/USD (29), and GER30/EUR (32). "DSC" stands for Dealing Desk System Cost — this table captures the daily cost of hedging the firm's net exposure on indices.

The data is computed entirely within the DWH by `SP_Dealing_DSC_HedgeOnIndices`. The SP reads position-level data from `DWH_dbo.Dim_Position` (filtered to valid customers from `DWH_dbo.Dim_Customer`, instrument type Indices from `DWH_dbo.Dim_Instrument`, and hedge servers 222 and 21), calculates hourly unrealized PnL and realized PnL into the detail table `DSC_HedgeOnIndices_H`, then aggregates by day/instrument into this summary table.

Refreshed daily as part of the Dealing_dbo ETL process (Priority 21 in OpsDB orchestration). The SP accepts a `@Date` parameter and deletes/reloads all data from that date forward.

---

## 2. Business Logic

### 2.1 Zero (Net P&L)

**What**: The "zero" metric represents the net P&L impact of client positions on a given day — combining realized gains from closed positions with changes in unrealized P&L from open positions.

**Columns Involved**: `Zero`

**Rules**:
- Zero = SUM(Realized + Unrealized_Change) across all hours
- Realized = NetProfit + Commission from positions closed during the hour
- Unrealized_Change = difference in unrealized PnL between consecutive hourly snapshots
- A zero value of 0 means the hedging perfectly offset client P&L

### 2.2 Hedge Cost (HC_ALL)

**What**: Total hedge cost incurred from the bid-ask spread at position open and close events, converted to USD.

**Columns Involved**: `HC_ALL`

**Rules**:
- HC_ALL = SUM(LotCount * Spread/2) at each open/close event
- Spread is (Ask - Bid) at the moment of execution
- Values are converted to USD using Dim_GetSpreadedPriceCandle60MinSplitted rates with SellCurrencyID-based conversion factors

### 2.3 Theoretical Boundary Cost

**What**: The difference between the actual zero (net P&L) and what a synthetic account-based approach would yield, indicating the theoretical cost of boundary-style hedging.

**Columns Involved**: `TheoreticalBoundaryCost`, `Zero`, `SpreadLPBoundary`

**Rules**:
- TheoreticalBoundaryCost = Zero - SyntheticAccountPnL (from the hourly detail)
- SpreadLPBoundary = negative boundary volume * fixed spread factor (0.00004125)
- Boundary volume = Conversion * |units_delta| * BidLast * 0.8

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `DateID`. Always filter on `DateID` or `Date` for optimal performance. With only ~6,800 rows across 4 instruments, this is a small table and full scans are acceptable.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily hedge cost for a specific index | `WHERE InstrumentID = 27 AND DateID BETWEEN @Start AND @End` |
| Compare zero across all indices for a date | `WHERE DateID = @DateID` — returns exactly 4 rows |
| Weekly/monthly hedge cost trends | `GROUP BY DATEPART(week, Date)` or `DATEPART(month, Date)` on any column |
| Identify days with high boundary cost | `ORDER BY ABS(TheoreticalBoundaryCost) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID = InstrumentID | Get full instrument details, currency, asset class |
| Dealing_dbo.DSC_HedgeOnIndices_H | ON DateID = DateID AND InstrumentID = InstrumentID | Drill down to hourly detail |
| Dealing_dbo.Dealing_NOP_Report | ON Date and InstrumentID | Correlate hedge cost with NOP exposure |

### 3.4 Gotchas

- Only 4 instruments are tracked: SPX500/USD (27), NSDQ100/USD (28), DJ30/USD (29), GER30/EUR (32). Other indices are NOT included.
- Recent data may show all zeros — this can happen if the hedge server configuration (HedgeServerID IN 222, 21) has changed or if no positions were open for these indices.
- The `Date` column is `date` type (no time). For hourly granularity, use `DSC_HedgeOnIndices_H`.
- `TheoreticalBoundaryCost` can be negative — this indicates the boundary approach would have been cheaper than the actual hedge.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — SP_Dealing_DSC_HedgeOnIndices)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date identifier in YYYYMMDD integer format. `CAST(FORMAT(Date, 'yyyyMMdd') AS INT)` from the hourly detail table. Used as the clustered index key. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 2 | Date | date | YES | Calendar date for this daily aggregate row. Cast from the datetime hourly buckets in DSC_HedgeOnIndices_H. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 3 | InstrumentID | int | YES | Financial instrument identifier. Restricted to 4 major indices: 27=SPX500/USD, 28=NSDQ100/USD, 29=DJ30/USD, 32=GER30/EUR. Filtered in SP WHERE clause: `InstrumentTypeID=4 AND Tradable=1 AND InstrumentID IN (27,28,29,32)`. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 4 | InstrumentType | varchar(50) | NO | Instrument asset class. Always 'Indices' for rows in this table. Joined from `DWH_dbo.Dim_Instrument.InstrumentType`. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 5 | Name | varchar(50) | NO | Instrument display name (e.g., 'SPX500/USD', 'NSDQ100/USD', 'DJ30/USD', 'GER30/EUR'). Joined from `DWH_dbo.Dim_Instrument.Name`. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 6 | Zero | float | YES | Net P&L zero for the day per instrument. `SUM(ISNULL(realised, 0) + ISNULL(unrealdiff, 0))` across all hourly intervals. Realized = SUM(NetProfit + Commission) from closed positions; Unrealdiff = delta in unrealized PnL between consecutive hours. A value of 0 means perfect hedge neutrality. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 7 | HC_ALL | numeric(38,6) | YES | Daily total hedge cost from bid-ask spreads at position open/close events. `SUM(LotCountDecimal * Spread/2)` at opens + closes, converted to USD via SellCurrencyID-based conversion from Dim_GetSpreadedPriceCandle60MinSplitted. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 8 | TheoreticalBoundaryCost | float | YES | Theoretical cost of boundary-style hedging. `SUM(Zero) - SUM(SyntheticAccountPnL)` from the hourly detail table. Positive = boundary approach more expensive than actual; negative = boundary would have been cheaper. SyntheticAccountPnL = (BidLast_delta * units * 0.8) converted to USD minus boundary volume cost. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 9 | SpreadLPBoundary | numeric(38,6) | YES | LP boundary spread cost. `SUM(-boundariesvolume * 0.00004125)` per day. BoundariesVolume = Conversion * ABS(units_delta) * BidLast * 0.8. Represents the cost of the spread charged by the LP on boundary hedging volume. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |
| 10 | UpdateDate | datetime | NO | ETL load timestamp — set to `GETDATE()` when SP_Dealing_DSC_HedgeOnIndices runs. (Tier 2 — SP_Dealing_DSC_HedgeOnIndices) |

---

## 5. Lineage

### 5.1 Production Sources

This table has no direct production source. It is computed entirely within the DWH from position, instrument, and customer dimensions.

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | etoro.Trade.PositionTbl (via Dim_Position) | InstrumentID | passthrough |
| InstrumentType | etoro.Trade.Instrument (via Dim_Instrument) | InstrumentType | passthrough |
| Name | etoro.Trade.Instrument (via Dim_Instrument) | Name | passthrough |
| Zero | etoro.Trade.PositionTbl (via Dim_Position) | NetProfit, Commission | ETL-computed: realized + unrealized change |
| HC_ALL | etoro.Trade.PositionTbl (via Dim_Position) | AmountInUnitsDecimal, SpreadOpen, SpreadClose | ETL-computed |

Full lineage: see [DSC_HedgeOnIndices.lineage.md](DSC_HedgeOnIndices.lineage.md)

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position ──┐
DWH_dbo.Dim_Instrument ┤──► SP_Dealing_DSC_HedgeOnIndices ──► DSC_HedgeOnIndices_H ──► DSC_HedgeOnIndices
DWH_dbo.Dim_Customer ──┤                                      (hourly detail)           (daily aggregate)
DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted ─┘
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Position, Dim_Instrument, Dim_Customer, Dim_GetSpreadedPriceCandle60MinSplitted | Position, instrument, and pricing dimensions |
| ETL | Dealing_dbo.SP_Dealing_DSC_HedgeOnIndices | Calculates hourly hedge metrics from positions, aggregates to daily |
| Intermediate | Dealing_dbo.DSC_HedgeOnIndices_H | Hourly detail — unrealized, realized, commission, units, spread per instrument |
| Target | Dealing_dbo.DSC_HedgeOnIndices | Daily summary per instrument — zero, hedge cost, boundary cost |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Financial instrument lookup (27=SPX500, 28=NSDQ100, 29=DJ30, 32=GER30) |
| DateID | DWH_dbo.Dim_Date | Calendar date dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_dbo.DSC_HedgeOnIndices_H | DateID, InstrumentID | Hourly detail rows that feed this daily aggregate |

---

## 7. Sample Queries

### 7.1 Daily hedge cost and zero for all indices last 30 days

```sql
SELECT
    Date,
    Name,
    Zero,
    HC_ALL,
    TheoreticalBoundaryCost,
    SpreadLPBoundary
FROM Dealing_dbo.DSC_HedgeOnIndices
WHERE DateID >= CAST(FORMAT(DATEADD(DAY, -30, GETDATE()), 'yyyyMMdd') AS INT)
ORDER BY Date DESC, Name;
```

### 7.2 Weekly average hedge cost per instrument

```sql
SELECT
    DATEPART(YEAR, Date) AS yr,
    DATEPART(WEEK, Date) AS wk,
    Name,
    AVG(Zero) AS avg_zero,
    AVG(HC_ALL) AS avg_hedge_cost,
    AVG(TheoreticalBoundaryCost) AS avg_boundary_cost
FROM Dealing_dbo.DSC_HedgeOnIndices
GROUP BY DATEPART(YEAR, Date), DATEPART(WEEK, Date), Name
ORDER BY yr DESC, wk DESC;
```

### 7.3 Days where boundary cost exceeded hedge cost with instrument details

```sql
SELECT
    h.Date,
    i.Name,
    i.InstrumentType,
    h.Zero,
    h.HC_ALL,
    h.TheoreticalBoundaryCost,
    h.SpreadLPBoundary
FROM Dealing_dbo.DSC_HedgeOnIndices h
JOIN DWH_dbo.Dim_Instrument i ON h.InstrumentID = i.InstrumentID
WHERE h.TheoreticalBoundaryCost < 0
ORDER BY h.TheoreticalBoundaryCost ASC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Diffusion](https://etoro-jira.atlassian.net/wiki/spaces/TKB/pages/11861295645/Diffusion) | Confluence | Indices hedge monitoring, NOP vs hedged deltas, execution factor calculations |
| [Create "Top System Instruments Zero & NOP" Report](https://etoro-jira.atlassian.net/wiki/spaces/TKB/pages/11887935736) | Confluence | Operational procedures for generating dealing desk zero and NOP reports |
| [Dealing System Architecture](https://etoro-jira.atlassian.net/wiki/spaces/CTO/pages/11532107859/Dealing+System+Architecture) | Confluence | Architecture of price servers, hedging services, and dealing desk tools |
| [H21 - Tail indices new strategy](https://etoro-jira.atlassian.net/wiki/spaces/TKB/blog/2024/01/31/12221317178) | Confluence | Tail indices VaR monitoring and hedge strategy context |

---

*Generated: 2026-03-21 | Quality: 7.2/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10*
*Object: Dealing_dbo.DSC_HedgeOnIndices | Type: Table | Production Source: Derived (DWH-computed)*
