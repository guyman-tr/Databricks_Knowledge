# Trade.GetPartitionDrawDownActiveCustomers

> Returns CIDs of customers active within a date range for a specific partition shard - used by the Drawdown Calculation Service (DCS) for parallel per-partition drawdown processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PartitionId + @TotalCustomerPartitionCount - modulo-based customer sharding |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPartitionDrawDownActiveCustomers` identifies all customers who were "active" (had trading activity or open positions) within a given date range AND belong to a specific partition shard (CID % TotalPartitionCount = PartitionId). It powers the Drawdown Calculation Service (DCS), which calculates customer drawdown metrics in parallel across multiple worker processes.

**WHY:** Drawdown calculation must cover every customer who could have a drawdown - those with open positions (always active) and those who opened or closed positions in the reporting window. By partitioning by CID, multiple DCS workers can each process a subset of customers concurrently without overlap.

**HOW:** UNION of four sources (all NOLOCK, all partition-filtered with CID%N=P):
1. Customers with no open positions but with last activity in the date range (from History.LastPostionOperationDateByCID where OpenPositionExists IS NULL)
2. Customers with open positions regardless of date (OpenPositionExists = 1)
3. Customers with open positions (StatusID=1) in PositionTbl opened within the range
4. Customers with positions in History.PositionSlim opened or closed within the range

**Note (DCS-1006):** The SP was fixed to (1) use @MinDate as the lookback anchor (instead of getdate()-1 which limited history to 1 day), (2) compute @MaxDateEndOfDay = DATEADD(DAY, 1, CAST(@MaxDate AS DATE)) to include the full last day, and (3) use >= / < instead of BETWEEN for correct half-open datetime range handling.

---

## 2. Business Logic

### 2.1 Partition-Based Customer Sharding

**What:** All four UNION branches apply the same modulo partition filter to evenly distribute customers across workers.

**Columns/Parameters Involved:** `CID`, `@PartitionId`, `@TotalCustomerPartitionCount`

**Rules:**
- `WHERE CID % @TotalCustomerPartitionCount = @PartitionId`
- Worker 0 of 10 processes CIDs 0, 10, 20, ...; Worker 1 processes CIDs 1, 11, 21, ...; etc.
- Each customer belongs to exactly one partition - no overlap between workers
- @TotalCustomerPartitionCount is typically set by the DCS configuration (e.g., 10, 20, 50)

### 2.2 Four-Source Active Customer Detection

**What:** The UNION ensures no active customer is missed regardless of which source has their activity record.

**Rules:**
```
ACTIVE = TRUE when ANY of:
  1. LastPostionOperationDateByCID.OpenPositionExists IS NULL
     AND LastOperationDate in [@MinDate, @MaxDateEndOfDay)
     -> Closed-out customer who traded recently
  2. LastPostionOperationDateByCID.OpenPositionExists = 1
     -> Customer with at least one open position (always relevant for drawdown)
  3. Trade.PositionTbl.StatusID = 1
     AND Occurred in [@MinDate, @MaxDateEndOfDay)
     -> Position opened and still open within the window
  4. History.PositionSlim.OpenOccurred OR CloseOccurred in [@MinDate, @MaxDateEndOfDay)
     -> Position opened or closed within the window (including already-closed positions)
```

### 2.3 End-Of-Day Boundary Fix (DCS-1006)

**What:** @MaxDateEndOfDay ensures the full last day is included even when @MaxDate is a date (no time component).

**Columns/Parameters Involved:** `@MaxDate`, `@MaxDateEndOfDay`

**Rules:**
- `@MaxDateEndOfDay = DATEADD(DAY, 1, CAST(@MaxDate AS DATE))`
- If @MaxDate = '2024-01-07', then @MaxDateEndOfDay = '2024-01-08 00:00:00'
- All range conditions use `>= @MinDate AND < @MaxDateEndOfDay` (half-open interval)
- Avoids BETWEEN which would miss records timestamped after @MaxDate's time component

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinDate | DATETIME | NO | - | CODE-BACKED | Start of the activity window. Used as >= lower bound. Fixed in DCS-1006 to be the true start (was previously getdate()-1). |
| 2 | @MaxDate | DATETIME | NO | - | CODE-BACKED | End of the activity window (exclusive, converted to @MaxDateEndOfDay). |
| 3 | @PartitionId | INT | NO | - | CODE-BACKED | The partition shard index this worker handles. Values: 0 to @TotalCustomerPartitionCount-1. |
| 4 | @TotalCustomerPartitionCount | INT | NO | - | CODE-BACKED | Total number of partition shards. Determines modulo denominator. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID. Output - distinct customer IDs active in this partition within the date range. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.LastPostionOperationDateByCID | Lookup | Last activity date and open position flag per customer |
| CID | Trade.PositionTbl | Lookup | Open positions (StatusID=1) opened within date range |
| CID | History.PositionSlim | Lookup | Closed positions with open/close timestamps |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the Drawdown Calculation Service (DCS) workers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPartitionDrawDownActiveCustomers (procedure)
|- History.LastPostionOperationDateByCID (table) - last activity + open position flag
|- Trade.PositionTbl (table) - live open positions
|- History.PositionSlim (table) - closed position history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.LastPostionOperationDateByCID | Table | Last operation date and open position existence per CID |
| Trade.PositionTbl | Table | Open positions (StatusID=1) for the date range and partition |
| History.PositionSlim | Table | Historical open/closed positions for the date range and partition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by Drawdown Calculation Service (DCS) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CID % @TotalCustomerPartitionCount = @PartitionId | Partition routing | Horizontal sharding for parallel processing |
| @MaxDateEndOfDay = DATEADD(DAY,1,CAST(@MaxDate AS DATE)) | Date boundary | Ensures full last day is included (DCS-1006 fix) |
| >= @MinDate AND < @MaxDateEndOfDay | Range | Half-open interval to avoid BETWEEN timestamp edge cases |
| UNION (not UNION ALL) | Dedup | Removes duplicate CIDs appearing in multiple source branches |
| WITH (NOLOCK) on all tables | Performance | Dirty read acceptable - activity detection does not require consistency |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get active customers for partition 3 of 10 over a 52-week window

```sql
EXEC Trade.GetPartitionDrawDownActiveCustomers
    @MinDate = '2023-01-01',
    @MaxDate = '2023-12-31',
    @PartitionId = 3,
    @TotalCustomerPartitionCount = 10
```

### 8.2 Parallel DCS pattern - 5 workers processing all customers

```sql
-- Worker 0: @PartitionId=0, @TotalCustomerPartitionCount=5
-- Worker 1: @PartitionId=1, @TotalCustomerPartitionCount=5
-- Worker 2: @PartitionId=2, @TotalCustomerPartitionCount=5
-- Worker 3: @PartitionId=3, @TotalCustomerPartitionCount=5
-- Worker 4: @PartitionId=4, @TotalCustomerPartitionCount=5
-- Together they cover all CIDs with no overlap
```

### 8.3 Single-worker full scan (partition 0 of 1)

```sql
EXEC Trade.GetPartitionDrawDownActiveCustomers
    @MinDate = DATEADD(WEEK, -52, GETDATE()),
    @MaxDate = GETDATE(),
    @PartitionId = 0,
    @TotalCustomerPartitionCount = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Referenced Jira ticket DCS-1006 in code comments - date range fix.)

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPartitionDrawDownActiveCustomers | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPartitionDrawDownActiveCustomers.sql*
