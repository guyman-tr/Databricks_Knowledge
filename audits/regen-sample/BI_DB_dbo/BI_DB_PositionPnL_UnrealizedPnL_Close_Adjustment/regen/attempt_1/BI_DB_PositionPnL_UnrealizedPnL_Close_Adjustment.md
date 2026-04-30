# BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment

> ~278M-row daily close-adjustment table capturing the **unrealized P&L change for positions that closed on each trading day**, complementing `BI_DB_PositionPnL` (which tracks only open positions at EOD). Grain is one row per closed `PositionID` per `DateID`. Data spans 2023-01-01 to 2024-07-06. Refreshed daily by `SP_PositionPnL_UnrealizedPnL_Close_Adjustment`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.SP_PositionPnL_UnrealizedPnL_Close_Adjustment (reads BI_DB_PositionPnL + Dim_Position) |
| **Refresh** | Daily (SB_Daily, Priority 0, ProcessType SQL) |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Synapse Partitions** | None |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment` complements the main `BI_DB_PositionPnL` table by capturing the unrealized P&L impact when positions close during the day. `BI_DB_PositionPnL` only contains open positions at end-of-day, so when a position closes, its unrealized P&L "disappears" from the open snapshot. This table records that disappearance as the close adjustment.

For each position that closed on `@date`, the SP reads the prior day's `PositionPnL` (unrealized P&L) from `BI_DB_PositionPnL` as `UnrealizedPnLStart`, sets `UnrealizedPnLEnd` to 0 (the position is now closed), and computes `UnrealizedPnLChange` as the difference. It also captures the realized `NetProfit` from `Dim_Position` for the same positions. This enables efficient computation of total unrealized P&L change across all positions (open + closed) for a given day.

The table stores ~278M rows spanning from 20230101 to 20240706 (188+ distinct dates in recent data). Each row carries the position's dimension attributes (InstrumentID, MirrorID, Leverage, IsBuy, IsSettled, HedgeServerID, SettlementTypeID) to support filtering and aggregation without needing to re-join Dim_Position.

---

## 2. Business Logic

### 2.1 Unrealized P&L Close Adjustment

**What**: Captures the unrealized P&L that "vanishes" when a position closes during the day.

**Columns Involved**: `UnrealizedPnLStart`, `UnrealizedPnLEnd`, `UnrealizedPnLChange`, `NetProfit`

**Rules**:
- `UnrealizedPnLStart` = prior-day `PositionPnL` from `BI_DB_PositionPnL` (the last known unrealized P&L while the position was still open).
- `UnrealizedPnLEnd` = 0 always (position is closed; unrealized P&L ceases to exist).
- `UnrealizedPnLChange` = CASE logic: if Start IS NULL then End; if End IS NULL then -1 * Start; else End - Start. Typically equals -1 * UnrealizedPnLStart since End = 0.
- `NetProfit` = realized profit/loss from `Dim_Position` for positions where `CloseDateID = @dateID`.
- The SP uses a JOIN (not FULL OUTER JOIN) between prior-day BI_DB_PositionPnL and same-day Dim_Position closures, so only positions that appear in BOTH sources are included.

### 2.2 Daily DELETE + INSERT Pattern

**What**: Each day's data is replaced atomically.

**Columns Involved**: `DateID`

**Rules**:
- `DELETE FROM ... WHERE DateID = @dateID` runs before INSERT.
- INSERT populates all 15 columns from `#unrealizedPrep` temp table.
- No partition switching; direct DELETE + INSERT on the main table.

### 2.3 Position Attribute COALESCE

**What**: Dimension columns prefer Dim_Position values over BI_DB_PositionPnL values.

**Columns Involved**: `CID`, `InstrumentID`, `MirrorID`, `Leverage`, `IsBuy`, `IsSettled`, `HedgeServerID`, `SettlementTypeID`

**Rules**:
- All dimension attributes use `COALESCE(dp.{col}, upl.{col})`, preferring Dim_Position (the canonical source) over the BI_DB_PositionPnL snapshot.
- `PositionID` and `CID` use `COALESCE(upl.{col}, dp.{col})` — preferring the prior-day snapshot, though in practice both sources have the same value.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH (PositionID)**: Rows distributed by PositionID. Joins to `BI_DB_PositionPnL` (also HASH on PositionID) and `Dim_Position` (also HASH on PositionID) are co-located.

