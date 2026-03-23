# BI_DB_dbo.BI_DB_DDR_Fact_PnL

> DDR (Daily Data Report) fact table — daily per-customer aggregation of unrealized PnL change, realized net profit, and position counts, sliced by instrument type, copy-trade flags, settlement, futures, leverage, side, copy-fund, and SQF (Spot Quoted Futures).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — DDR daily aggregate) |
| **Production Source** | `BI_DB_dbo.Function_PnL_Single_Day(@dateID)` + `DWH_dbo.Dim_Instrument` via `SP_DDR_Fact_PnL` |
| **Refresh** | Per business date — `DELETE WHERE DateID = @dateID` + `INSERT` for that day |
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

`BI_DB_DDR_Fact_PnL` is a **DDR pyramid** fact: one row represents a single **grain** of trading PnL for a **real customer** (`RealCID`) on a **calendar day**, after aggregation from position-level PnL produced by `Function_PnL_Single_Day`. The grain includes **instrument type** (`InstrumentTypeID` from `Dim_Instrument`), whether the activity is **copy trading** (`IsCopy` from `MirrorID`), **settled vs open/CFD** posture (`IsSettled`), **futures** vs other (`IsFuture`), **leveraged** vs not (`IsLeveraged` from `Leverage > 1`), **buy vs sell** (`IsBuy`), **copy-fund** positions (`IsCopyFund`), and **Spot Quoted Futures** (`IsSQF`).

Measures stored are **unrealized PnL change** for the day, **net profit** (realized component from the TVF), and **how many positions** contributed to that cell (`CountPositions`). Together with downstream view `BI_DB_V_DDR_PnL`, this table feeds **customer daily/periodic status**, **DDR aggregation functions** (week/month/quarter/year, MoM, YoY), and **BI dashboards** that compare manual vs copy PnL and splits by asset class.

Author: Guy Manova (SP header). SP created 2024-07-02; dimensions `IsFuture`, `IsLeveraged`, `IsBuy` added 2025-03-09; `IsSQF` 2025-06-23; null handling for merge keys 2025-12-07.

---

## 2. Business Logic

### 2.1 Load pattern

**What**: Replace one calendar day’s rows in the fact.

**Columns involved**: `DateID`, `[Date]`, all measures.

**Rules** (from `SP_DDR_Fact_PnL`):

- `@dateID = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)`.
- `DELETE FROM BI_DB_DDR_Fact_PnL WHERE DateID = @dateID`.
- `INSERT ... SELECT` from aggregated TVF output; `[Date] = @date` (constant for the batch); `UpdateDate = GETDATE()`.

### 2.2 Aggregation grain

**What**: Multiple positions roll up to one row per distinct combination of dimension keys.

**Rules**:

- Source: `FROM BI_DB_dbo.Function_PnL_Single_Day(@dateID) frfc JOIN DWH_dbo.Dim_Instrument di ON frfc.InstrumentID = di.InstrumentID`.
- `GROUP BY`: `DateID`, `CID`, `InstrumentTypeID`, copy flag (`MirrorID > 0`), `IsSettled`, `IsFuture` (null→0), `IsLeveraged` (`Leverage > 1`), `IsBuy`, `IsCopyFund` (null→0), `IsSQF` (null→0).
- `RealCID` in the table = **`frfc.CID`** (real customer id).
- **UnrealizedPnLChange** = `SUM(UnrealizedPnLChange)`; **NetProfit** = `SUM(NetProfit)`; **CountPositions** = `COUNT(PositionID)`.

### 2.3 Upstream PnL semantics (TVF)

**What**: `Function_PnL_Single_Day` builds position-level realized + unrealized PnL for the day from `BI_DB_PositionPnL` (open position marks) and `Dim_Position` (positions closed on `@dateID`), then tags **IsSQF** by joining `Function_Instrument_Snapshot_Enriched(@dateID)` where `IsSQF = 1`.

**Note**: Detailed position-level formulas (e.g. unrealized change from start/end marks) live in `Function_PnL_Single_Day`; this fact only stores **aggregates** at the DDR grain.

---

## 3. Query Advisory

### 3.1 Synapse distribution and columnstore

