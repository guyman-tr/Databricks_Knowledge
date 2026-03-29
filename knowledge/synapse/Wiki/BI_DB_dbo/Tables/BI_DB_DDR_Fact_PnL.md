# BI_DB_dbo.BI_DB_DDR_Fact_PnL

> 8.8B-row granular daily P&L fact table tracking unrealized PnL changes and realized net profit per customer × instrument type × position flags since 2015. Sourced from `Function_PnL_Single_Day` (which reads `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument`), aggregated by `SP_DDR_Fact_PnL` with daily DELETE/INSERT by DateID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multiple — `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument` via `Function_PnL_Single_Day` TVF |
| **Refresh** | Daily (DELETE/INSERT by DateID) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table is the daily P&L (Profit & Loss) fact table within the DDR (Daily Data Report) framework. Each row represents the aggregated unrealized PnL change and realized net profit for a single customer (`RealCID`) on a specific date, broken down by instrument type, copy-trade status, settlement status, buy/sell direction, leverage, futures, copy-fund, and SQF flags. It answers: "How much did each customer's positions gain or lose today, by asset class and trade characteristics?"

Data originates from `Function_PnL_Single_Day`, a TVF that reads position-level PnL from `BI_DB_PositionPnL` (daily position P&L snapshot), enriched with position attributes from `Dim_Position` and instrument metadata from `Dim_Instrument`. The SP aggregates position-level rows into customer × dimension-group granularity using SUM for monetary measures and COUNT for position counts.

`SP_DDR_Fact_PnL` runs daily via Service Broker (`SB_Daily`). It performs a DELETE by DateID followed by INSERT, making it idempotent and re-runnable. The ETL was authored in 2024-07-02 with subsequent additions: IsFuture/IsLeveraged/IsBuy (2025-03-09), IsSQF (2025-06-23), and null handling for lake merge keys (2025-12-07).

---

## 2. Business Logic

### 2.1 PnL Aggregation Grain

**What**: Positions are aggregated to CID × InstrumentType × flag combination level

**Columns Involved**: `RealCID`, `InstrumentTypeID`, `IsCopy`, `IsSettled`, `IsFuture`, `IsLeveraged`, `IsBuy`, `IsCopyFund`, `IsSQF`

**Rules**:
- The GROUP BY includes all 9 dimension columns — every unique combination gets its own row
- `UnrealizedPnLChange` and `NetProfit` are SUMmed across positions within each group
- `CountPositions` is the COUNT of distinct position rows in that group
- Total P&L for a CID on a date = SUM across all rows for that CID/DateID

### 2.2 Copy-Trade Detection

**What**: Distinguishes positions opened by copy-trading from manual positions

**Columns Involved**: `IsCopy`, `IsCopyFund`

**Rules**:
- `IsCopy = 1` when `MirrorID > 0` in the source function (position was opened via CopyTrader)
- `IsCopyFund = 1` when the position belongs to a Smart Portfolio / Fund vehicle (from `BI_DB_CopyFund_Positions` lookup in the function)
- Both flags are independent — a position can be copy but not fund, or fund but not copy

### 2.3 Leverage Classification

**What**: Flags whether positions in the group used leverage

**Columns Involved**: `IsLeveraged`

