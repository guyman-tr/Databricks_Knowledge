# Hedge.AddCustomerRealizedData

> Accepts a table-valued parameter of customer closed position data, aggregates it by instrument and hedge server, and upserts the accumulated totals into Hedge.CustomerClosedPositions_New using xlock to prevent concurrency conflicts.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.CustomerClosedPositions_New via TVP input |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddCustomerRealizedData` is the accumulation writer for the customer-side realized P&L store. It receives a batch of closed position data via a table-valued parameter (TVP of type `Hedge.CustomerClosedPositions_New`) and accumulates its totals into the persisted `Hedge.CustomerClosedPositions_New` table.

The key business behavior is accumulation: new P&L, commission, and execution volume are ADDED to the most recent matching row in the table (within the last 7 days, matching on HedgeServerID + InstrumentID + partition key), not simply inserted as a new row. This makes the table a rolling accumulator of customer realized activity rather than a raw event log.

This procedure exists to maintain the customer-side realized P&L total that feeds the `Hedge.HedgeCostReport` family of procedures. The `CustomerClosedPositions_New` table stores how much P&L customers realized per instrument per hedge server - the counterpart to `Hedge.AccountClosedPositions` (the broker side). The delta between the two sides defines the realized hedge cost.

The `xlock` hint in the OUTER APPLY ensures that when multiple concurrent threads call this procedure simultaneously, they see a consistent last row and avoid double-counting race conditions. Change history note: `xlock` was added 2020-09-30 (developer: Shany S) specifically to support concurrent thread safety.

---

## 2. Business Logic

### 2.1 Aggregation Before Upsert

**What**: The TVP input is first aggregated by (InstrumentID, HedgeServerID) before being merged into the persistent table.

**Columns/Parameters Involved**: `@CustomerClosedPositions_New` TVP, #AggregatedCustomerClosedPosition

**Rules**:
- Step 1: All rows in the TVP input are GROUP BY (InstrumentID, HedgeServerID) into a temp table
- SUM(NetPL), SUM(CommissionOnClose), SUM(ExecutionVolumeInUSD) per group
- Clustered index CIX on (HedgeServerID, InstrumentID) on the temp table for join performance
- Step 2: For each aggregated group, find the most recent matching row in CustomerClosedPositions_New (within last 7 days, same HedgeServerID + InstrumentID + PartitionCol) using OUTER APPLY + TOP 1 + ORDER BY OccurredAt DESC

### 2.2 Accumulation Semantics - Add to Existing Row

**What**: The inserted row's totals are the sum of the new batch PLUS the most recent existing row's totals.

**Columns/Parameters Involved**: `NetPL`, `CommissionOnClose`, `ExecutionVolumeInUSD`

**Rules**:
- `NetPL = new_agg.NetPL + ISNULL(existing.NetPL, 0)` - adds to the existing accumulated value
- `CommissionOnClose = new_agg.CommissionOnClose + ISNULL(existing.CommissionOnClose, 0)`
- `ExecutionVolumeInUSD = new_agg.ExecutionVolumeInUSD + ISNULL(existing.ExecutionVolumeInUSD, 0)`
- The "existing" row is found via OUTER APPLY within the last 7 days; if none found, ISNULL defaults to 0 (fresh start)
- PartitionCol filter: `b.PartitionCol = (b.HedgeServerID + b.InstrumentID) % 10` - uses modulo hash to target the correct partition bucket

### 2.3 Concurrent Thread Safety (xlock)

**What**: xlock on the OUTER APPLY subquery prevents race conditions when multiple threads call this procedure simultaneously.

**Columns/Parameters Involved**: `@CustomerClosedPositions_New` table, xlock hint

**Rules**:
- `WITH (xlock)` on the OUTER APPLY subquery acquires an exclusive lock on the row being read
- This ensures that if two threads both find the same "last row" and try to add to it, they are serialized
- Without xlock, both threads would read the same base value and write two rows that each add to the same number - resulting in double-counting

**Diagram**:
```
TVP Input (@CustomerClosedPositions_New rows)
      |
      v