**HASH(RealCID)**: Co-locates rows for the same customer — good for **filtering or joining on `RealCID`**. Combine with **`DateID`** predicates to limit scans.

**CLUSTERED COLUMNSTORE**: Favors **analytical aggregates** over narrow OLTP point lookups. Prefer **date-scoped** queries and avoid `SELECT *` on wide exploratory scans without filters.

### 3.1b UC (Databricks) storage and partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join to | Join condition | Purpose |
|---------|----------------|---------|
| `DWH_dbo.Dim_Instrument` | `InstrumentTypeID` | Instrument type name / hierarchy |
| `DWH_dbo.Dim_Customer` | `RealCID` = customer key | Customer attributes |
| `DWH_dbo.Dim_Date` | `DateID` | Calendar attributes |
| `BI_DB_dbo.BI_DB_V_DDR_PnL` | `RealCID`, `DateID` | Pre-rolled daily PnL totals and asset-class splits |

### 3.3 Gotchas

- **Grain is not “one row per customer per day”** — there are **multiple rows per customer per day** (one per dimension combination). Use `SUM` with correct filters or use `BI_DB_V_DDR_PnL` for customer-day totals.
- **Total daily PnL** for reporting is often computed as **`UnrealizedPnLChange + NetProfit`** (see `BI_DB_V_DDR_PnL`).
- **`IsCopy`**: derived from **`MirrorID > 0`**, not a raw column on this table.
- **Refresh ordering**: This table is part of the DDR batch; consumers assume **a full day’s load** for a given `DateID`.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_PnL) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NULL | Business date as YYYYMMDD integer. Delete/replace key for the daily load. (Tier 2 — SP_DDR_Fact_PnL) |
| 2 | Date | date | NULL | Calendar date for the batch — equals parameter `@date` in `SP_DDR_Fact_PnL`. (Tier 2 — SP_DDR_Fact_PnL) |
| 3 | RealCID | int | NULL | Real customer ID (`frfc.CID`). HASH distribution key. (Tier 2 — SP_DDR_Fact_PnL) |
| 4 | InstrumentTypeID | int | NULL | Instrument type from `DWH_dbo.Dim_Instrument` for `frfc.InstrumentID`. (Tier 2 — SP_DDR_Fact_PnL) |
| 5 | IsCopy | int | NULL | `1` if copy trade (`MirrorID > 0`), else `0`. (Tier 2 — SP_DDR_Fact_PnL) |
| 6 | IsSettled | int | NULL | Settlement / product posture flag from position-level PnL (passed through from `Function_PnL_Single_Day`). (Tier 2 — SP_DDR_Fact_PnL) |
| 7 | UnrealizedPnLChange | decimal(16,6) | NULL | Sum of unrealized PnL change for the day for this grain. (Tier 2 — SP_DDR_Fact_PnL) |
| 8 | NetProfit | decimal(16,6) | NULL | Sum of realized net profit for the grain (from TVF). (Tier 2 — SP_DDR_Fact_PnL) |
| 9 | CountPositions | int | NULL | Count of distinct `PositionID` values in the grain. (Tier 2 — SP_DDR_Fact_PnL) |
| 10 | UpdateDate | datetime | NULL | ETL load timestamp — `GETDATE()` at insert. (Tier 2 — SP_DDR_Fact_PnL) |
| 11 | IsFuture | int | NULL | `ISNULL(IsFuture, 0)` from TVF — futures instrument flag. (Tier 2 — SP_DDR_Fact_PnL) |
| 12 | IsLeveraged | int | NULL | `1` if `Leverage > 1`, else `0`. (Tier 2 — SP_DDR_Fact_PnL) |
| 13 | IsBuy | int | NULL | Long (`1`) vs short (`0`) side from position data. (Tier 2 — SP_DDR_Fact_PnL) |
| 14 | IsCopyFund | int | NULL | `ISNULL(IsCopyFund, 0)` — position is in a copy fund (from TVF / copy-fund join logic). (Tier 2 — SP_DDR_Fact_PnL) |
| 15 | IsSQF | int | NULL | `ISNULL(IsSQF, 0)` — Spot Quoted Futures instrument (from `Function_Instrument_Snapshot_Enriched` inside TVF). (Tier 2 — SP_DDR_Fact_PnL) |

