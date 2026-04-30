# Hedge.PositionsHedgeTbl

> Hedge server persistence cache - stores the current aggregate customer position state per (InstrumentID, HedgeServerID, IsBuy), refreshed in bulk via TVP upsert. Separate rows for long and short directions. Currently empty (cleared state).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, HedgeServerID, IsBuy) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK + NC on AmountInUnitsDecimal/Redeemed) |

---

## 1. Business Meaning

Hedge.PositionsHedgeTbl is the hedge server's local persistence store for its current view of aggregate customer positions. Unlike Hedge.Netting (which stores the LP-side hedge position), this table stores the CUSTOMER-SIDE aggregated position data - how much exposure exists in each direction (long/short) per instrument, as seen by a specific hedge server instance.

The "persist" naming (reflected in the SP names: `SetHedgePersistData`, `ClearHedgeExposuresPersistData`, `DeleteZeroRowPositionsHedgePersistData`) indicates this is a snapshot/cache that is periodically refreshed. The hedge server can clear the whole table via TRUNCATE and reload it with a fresh snapshot from the current position state.

The PK includes IsBuy as a component (unlike Hedge.Netting where IsBuy is just a direction attribute), meaning long (IsBuy=1) and short (IsBuy=0) positions for the same instrument+server are stored as SEPARATE rows. This supports bidirectional exposure tracking without netting.

Each row captures not just the position size (AmountInUnitsDecimal) but also the margin and forex rate context needed to compute monetary exposure: UnitMargin for capital cost per unit, InitForexRate for cross-currency P&L conversion.

The NC index on (AmountInUnitsDecimal, Redeemed) directly supports the `DeleteZeroRowPositionsHedgePersistData` cleanup procedure that removes fully empty positions (both amounts are zero).

---

## 2. Business Logic

### 2.1 TVP Batch Upsert Pattern (SetHedgePersistData)

**What**: Positions are written in bulk via a table-valued parameter (TVP) type `Hedge.PositionsHedgePersistTable`, which matches the table schema exactly.

**Columns/Parameters Involved**: All columns

**Rules**:
- `SetHedgePersistData` receives a TVP `@HedgeToUpdate` of type `Hedge.PositionsHedgePersistTable`
- Step 1: UPDATE existing rows where (InstrumentID, HedgeServerID, IsBuy) matches
- Step 2: INSERT rows where no match exists (NOT EXISTS check on same PK)
- No DELETE in this SP - rows are only removed via TRUNCATE (`ClearHedgeExposuresPersistData`) or cleanup (`DeleteZeroRowPositionsHedgePersistData`)
- `@PersistID bigint OUTPUT` captures `scope_identity()` but is set BEFORE the INSERT, so it captures the scope identity from a prior operation - this appears to be a tracking/correlation ID for the caller

**Diagram**:
```
Hedge Server -> SetHedgePersistData(@HedgeToUpdate TVP)
                 |
                 +-> UPDATE matching rows (InstrumentID, HedgeServerID, IsBuy exist)
                 +-> INSERT new rows (not yet in table)
                 +-> OUTPUT: @PersistID (scope_identity tracking)
```

### 2.2 Clear and Cleanup Operations

**What**: Two separate procedures manage row removal.

**Rules**:
- `ClearHedgeExposuresPersistData`: TRUNCATE TABLE - removes ALL rows instantly. Used for full refresh cycles.
- `DeleteZeroRowPositionsHedgePersistData`: DELETE WHERE AmountInUnitsDecimal = 0 AND Redeemed = 0 - removes rows where the position has fully closed (no open units and no redeemed units). Supported by the NC index on (AmountInUnitsDecimal, Redeemed).
- A position with AmountInUnitsDecimal > 0 but Redeemed > 0 is partially redeemed - kept until both go to zero.

### 2.3 Bidirectional Position Tracking (IsBuy in PK)

**What**: Long and short positions are stored as separate rows, enabling independent tracking of both directions.