**Rules**:
- `IsLeveraged = 1` when `Leverage > 1` in the source position data
- Settled real stocks (`IsSettled=1, InstrumentTypeID=5`) typically have `IsLeveraged=0`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX. Always include `RealCID` in WHERE or JOIN conditions for optimal distribution-aligned queries. With 8.8B rows, always filter by `DateID` to limit scan scope.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total PnL for a customer on a date | `WHERE RealCID = @cid AND DateID = @dt` — SUM `UnrealizedPnLChange + NetProfit` across all rows |
| Daily PnL by asset class | `GROUP BY DateID, InstrumentTypeID` — SUM the measures |
| Copy vs non-copy P&L comparison | `GROUP BY DateID, IsCopy` — compare aggregated PnL |
| Count of active positions by instrument | `SUM(CountPositions) GROUP BY DateID, InstrumentTypeID` |
| Leveraged vs unleveraged performance | `GROUP BY DateID, IsLeveraged` — SUM PnL measures |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_InstrumentType` | `ON p.InstrumentTypeID = dit.InstrumentTypeID` | Resolve instrument type names (Stocks, Crypto, ETFs, etc.) |
| `DWH_dbo.Dim_Customer` | `ON p.RealCID = dc.RealCID` | Customer demographics, registration, country |
| `BI_DB_dbo.BI_DB_DDR_CID_Level` | `ON p.RealCID = cl.RealCID AND p.DateID = cl.DateID` | Full DDR daily picture per customer |

### 3.4 Gotchas

- **8.8B rows** — always filter by `DateID`. Unfiltered scans are prohibitively expensive.
- **UnrealizedPnLChange is a DELTA, not absolute** — it represents the day-over-day change in unrealized P&L, not the total unrealized P&L.
- **NetProfit is realized** — only positions that closed on this date contribute non-zero NetProfit.
- **IsCopy and IsCopyFund are independent** — a CopyFund position has `IsCopyFund=1` but may also have `IsCopy=1` if opened through copy-trading a fund manager.
- **Null coercion** — `IsFuture`, `IsCopyFund`, `IsSQF` are ISNULL'd to 0 — NULLs never appear in these columns.
- **IsSettled** — distinguishes CFD (`IsSettled=0`) from real/settled positions (`IsSettled=1`).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code / function) | `(Tier 2 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date key in YYYYMMDD integer format. Partition/filter key for daily DELETE/INSERT. Direct from `Function_PnL_Single_Day.DateID`. (Tier 2 — SP_DDR_Fact_PnL) |
| 2 | Date | date | YES | Calendar date corresponding to DateID. `@date` SP input parameter. (Tier 2 — SP_DDR_Fact_PnL) |
| 3 | RealCID | int | YES | Customer identifier. Renamed from `CID` in `Function_PnL_Single_Day`. Distribution key. (Tier 2 — SP_DDR_Fact_PnL) |
| 4 | InstrumentTypeID | int | YES | Instrument asset class. Join-enriched from `Dim_Instrument.InstrumentTypeID` via `frfc.InstrumentID = di.InstrumentID`. Common values: 4=Indices, 5=Stocks, 6=Commodities, 10=Crypto, 12=ETFs, 73=Currencies. (Tier 2 — SP_DDR_Fact_PnL) |
| 5 | IsCopy | int | YES | Copy-trade flag. `CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END`. 1=position opened via CopyTrader, 0=manual/independent. (Tier 2 — SP_DDR_Fact_PnL) |
| 6 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 7 | UnrealizedPnLChange | decimal(16,6) | YES | Day-over-day change in unrealized P&L in USD. `SUM(frfc.UnrealizedPnLChange)` aggregated across all positions in the group. Represents the daily mark-to-market movement for open positions. (Tier 2 — SP_DDR_Fact_PnL) |
| 8 | NetProfit | decimal(16,6) | YES | Realized net profit in USD from positions closed on this date. `SUM(frfc.NetProfit)` aggregated across closed positions in the group. Zero for groups with no closes. (Tier 2 — SP_DDR_Fact_PnL) |
| 9 | CountPositions | int | YES | Number of positions contributing to this row's PnL. `COUNT(frfc.PositionID)` within the group. (Tier 2 — SP_DDR_Fact_PnL) |
| 10 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 — SP_DDR_Fact_PnL) |
| 11 | IsFuture | int | YES | Futures contract flag. `ISNULL(frfc.IsFuture, 0)`. 1=futures position, 0=non-futures. NULL coerced to 0. (Tier 2 — SP_DDR_Fact_PnL) |
| 12 | IsLeveraged | int | YES | Leverage flag. `CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END`. 1=leveraged position (leverage multiplier > 1×), 0=unleveraged. (Tier 2 — SP_DDR_Fact_PnL) |
| 13 | IsBuy | int | YES | Trade direction. 1=long (buy), 0=short (sell). Direct from `Function_PnL_Single_Day.IsBuy`. (Tier 2 — SP_DDR_Fact_PnL) |
| 14 | IsCopyFund | int | YES | Smart Portfolio / Fund position flag. `ISNULL(frfc.IsCopyFund, 0)`. 1=position belongs to a Smart Portfolio or Fund vehicle, 0=regular. Derived from `BI_DB_CopyFund_Positions` lookup in the function. (Tier 2 — SP_DDR_Fact_PnL) |
| 15 | IsSQF | int | YES | Sustainable & Quality-Focused instrument flag. `ISNULL(frfc.IsSQF, 0)`. 1=instrument is SQF-classified via `Function_Instrument_Snapshot_Enriched`, 0=non-SQF. (Tier 2 — SP_DDR_Fact_PnL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateID | Function_PnL_Single_Day | DateID | passthrough |
| RealCID | Function_PnL_Single_Day | CID | rename |
| InstrumentTypeID | Dim_Instrument | InstrumentTypeID | join-enriched |
| IsCopy | Function_PnL_Single_Day | MirrorID | CASE WHEN > 0 |
| IsSettled | Function_PnL_Single_Day | IsSettled | passthrough |
| UnrealizedPnLChange | Function_PnL_Single_Day | UnrealizedPnLChange | SUM |
| NetProfit | Function_PnL_Single_Day | NetProfit | SUM |
| CountPositions | Function_PnL_Single_Day | PositionID | COUNT |
| IsLeveraged | Function_PnL_Single_Day | Leverage | CASE WHEN > 1 |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument
  + BI_DB_CopyFund_Positions + Function_Instrument_Snapshot_Enriched(IsSQF)
  |-- Function_PnL_Single_Day(@dateID) ---|
  v
[position-level PnL: 19 columns per position per day]
  |-- SP_DDR_Fact_PnL(@date): JOIN Dim_Instrument, GROUP BY 9 dims, SUM/COUNT ---|
  v
BI_DB_dbo.BI_DB_DDR_Fact_PnL (8.8B rows, CID × InstrumentType × flags grain)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | BI_DB_PositionPnL, Dim_Position, Dim_Instrument | Position-level daily PnL snapshots |
| TVF | Function_PnL_Single_Day | Joins sources, outputs 19-column position-level PnL |
| ETL | SP_DDR_Fact_PnL | DELETE/INSERT by DateID; aggregates with GROUP BY + SUM/COUNT |
| Target | BI_DB_DDR_Fact_PnL | Aggregated DDR PnL fact table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentTypeID | DWH_dbo.Dim_InstrumentType | Resolves to instrument class name |
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_V_DDR_PnL | — | View that reads this table for DDR reporting |
| BI_DB_dbo.BI_DB_V_DDR_Daily_Panel | — | Daily panel view aggregating DDR facts |
| BI_DB_dbo.Function_DDR_Aggregation_* | — | Aggregation functions for time-range rollups |

---

## 7. Sample Queries

### 7.1 Total daily PnL for a customer

```sql
SELECT DateID,
       SUM(UnrealizedPnLChange) AS TotalUnrealizedDelta,
       SUM(NetProfit) AS TotalRealized,
       SUM(UnrealizedPnLChange + NetProfit) AS TotalPnL,
       SUM(CountPositions) AS PositionCount
FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL
WHERE RealCID = 12345678
  AND DateID BETWEEN 20260301 AND 20260310
GROUP BY DateID
ORDER BY DateID;
```

### 7.2 PnL by asset class for a date range

```sql
SELECT dit.Name AS InstrumentType,
       SUM(p.UnrealizedPnLChange) AS UnrealizedDelta,
       SUM(p.NetProfit) AS RealizedProfit,
       SUM(p.CountPositions) AS Positions
FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL p
JOIN DWH_dbo.Dim_InstrumentType dit ON p.InstrumentTypeID = dit.InstrumentTypeID
WHERE p.DateID = 20260309
GROUP BY dit.Name
ORDER BY SUM(p.NetProfit) DESC;
```

### 7.3 Copy vs manual PnL comparison

```sql
SELECT DateID,
       CASE WHEN IsCopy = 1 THEN 'CopyTrade' ELSE 'Manual' END AS TradeType,
       SUM(UnrealizedPnLChange + NetProfit) AS TotalPnL,
       SUM(CountPositions) AS Positions
FROM BI_DB_dbo.BI_DB_DDR_Fact_PnL
WHERE DateID = 20260309
GROUP BY DateID, IsCopy
ORDER BY IsCopy;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_PnL | Type: Table | Production Source: Function_PnL_Single_Day + Dim_Instrument*