SELECT ... GROUP BY (InstrumentID, HedgeServerID) -> #AggregatedCustomerClosedPosition
      |
      v
For each aggregated group:
  OUTER APPLY (SELECT TOP 1 ... FROM CustomerClosedPositions_New WITH(xlock)
               WHERE HedgeServerID=? AND InstrumentID=? AND OccurredAt >= GETUTCDATE()-7
               ORDER BY OccurredAt DESC)
      |
      v
INSERT INTO CustomerClosedPositions_New (
    NetPL = new_agg.NetPL + ISNULL(existing.NetPL, 0),
    CommissionOnClose = new_agg.CommissionOnClose + ISNULL(existing.CommissionOnClose, 0),
    ExecutionVolumeInUSD = new_agg.ExecutionVolumeInUSD + ISNULL(existing.ExecutionVolumeInUSD, 0)
)
OUTPUT Inserted.*
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerClosedPositions_New | Hedge.CustomerClosedPositions_New (TVP) | NO | - | CODE-BACKED | Table-valued parameter (READONLY) containing a batch of customer closed position records to accumulate. Type definition: Hedge.CustomerClosedPositions_New UDT with columns InstrumentID, HedgeServerID, NetPL, CommissionOnClose, ExecutionVolumeInUSD. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CustomerClosedPositions_New | Hedge.CustomerClosedPositions_New (UDT) | Type reference | Input TVP type definition |
| (reads + writes) | Hedge.CustomerClosedPositions_New (table) | Accumulation upsert | Reads last 7-day row with xlock; inserts new accumulated row |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the hedge server's realized P&L pipeline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddCustomerRealizedData (procedure)
├── Hedge.CustomerClosedPositions_New (UDT) - input TVP type
└── Hedge.CustomerClosedPositions_New (table) - read (xlock) + insert
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerClosedPositions_New | User Defined Type | TVP input parameter type |
| Hedge.CustomerClosedPositions_New | Table | OUTER APPLY read (last 7 days, xlock) + INSERT target for accumulated rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge server realized P&L pipeline) | External | Calls to accumulate customer closed position data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- Temp table `#AggregatedCustomerClosedPosition` has clustered index on (HedgeServerID, InstrumentID)
- `DROP TABLE IF EXISTS` ensures clean state on each invocation
- `OUTPUT Inserted.*` returns all inserted rows to the caller
- PartitionCol filter: `(HedgeServerID + InstrumentID) % 10` - must match the target table's partition column formula

---

## 8. Sample Queries

### 8.1 Execute: Accumulate a batch of closed position data

```sql
DECLARE @batch AS Hedge.CustomerClosedPositions_New
INSERT INTO @batch VALUES (1, 5, 250.50, 12.25, 10000.00)  -- InstrumentID, HedgeServerID, NetPL, Commission, Volume
EXEC Hedge.AddCustomerRealizedData @CustomerClosedPositions_New = @batch
```

### 8.2 Query: Check accumulated totals for a specific instrument and server

```sql
SELECT TOP 5
    InstrumentID,
    HedgeServerID,
    NetPL,
    CommissionOnClose,
    ExecutionVolumeInUSD,
    OccurredAt
FROM Hedge.CustomerClosedPositions_New WITH (NOLOCK)
WHERE HedgeServerID = 5 AND InstrumentID = 1
ORDER BY OccurredAt DESC
```

### 8.3 Query: Verify partition column distribution

```sql
SELECT TOP 20
    HedgeServerID,
    InstrumentID,
    PartitionCol,
    (HedgeServerID + InstrumentID) % 10 AS ExpectedPartitionCol,
    OccurredAt
FROM Hedge.CustomerClosedPositions_New WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddCustomerRealizedData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddCustomerRealizedData.sql*