**Rules**:
- IsBuy=1 row = aggregate long (buy) position for that instrument/server
- IsBuy=0 row = aggregate short (sell) position for that instrument/server
- Both rows can exist simultaneously (unlike Hedge.Netting which has a single netted position)
- The hedge system can monitor gross exposure in each direction independently

---

## 3. Data Overview

Table is currently empty (0 rows). The table is in a cleared state - either the full refresh cycle just ran `ClearHedgeExposuresPersistData` and has not yet been repopulated, or the feature using this table is not currently active.

When populated, representative rows would look like:

| InstrumentID | HedgeServerID | IsBuy | AmountInUnitsDecimal | UnitMargin | InitForexRate | Redeemed | LastDataID | LastUpdated |
|---|---|---|---|---|---|---|---|---|
| 1 | 2 | 1 | 5,000,000.000000 | 0.00001250 | 1.08320000 | 0.000000 | 98765 | 2026-03-19 08:00:00 |
| 1 | 2 | 0 | 2,500,000.000000 | 0.00001250 | 1.08320000 | 500000.000000 | 98765 | 2026-03-19 08:00:00 |

Row 1: InstrumentID=1, long position of 5M units, no redemptions yet
Row 2: InstrumentID=1, short position of 2.5M units, 500K units redeemed

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | First component of composite PK. Implicit FK to Trade.Instrument. The financial instrument for which this position is tracked. Combined with HedgeServerID and IsBuy to form the unique key. |
| 2 | HedgeServerID | int | NO | - | VERIFIED | Second component of composite PK. Implicit FK to Trade.HedgeServer. Identifies which hedge server instance owns and maintains this position record. Each hedge server maintains its own position cache independently. |
| 3 | IsBuy | bit | NO | - | VERIFIED | Third component of composite PK. Direction flag: 1 = long (buy) position aggregate, 0 = short (sell) position aggregate. Included in the PK to allow separate rows for each direction - unlike Hedge.Netting where direction is just a column. Enables independent tracking of gross long and gross short exposure. |
| 4 | AmountInUnitsDecimal | decimal(16,6) | YES | - | VERIFIED | Current aggregate position size in instrument units for this direction. Nullable - may be NULL for empty/initializing positions. Combined with UnitMargin gives the total margin exposure. Paired with Redeemed in the NC index to support zero-row cleanup (both = 0 means position fully closed). |
| 5 | UnitMargin | decimal(16,8) | NO | - | VERIFIED | Margin cost per instrument unit at position opening. Used to convert unit-denominated position size into monetary exposure. 8 decimal places for precision in pip/unit calculations. Same concept as UnitMargin in Hedge.AccountStatus. |
| 6 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | The forex conversion rate in effect when the position was first established. Uses the custom `dbo.dtPrice` type (same as AvgRate in Hedge.Netting). Required for cross-currency P&L computation: converts instrument-currency P&L into account-currency terms. "Init" prefix means this is the rate at initialization, not the current rate. |
| 7 | Redeemed | decimal(16,6) | YES | - | CODE-BACKED | Amount of the position that has been redeemed (partially closed). Nullable. A position is fully closed when AmountInUnitsDecimal=0 AND Redeemed=0 (matching the cleanup predicate in `DeleteZeroRowPositionsHedgePersistData`). Non-zero Redeemed with zero AmountInUnitsDecimal means the position is in process of being cleaned up. |
| 8 | LastDataID | int | NO | - | CODE-BACKED | Identifier of the last data batch/record that updated this row. Used for synchronization tracking - allows the hedge server to identify which data cycle produced the current state. The TVP-based update sets this from the incoming data, enabling consumers to detect stale data. |
| 9 | LastUpdated | datetime | NO | - | VERIFIED | Timestamp when this row was last modified. NOT NULL - always set during upsert. Used to track data freshness. The TVP type `Hedge.PositionsHedgePersistTable` also marks LastUpdated as NOT NULL (only NOT NULL column in the TVP definition), indicating it is always required by the caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The financial instrument for the aggregate position |
| HedgeServerID | Trade.HedgeServer | Implicit | The hedge server that owns this position record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.SetHedgePersistData | InstrumentID, HedgeServerID, IsBuy | WRITER (upsert) | Bulk UPSERT via TVP - primary write path |
| Hedge.ClearHedgeExposuresPersistData | (all) | TRUNCATE | Full table clear for refresh cycle reset |
| Hedge.DeleteZeroRowPositionsHedgePersistData | AmountInUnitsDecimal, Redeemed | DELETER | Removes fully closed positions (both amounts = 0) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.PositionsHedgeTbl (table)
+-- Trade.Instrument (table) [implicit FK target - leaf]
+-- Trade.HedgeServer (table) [implicit FK target - leaf]
+-- Hedge.PositionsHedgePersistTable (User Defined Type) [TVP type used by SetHedgePersistData]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | Implicit FK target for InstrumentID |
| Trade.HedgeServer | Table | Implicit FK target for HedgeServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.SetHedgePersistData | Stored Procedure | WRITER - TVP-based batch upsert |
| Hedge.ClearHedgeExposuresPersistData | Stored Procedure | TRUNCATE - full clear |
| Hedge.DeleteZeroRowPositionsHedgePersistData | Stored Procedure | DELETE - removes zero-amount rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionsHedgeTbl | CLUSTERED PK | InstrumentID ASC, HedgeServerID ASC, IsBuy ASC | - | - | Active |
| Ix_AmountInUnitsDecimalRedeemed | NONCLUSTERED | AmountInUnitsDecimal ASC, Redeemed ASC | - | - | Active |