---

## 5. Lineage

### 5.1 Pipeline

```
BI_DB_dbo.Function_PnL_Single_Day(@dateID)
  ← BI_DB_PositionPnL, Dim_Position, Dim_Instrument, BI_DB_CopyFund_Positions,
     Function_Instrument_Snapshot_Enriched(@dateID)
       │
       └─ JOIN DWH_dbo.Dim_Instrument (InstrumentTypeID)
            │
            └─ SP_DDR_Fact_PnL(@date)
                 ├─ DELETE WHERE DateID = @dateID
                 └─ INSERT aggregated rows
```

### 5.2 Key source objects

| Source | Columns used |
|--------|----------------|
| `BI_DB_dbo.Function_PnL_Single_Day(@dateID)` | Position-level PnL, CID, InstrumentID, MirrorID, IsSettled, IsFuture, Leverage, IsBuy, IsCopyFund, IsSQF, DateID |
| `DWH_dbo.Dim_Instrument` | `InstrumentTypeID` |

---

## 6. Relationships

### 6.1 References to (this object points to)

| Target object | Join column | Description |
|---------------|-------------|-------------|
| `DWH_dbo.Dim_Instrument` | `InstrumentTypeID` | Instrument type dimension |
| `DWH_dbo.Dim_Customer` | `RealCID` | Customer dimension |
| `DWH_dbo.Dim_Date` | `DateID` | Date dimension |

### 6.2 Referenced by (other objects point to this)

| Source object | Description |
|---------------|-------------|
| `BI_DB_dbo.BI_DB_V_DDR_PnL` | View — aggregates to customer-day PnL buckets |
| `BI_DB_dbo.BI_DB_V_DDR_Daily_Panel` | Customer daily panel (via `BI_DB_V_DDR_PnL`) |
| `BI_DB_dbo.Function_DDR_Aggregation_Yesterday` | Period-compare TVFs consuming `BI_DB_V_DDR_PnL` |
| `BI_DB_dbo.Function_DDR_Aggregation_ThisWeek` | (same) |
| `BI_DB_dbo.Function_DDR_Aggregation_ThisMonth` | (same) |
| `BI_DB_dbo.Function_DDR_Aggregation_ThisQuarter` | (same) |
| `BI_DB_dbo.Function_DDR_Aggregation_ThisYear` | (same) |
| `BI_DB_dbo.Function_DDR_Aggregation_YoY` | (same) |
| `BI_DB_dbo.Function_DDR_Aggregation_MoM` | (same) |

---

## 7. Sample Queries

### 7.1 Customer total PnL for one day (matches view logic)

```sql
SELECT  RealCID,
        SUM(UnrealizedPnLChange + NetProfit) AS DailyTotalPnL
FROM    BI_DB_dbo.BI_DB_DDR_Fact_PnL
WHERE   DateID = 20260320
  AND   RealCID = 12345678
GROUP BY RealCID;
```

### 7.2 Manual vs copy split for one day

```sql
SELECT  IsCopy,
        SUM(UnrealizedPnLChange + NetProfit) AS PnL
FROM    BI_DB_dbo.BI_DB_DDR_Fact_PnL
WHERE   DateID = 20260320
GROUP BY IsCopy;
```

### 7.3 Drill to SQF and futures slice

```sql
SELECT  RealCID,
        SUM(UnrealizedPnLChange + NetProfit) AS PnL
FROM    BI_DB_dbo.BI_DB_DDR_Fact_PnL
WHERE   DateID = 20260320
  AND   IsSQF = 1
  AND   IsFuture = 1
GROUP BY RealCID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| _None auto-linked in this pass_ | — | Add Confluence links for DDR pyramid / customer daily panel when available |

---

*Generated: 2026-03-23 | Quality: 7.5/10 (★★★★☆) | Phases: wiki pass from DataPlatform repo (SP + TVF)*  
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10 (no Confluence hits in pass)*  
*Object: BI_DB_dbo.BI_DB_DDR_Fact_PnL | Type: Table | Writer: SP_DDR_Fact_PnL*