**CLUSTERED COLUMNSTORE INDEX**: Good compression for the large row count. No explicit nonclustered indexes.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total unrealized PnL change for a day (including closed positions) | SUM this table's UnrealizedPnLChange + SUM BI_DB_PositionPnL.DailyPnL for the same DateID |
| Closed-position PnL adjustment for a date range | WHERE DateID BETWEEN X AND Y |
| Close adjustment by instrument | WHERE DateID = X GROUP BY InstrumentID |
| CFD vs Real asset close adjustments | WHERE IsSettled = 0 (CFD) or IsSettled = 1 (Real) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_PositionPnL | ON PositionID AND DateID | Combine open-position and close-adjustment P&L for total daily unrealized change |
| DWH_dbo.Dim_Position | ON PositionID | Full position attributes, close details |
| DWH_dbo.Dim_Instrument | ON InstrumentID | Instrument name, asset class |
| DWH_dbo.Dim_Customer | ON CID | Customer demographics |

### 3.4 Gotchas

- **No partition elimination**: Unlike `BI_DB_PositionPnL`, this table has no partitions. Always include a `DateID` filter to avoid full columnstore scans across all ~278M rows.
- **UnrealizedPnLEnd is always 0**: This is by design (closed positions have no unrealized P&L). Do not mistake this for missing data.
- **JOIN semantics in SP**: The SP uses an inner JOIN between prior-day BI_DB_PositionPnL and same-day Dim_Position closures. Positions that close on their opening day (same-day open/close with no prior-day PositionPnL entry) may not appear.
- **IsBuy is int, not bit**: Unlike Dim_Position (bit), this table stores IsBuy as int. Values are still 0/1.
- **SettlementTypeID NULL values**: ~3.5% of rows have NULL SettlementTypeID (716K of 20.5M in June-July 2024 sample). These predate the column's addition to upstream sources.
- **Data stops at 20240706**: The table appears to have stopped loading after this date. Verify current load status before relying on recent data.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ***** | Tier 1 - Production source via upstream wiki | (Tier 1 — Trade.PositionTbl) |
| *** | Tier 2 - Synapse SP code | (Tier 2 — source_table) |
| ** | Tier 3 - ETL runtime | (Tier 3 — SP parameter / GETDATE()) |
| * | Tier 5 - Expert Review | (Tier 5 — Expert Review) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Snapshot date as YYYYMMDD integer; computed from SP parameter `@date`. Used as the daily grain key. DELETE + INSERT idempotency key. (Tier 3 — SP_PositionPnL_UnrealizedPnL_Close_Adjustment, CAST(CONVERT(CHAR(8),@date,112) AS INT)) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 3 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Synapse distribution key. (Tier 1 — Trade.PositionTbl) |
| 4 | UnrealizedPnLStart | decimal(16,6) | YES | Prior-day unrealized P&L for the position, sourced from `BI_DB_PositionPnL.PositionPnL` where DateID = day before @date. Represents the last known unrealized P&L while the position was still open. (Tier 2 — BI_DB_PositionPnL) |
| 5 | UnrealizedPnLEnd | decimal(16,6) | YES | End-of-day unrealized P&L after close. Always 0 — the position closed during the day, so unrealized P&L ceases. (Tier 2 — SP_PositionPnL_UnrealizedPnL_Close_Adjustment) |
| 6 | UnrealizedPnLChange | decimal(16,6) | YES | Change in unrealized P&L: CASE WHEN Start IS NULL THEN End; WHEN End IS NULL THEN -1 * Start; ELSE End - Start END. Typically equals -1 * UnrealizedPnLStart since End = 0. (Tier 2 — BI_DB_PositionPnL) |
| 7 | NetProfit | decimal(16,6) | YES | Realized PnL. 0 when open; set on close. In position currency. Passthrough from Dim_Position for positions closing on @date. (Tier 1 — Trade.PositionTbl) |
| 8 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 9 | MirrorID | int | YES | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 10 | Leverage | int | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 11 | IsBuy | int | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. Stored as int (not bit) in this table. (Tier 1 — Trade.PositionTbl) |
| 12 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 13 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) |
| 14 | SettlementTypeID | int | YES | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) |
| 15 | UpdateDate | datetime | YES | Row load timestamp at insert (GETDATE()). (Tier 3 — SP_PositionPnL_UnrealizedPnL_Close_Adjustment, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| DateID | (SP parameter) | @date | CAST(CONVERT(CHAR(8),@date,112) AS INT) |
| CID | Trade.PositionTbl (via Dim_Position) | CID | COALESCE passthrough |
| PositionID | Trade.PositionTbl (via Dim_Position) | PositionID | COALESCE passthrough |
| UnrealizedPnLStart | BI_DB_PositionPnL | PositionPnL | Prior-day value; SUM(ISNULL(…,0)) |
| UnrealizedPnLEnd | (literal) | 0 | Hardcoded — position closed |
| UnrealizedPnLChange | BI_DB_PositionPnL | PositionPnL | CASE on Start/End difference |
| NetProfit | Trade.PositionTbl (via Dim_Position) | NetProfit | ISNULL passthrough |
| InstrumentID | Trade.PositionTbl (via Dim_Position) | InstrumentID | COALESCE passthrough |
| MirrorID | Trade.PositionTbl (via Dim_Position) | MirrorID | COALESCE passthrough |
| Leverage | Trade.PositionTbl (via Dim_Position) | Leverage | COALESCE passthrough |
| IsBuy | Trade.PositionTbl (via Dim_Position) | IsBuy | COALESCE passthrough; bit→int widening |
| IsSettled | Dim_Position | IsSettled | COALESCE passthrough |
| HedgeServerID | Trade.PositionTbl (via Dim_Position) | HedgeServerID | COALESCE passthrough |
| SettlementTypeID | Trade.PositionTbl (via Dim_Position) | SettlementTypeID | COALESCE passthrough |
| UpdateDate | (runtime) | GETDATE() | Row insert timestamp |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionTbl (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging → SP_Dim_Position_DL_To_Synapse @dt
  v
DWH_dbo.Dim_Position (CloseDateID = @dateID — closed positions)
  |                                                                \
  |   BI_DB_dbo.BI_DB_PositionPnL (DateID = prior day — open positions EOD)
  |     |
  |     v
  |-- SP_PositionPnL_UnrealizedPnL_Close_Adjustment @date ---|
  v
BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment (~278M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| PositionID | DWH_dbo.Dim_Position | Position dimension (canonical) |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| MirrorID | DWH_dbo.Dim_Mirror | Copy-trading mirror relationship |
| HedgeServerID | DWH_dbo.Dim_HedgeServer | Hedge server dimension |
| SettlementTypeID | Dictionary.SettlementTypes | Settlement type lookup |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| (No known consumers found in SSDT repo) | This table is consumed externally for total unrealized P&L reporting but no downstream SPs or views reference it in the current codebase |

---

## 7. Sample Queries

### 7.1 Total Unrealized P&L Change for a Day (Open + Closed)

```sql
-- Combine open-position daily PnL with close-adjustment PnL
SELECT
    o.DateID,
    SUM(o.DailyPnL) AS OpenPositionDailyPnL,
    SUM(c.UnrealizedPnLChange) AS CloseAdjustmentPnL,
    SUM(o.DailyPnL) + SUM(c.UnrealizedPnLChange) AS TotalUnrealizedPnLChange
FROM BI_DB_dbo.BI_DB_PositionPnL o
FULL OUTER JOIN BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment c
    ON o.DateID = c.DateID AND o.PositionID = c.PositionID
WHERE o.DateID = 20240701
GROUP BY o.DateID
```

### 7.2 Close Adjustments by Instrument for a Date

```sql
SELECT
    c.InstrumentID,
    di.SymbolFull,
    COUNT(*) AS ClosedPositions,
    SUM(c.UnrealizedPnLChange) AS TotalUnrealizedChange,
    SUM(c.NetProfit) AS TotalRealizedProfit
FROM BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment c
JOIN DWH_dbo.Dim_Instrument di ON c.InstrumentID = di.InstrumentID
WHERE c.DateID = 20240701
GROUP BY c.InstrumentID, di.SymbolFull
ORDER BY COUNT(*) DESC
```

### 7.3 Real vs CFD Close Adjustment Comparison

```sql
SELECT
    DateID,
    CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD' END AS AssetType,
    COUNT(*) AS Positions,
    SUM(UnrealizedPnLChange) AS TotalUnrealizedChange,
    SUM(NetProfit) AS TotalRealizedProfit
FROM BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment
WHERE DateID BETWEEN 20240601 AND 20240630
GROUP BY DateID, CASE WHEN IsSettled = 1 THEN 'Real' ELSE 'CFD' END
ORDER BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (low-value for this well-documented ETL table).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 9 T1, 3 T2, 2 T3, 0 T4, 1 T5 | Elements: 15/15, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment | Type: Table | Production Source: SP_PositionPnL_UnrealizedPnL_Close_Adjustment (via BI_DB_PositionPnL + Dim_Position)*
