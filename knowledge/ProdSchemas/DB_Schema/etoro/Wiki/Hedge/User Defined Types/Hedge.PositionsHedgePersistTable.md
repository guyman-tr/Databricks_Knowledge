# Hedge.PositionsHedgePersistTable

> Table-valued parameter type carrying hedge position persistence data - instrument/server/direction aggregates with margin and rate details for bulk upsert into the hedge persistence tables.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | No primary key (heap TVP) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

`Hedge.PositionsHedgePersistTable` is a Table-Valued Parameter type whose structure mirrors `Hedge.PositionsHedgeTbl`. It enables the hedge server application to pass a batch of hedge position state snapshots in one call to `Hedge.SetHedgePersistData`.

Each row represents the aggregate state of hedge positions for one InstrumentID/HedgeServerID/IsBuy combination: total units, margin requirements, open forex rate, and redemption state. The "persist" terminology indicates that this data is written to a persistence table (`Hedge.PositionsHedgeTbl`) as an in-memory checkpoint of the hedge server's current position state, used for recovery after restarts.

The hedge server writes this data periodically so that on restart it can recover its position book without re-querying the full trading history.

---

## 2. Business Logic

### 2.1 Hedge Position State Checkpoint

**What**: Each TVP row captures the aggregate state of all hedge positions for one instrument/server/direction tuple at a point in time.

**Columns/Parameters Involved**: `InstrumentID`, `HedgeServerID`, `IsBuy`, `AmountInUnitsDecimal`, `UnitMargin`, `InitForexRate`, `Redeemed`, `LastDataID`, `LastUpdated`

**Rules**:
- `IsBuy` splits the hedge position into long vs. short sides - each direction is tracked separately.
- `AmountInUnitsDecimal`: total units currently held in this direction. The hedge server's net exposure in this instrument/direction.
- `UnitMargin`: margin cost per unit for this position, used in margin/equity calculations.
- `InitForexRate` (dbo.dtPrice): weighted average opening rate for the aggregate position. Used to compute unrealized PnL on recovery.
- `Redeemed`: portion of the position that has been redeemed/closed out. Used to track partial closure.
- `LastDataID` / `LastUpdated`: watermark fields - the last data ID and timestamp processed. On recovery, the hedge server uses these to identify which events have already been processed, preventing double-counting.

**Diagram**:
```
Hedge Server (in-memory state)
  |
  | periodically snapshots position state
  |
  | populates PositionsHedgePersistTable TVP
  v
Hedge.SetHedgePersistData (SP)
  |
  v
Hedge.PositionsHedgeTbl (persistence table)
  |
  +-- On restart: hedge server reads PositionsHedgeTbl to restore state
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument whose hedge position state is being persisted. Implicit FK to Trade.Instrument. Part of the composite key (InstrumentID, HedgeServerID, IsBuy). |
| 2 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server that owns this position aggregate. On recovery, the server reads its own persisted state using this filter. Implicit FK to Trade.HedgeServer. |
| 3 | IsBuy | bit | YES | - | CODE-BACKED | Position direction: 1 = long (buy-side hedge), 0 = short (sell-side hedge). Long and short positions are tracked separately for separate margin and PnL computation. |
| 4 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Total aggregate hedge position size in instrument units (decimal precision supports fractional shares/lots). This is the hedge server's current net exposure in this instrument/direction. |
| 5 | UnitMargin | decimal(16,8) | YES | - | CODE-BACKED | Margin requirement per unit for this position aggregate, in USD. Used to compute total used margin for the hedge account. High precision (16,8) for micro-lot accuracy. |
| 6 | InitForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Weighted average opening forex rate for the aggregate hedge position. Used to compute unrealized PnL on recovery: PnL = (CurrentRate - InitForexRate) * AmountInUnitsDecimal. |
| 7 | Redeemed | decimal(16,6) | YES | - | CODE-BACKED | Cumulative redeemed/closed portion of this position aggregate, in units. Redeemed + remaining open = original total. Tracks partial closure of the hedge. |
| 8 | LastDataID | int | YES | - | CODE-BACKED | Watermark: the last event/data ID that was processed when this persistence snapshot was taken. On recovery, the hedge server uses this to identify and replay only events after this point, preventing double-processing. |
| 9 | LastUpdated | datetime | NO | - | CODE-BACKED | Timestamp of this persistence snapshot (NOT NULL). Used to order snapshots chronologically and detect stale persistence data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Identifies the trading instrument being hedged |
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies the hedge server that owns the position state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.SetHedgePersistData | @PositionsHedge parameter | TVP parameter | Receives the hedge position state batch for upsert into Hedge.PositionsHedgeTbl |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

Note: Uses `dbo.dtPrice` for `InitForexRate`.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type (scalar) | Used as data type for InitForexRate column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.SetHedgePersistData | Stored Procedure | Bulk-upserts hedge position state to Hedge.PositionsHedgeTbl |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View current hedge position persistence state
```sql
SELECT InstrumentID, HedgeServerID, IsBuy,
       AmountInUnitsDecimal, UnitMargin, InitForexRate, LastUpdated
FROM [Hedge].[PositionsHedgeTbl] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY InstrumentID, IsBuy
```

### 8.2 Find stale persistence data (not updated recently)
```sql
SELECT HedgeServerID, COUNT(*) AS StaleRows,
       MIN(LastUpdated) AS OldestUpdate
FROM [Hedge].[PositionsHedgeTbl] WITH (NOLOCK)
WHERE LastUpdated < DATEADD(minute, -5, GETUTCDATE())
GROUP BY HedgeServerID
```

### 8.3 Compare hedge position by direction
```sql
SELECT InstrumentID,
       SUM(CASE WHEN IsBuy = 1 THEN AmountInUnitsDecimal ELSE 0 END) AS LongUnits,
       SUM(CASE WHEN IsBuy = 0 THEN AmountInUnitsDecimal ELSE 0 END) AS ShortUnits,
       SUM(CASE WHEN IsBuy = 1 THEN AmountInUnitsDecimal ELSE -AmountInUnitsDecimal END) AS NetUnits
FROM [Hedge].[PositionsHedgeTbl] WITH (NOLOCK)
WHERE HedgeServerID = 1
GROUP BY InstrumentID
ORDER BY ABS(SUM(CASE WHEN IsBuy = 1 THEN AmountInUnitsDecimal ELSE -AmountInUnitsDecimal END)) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.PositionsHedgePersistTable | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.PositionsHedgePersistTable.sql*