Note: `Ix_AmountInUnitsDecimalRedeemed` directly supports `DeleteZeroRowPositionsHedgePersistData` (DELETE WHERE AmountInUnitsDecimal = 0 AND Redeemed = 0). FILLFACTOR=95 on both indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PositionsHedgeTbl | PRIMARY KEY | One row per (Instrument, HedgeServer, Direction) |

### 7.3 Related User Defined Type

`Hedge.PositionsHedgePersistTable` is the TVP type used to bulk-feed data into this table via `SetHedgePersistData`. The type mirrors the table schema with all columns nullable except LastUpdated (NOT NULL).

---

## 8. Sample Queries

### 8.1 Current position snapshot per instrument and direction
```sql
SELECT  p.InstrumentID,
        p.HedgeServerID,
        CASE WHEN p.IsBuy = 1 THEN 'Long' ELSE 'Short' END AS Direction,
        p.AmountInUnitsDecimal,
        p.UnitMargin,
        p.InitForexRate,
        p.Redeemed,
        p.AmountInUnitsDecimal * p.UnitMargin AS EstimatedMarginExposure,
        p.LastDataID,
        p.LastUpdated
FROM    [Hedge].[PositionsHedgeTbl] p WITH (NOLOCK)
ORDER BY p.HedgeServerID, p.InstrumentID, p.IsBuy DESC;
```

### 8.2 Net position per instrument (aggregated across directions)
```sql
SELECT  p.InstrumentID,
        p.HedgeServerID,
        SUM(CASE WHEN p.IsBuy = 1 THEN p.AmountInUnitsDecimal ELSE -p.AmountInUnitsDecimal END) AS NetUnits
FROM    [Hedge].[PositionsHedgeTbl] p WITH (NOLOCK)
GROUP BY p.InstrumentID, p.HedgeServerID
ORDER BY p.HedgeServerID, p.InstrumentID;
```

### 8.3 Identify positions eligible for zero-row cleanup
```sql
SELECT  p.InstrumentID, p.HedgeServerID, p.IsBuy
FROM    [Hedge].[PositionsHedgeTbl] p WITH (NOLOCK)
WHERE   p.AmountInUnitsDecimal = 0
AND     p.Redeemed = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence search for "PositionsHedgeTbl" returned no results.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.PositionsHedgeTbl | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.PositionsHedgeTbl.sql*
