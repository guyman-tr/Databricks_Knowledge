# Hedge.GetCurrentOpenExposure

> Returns the aggregated open position exposure snapshot for hedge computation, using a time buffer to create a stable reference point. Supports optional instrument-level filtering via TVP. Returns two result sets: the exposure aggregation and the computed reference timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TimeBufferSeconds (required), @InstrumentIDsTbl (optional filter TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers the core hedge exposure question: "Given a time buffer to ensure stable data, what are the current open positions that should be hedged, and how much?"

The time buffer mechanism addresses a race condition: positions that just opened may not yet be fully synchronized across all systems. By applying a `@TimeBufferSeconds` lookback, the procedure works with positions that were definitively open as of `bufferTime = now - @TimeBufferSeconds`, rather than positions opened right now. This creates a stable, consistent exposure snapshot for hedge calculations.

The procedure returns:
1. **Exposure aggregation** (first result set): per (HedgeServerID, InstrumentID, IsBuy) group - total units, size-weighted average forex rate and unit margin
2. **Reference time** (second result set): the exact `@bufferTime` used for the calculation, so callers can log and correlate which time point this exposure represents

`@InstrumentIDsTbl` is an optional filter: when empty, all instruments are included; when populated, only the specified instruments are returned. This allows targeted exposure queries (e.g., refresh one instrument's exposure) without re-running the full snapshot.

Only positions with `IsComputeForHedge = 1` are included - positions excluded from hedge computation are filtered out.

---

## 2. Business Logic

### 2.1 Time Buffer - Stable Reference Point

**What**: A configurable lookback window ensures the exposure snapshot only includes positions whose state has stabilized.

**Columns/Parameters Involved**: `@TimeBufferSeconds`, `@bufferTime`, `OpenOccurred`, `CloseOccurred`

**Rules**:
- `@bufferTime = DATEADD(second, -1 * @TimeBufferSeconds, GETUTCDATE())` - timestamp in the past
- `OpenOccurred <= @bufferTime` - position must have been open before the buffer time (excludes very recent opens)
- `CloseOccurred > @bufferTime OR CloseOccurred IS NULL` - position must NOT have been closed before the buffer time (includes positions still open or closed after the reference point)
- Combined: positions that were OPEN AT the buffer time - i.e., the state of open positions as of `bufferTime`
- Positions opened exactly at `bufferTime` are excluded (strict `<=`)

**Effect**: Setting `@TimeBufferSeconds = 60` gives the exposure picture as of 60 seconds ago, filtering out positions opened in the last minute.

### 2.2 Optional Instrument Filter (Empty TVP Pattern)

**What**: `@InstrumentIDsTbl` can be empty (all instruments) or populated (specific instruments only).

**Columns/Parameters Involved**: `@InstrumentIDsTbl`, `tpos.InstrumentID`

**Rules**:
- `IF NOT EXISTS (SELECT TOP 1 1 FROM @InstrumentIDsTbl)` - checks whether the TVP has rows
- Empty TVP (0 rows): runs the "all instruments" branch - no instrument filter applied
- Populated TVP: runs the "filtered instruments" branch - INNER JOIN limits results to specified instruments
- Both branches produce identical column structures and the same aggregation logic
- `Trade.InstrumentIDsTbl`: simple TVP type with single `InstrumentID int NOT NULL` column (not memory-optimized)

### 2.3 Aggregation - Per Server/Instrument/Direction

**What**: Positions are aggregated into (HedgeServerID, InstrumentID, IsBuy) groups with weighted-average rate fields.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `InitForexRate`, `UnitMargin`, `IsBuy`

**Rules**:
- `SUM(tpos.AmountInUnitsDecimal)` - total hedgeable position size for this group
- `SUM(tpos.InitForexRate * tpos.AmountInUnitsDecimal) / SUM(tpos.AmountInUnitsDecimal)` - weighted average initial forex rate (larger positions contribute more to the average)
- `SUM(tpos.UnitMargin * tpos.AmountInUnitsDecimal) / SUM(tpos.AmountInUnitsDecimal)` - weighted average unit margin
- `IsBuy` separates long (1) and short (0) exposures - they are not netted against each other at this level
- `PositionID = 0` and `CID = 0` are constant stubs - aggregate results do not correspond to individual positions or customers

### 2.4 IsComputeForHedge Filter

**What**: Only positions eligible for hedge computation are included.

**Columns/Parameters Involved**: `IsComputeForHedge` (from `Trade.GetPositionDataSlim`)

**Rules**:
- `IsComputeForHedge = 1` - positions marked for hedge computation only
- Excludes positions that are open but should not influence hedge exposure (e.g., certain position types, internal accounts)

### 2.5 Second Result Set - Reference Time

**What**: Always returns the buffer time as a second result set after the exposure data.

**Rules**:
- `SELECT @bufferTime AS [ReferenceTime]` - always returned as second result set
- Allows callers to log and correlate which point-in-time the exposure snapshot represents
- Critical for reconciliation: callers can verify the actual reference time used

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeBufferSeconds | int | NO | - | CODE-BACKED | Required. Number of seconds to subtract from GETUTCDATE() to compute the reference time (@bufferTime). Positions opened within this window are excluded. Typical values: 30-120 seconds. Larger values = more stable but older snapshot. |
| 2 | @InstrumentIDsTbl | Trade.InstrumentIDsTbl READONLY | NO | - | CODE-BACKED | TVP filter for specific instruments. When empty (0 rows), all instruments are returned. When populated, only positions for the specified InstrumentIDs are returned. Trade.InstrumentIDsTbl has one column: InstrumentID int NOT NULL. |

**Output Columns (First Result Set - Exposure Aggregation)**:

| Column | Description |
|--------|-------------|
| HedgeServerID | The hedge server responsible for this exposure group. Groups positions by server for hedge routing. |
| InstrumentID | The trading instrument. Grouped separately per instrument. |
| AmountInUnitsDecimal | SUM of position sizes for this (HedgeServerID, InstrumentID, IsBuy) group. Total units to hedge. |
| IsBuy | Direction: 1=long exposure (buy positions), 0=short exposure (sell positions). Long and short not netted here. |
| PositionID | Always 0 - stub constant. Aggregate result has no single PositionID. |
| CID | Always 0 - stub constant. Aggregate result has no single customer ID. |
| InitForexRate | Size-weighted average of InitForexRate across all positions in this group. Larger positions contribute proportionally more. |
| UnitMargin | Size-weighted average of UnitMargin across all positions in this group. |

**Output Columns (Second Result Set - Reference Time)**:

| Column | Description |
|--------|-------------|
| ReferenceTime | The @bufferTime datetime computed as `GETUTCDATE() - @TimeBufferSeconds`. The actual reference point used for the exposure snapshot. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Trade.GetPositionDataSlim | View read (WITH NOLOCK) | Unified open+closed position data; filtered to open-at-bufferTime and IsComputeForHedge=1 |
| @InstrumentIDsTbl param | Trade.InstrumentIDsTbl | TVP parameter type | Single-column TVP for instrument ID filtering (InstrumentID int NOT NULL) |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the hedge engine's exposure calculation component to retrieve the current open exposure snapshot for hedge sizing decisions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetCurrentOpenExposure (procedure)
├── Trade.GetPositionDataSlim (view) - open/closed position data with hedge fields
|   ├── Trade.PositionTbl (open positions, StatusID=1)
|   └── History.PositionSlim (closed positions)
└── Trade.InstrumentIDsTbl (type) - TVP parameter type for optional instrument filter
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionDataSlim | View | FROM clause; filtered by time buffer, IsComputeForHedge=1; optionally joined to @InstrumentIDsTbl |
| Trade.InstrumentIDsTbl | User Defined Type | TVP parameter type; contains InstrumentID int NOT NULL; used for INNER JOIN when non-empty |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @bufferTime computed | Logic | Computed as DATEADD(second, -1 * @TimeBufferSeconds, GETUTCDATE()) - always a past timestamp |
| WITH (NOLOCK) | Isolation | Applied to Trade.GetPositionDataSlim - dirty reads accepted for exposure calculations |
| Dual result sets | Output | Always returns 2 result sets: exposure aggregation (first) + reference time (second). Callers must consume both. |
| Division by zero risk | Edge Case | Weighted average formulas divide by SUM(AmountInUnitsDecimal). If all positions in a group have AmountInUnitsDecimal=0, division by zero occurs. In practice, positions with 0 units should not exist for hedge-eligible positions. |
| IsBuy not netted | Design | Long and short positions are returned as separate rows. The hedge engine is responsible for netting the long/short exposure if needed. |
| PositionID/CID stubs | Design | Both are hardcoded 0 - aggregate results cannot be traced back to individual positions. Consumer should not join on these columns. |

---

## 8. Sample Queries

### 8.1 Equivalent query for all instruments with 60-second buffer

```sql
DECLARE @bufferTime datetime = DATEADD(second, -60, GETUTCDATE());

SELECT tpos.HedgeServerID, tpos.InstrumentID,
       SUM(tpos.AmountInUnitsDecimal) AS AmountInUnitsDecimal,
       tpos.IsBuy,
       SUM(tpos.InitForexRate * tpos.AmountInUnitsDecimal) / SUM(tpos.AmountInUnitsDecimal) AS InitForexRate,
       SUM(tpos.UnitMargin * tpos.AmountInUnitsDecimal) / SUM(tpos.AmountInUnitsDecimal) AS UnitMargin
FROM Trade.GetPositionDataSlim tpos WITH (NOLOCK)
WHERE tpos.OpenOccurred <= @bufferTime
  AND (tpos.CloseOccurred > @bufferTime OR tpos.CloseOccurred IS NULL)
  AND tpos.IsComputeForHedge = 1
GROUP BY tpos.HedgeServerID, tpos.InstrumentID, tpos.IsBuy
ORDER BY tpos.HedgeServerID, tpos.InstrumentID, tpos.IsBuy
```

### 8.2 Net exposure per server/instrument (long minus short)

```sql
DECLARE @bufferTime datetime = DATEADD(second, -60, GETUTCDATE());

SELECT HedgeServerID, InstrumentID,
       SUM(CASE WHEN IsBuy = 1 THEN AmountInUnitsDecimal
                ELSE -AmountInUnitsDecimal END) AS NetExposure
FROM (
    SELECT tpos.HedgeServerID, tpos.InstrumentID, tpos.IsBuy,
           SUM(tpos.AmountInUnitsDecimal) AS AmountInUnitsDecimal
    FROM Trade.GetPositionDataSlim tpos WITH (NOLOCK)
    WHERE tpos.OpenOccurred <= @bufferTime
      AND (tpos.CloseOccurred > @bufferTime OR tpos.CloseOccurred IS NULL)
      AND tpos.IsComputeForHedge = 1
    GROUP BY tpos.HedgeServerID, tpos.InstrumentID, tpos.IsBuy
) ex
GROUP BY HedgeServerID, InstrumentID
ORDER BY ABS(SUM(CASE WHEN IsBuy = 1 THEN AmountInUnitsDecimal ELSE -AmountInUnitsDecimal END)) DESC
```

### 8.3 Check exposure for specific instruments (the filtered path)

```sql
DECLARE @bufferTime datetime = DATEADD(second, -30, GETUTCDATE());

SELECT tpos.HedgeServerID, tpos.InstrumentID,
       SUM(tpos.AmountInUnitsDecimal) AS AmountInUnitsDecimal, tpos.IsBuy
FROM Trade.GetPositionDataSlim tpos WITH (NOLOCK)
INNER JOIN (VALUES (1), (8), (25)) AS ins(InstrumentID) ON tpos.InstrumentID = ins.InstrumentID
WHERE tpos.OpenOccurred <= @bufferTime
  AND (tpos.CloseOccurred > @bufferTime OR tpos.CloseOccurred IS NULL)
  AND tpos.IsComputeForHedge = 1
GROUP BY tpos.HedgeServerID, tpos.InstrumentID, tpos.IsBuy
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetCurrentOpenExposure | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetCurrentOpenExposure.sql*
