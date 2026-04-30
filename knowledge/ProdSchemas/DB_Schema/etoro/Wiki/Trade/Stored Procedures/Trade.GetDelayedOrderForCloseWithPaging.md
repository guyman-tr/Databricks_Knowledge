# Trade.GetDelayedOrderForCloseWithPaging

> Natively compiled procedure that reads delayed close orders with cursor-based paging, grouping by OrderID and returning all detail rows per order batch.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure (Natively Compiled) |
| **Key Identifier** | @RequestIdentifier + @LastUpdate + @StatusID (paging cursor) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDelayedOrderForCloseWithPaging is a natively compiled procedure that reads delayed close orders from the Trade.DelayedOrderForClose memory-optimized table using cursor-based pagination. It returns a batch of orders grouped by OrderID, where each order may have multiple position-level detail rows. The Dreq (Delayed Request) service uses this to poll for pending close operations.

This procedure exists because the delayed order processing service needs to consume close orders in controlled batches. Memory-optimized table access with SNAPSHOT isolation ensures minimal contention with the order insertion path. The paging mechanism uses RequestIdentifier and LastUpdate as a cursor to resume from where the last read left off.

Data flows from Trade.DelayedOrderForClose, first aggregated by OrderID (TOP @MaxRead groups) to form the page boundary, then self-joined to return all detail rows for each OrderID in the batch.

---

## 2. Business Logic

### 2.1 Cursor-Based Paging

**What**: Uses RequestIdentifier and LastUpdate as a compound cursor for resumable batch reads.

**Columns/Parameters Involved**: `@RequestIdentifier`, `@LastUpdate`, `@MaxRead`, `@StatusID`

**Rules**:
- When @LastUpdate IS NULL or equals the current row's LastUpdate: advance by RequestIdentifier > @RequestIdentifier
- When LastUpdate > @LastUpdate: all rows with later LastUpdate qualify (handles time-based advancement)
- Combined with StatusID = @StatusID filter (typically StatusID=1 for pending)
- GROUP BY OrderID with TOP(@MaxRead) limits the number of order groups returned
- STRING_AGG(PositionID, ',') concatenates all position IDs per order for the summary row

### 2.2 Order-Level Grouping

**What**: Groups delayed close requests by OrderID, then returns full detail per order.

**Columns/Parameters Involved**: `OrderID`, `MaxRequestIdentifier`, `PositionIDs`, `MaxLastUpdate`

**Rules**:
- Inner subquery groups by OrderID and aggregates: MAX(RequestIdentifier), STRING_AGG(PositionID), MAX(LastUpdate)
- Outer join back to DelayedOrderForClose on MaxRequestIdentifier retrieves the canonical detail row
- This pattern ensures one "header" (grouped) row per order plus full detail

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestIdentifier | bigint | NO | - | CODE-BACKED | Cursor position: last processed RequestIdentifier. Pass 0 on first call. |
| 2 | @LastUpdate | datetime | YES | NULL | CODE-BACKED | Cursor position: last processed LastUpdate timestamp. NULL on first call. |
| 3 | @MaxRead | int | NO | - | CODE-BACKED | Maximum number of order groups to return per batch. |
| 4 | @StatusID | int | NO | - | CODE-BACKED | Filter to specific order status (typically 1=pending). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID (grouped) | int | NO | - | CODE-BACKED | Order group identifier (from subquery). |
| 2 | MaxRequestIdentifier | bigint | NO | - | CODE-BACKED | Highest RequestIdentifier in this order group. |
| 3 | PositionIDs | nvarchar(max) | YES | - | CODE-BACKED | Comma-separated list of all PositionIDs in this order. Via STRING_AGG. |
| 4 | MaxLastUpdate | datetime | YES | - | CODE-BACKED | Latest LastUpdate in this order group. |
| 5 | RequestIdentifier | bigint | NO | - | CODE-BACKED | Detail row's request identifier. |
| 6 | OrderID | int | NO | - | CODE-BACKED | Detail row's order ID. |
| 7 | OriginalOrderID | int | YES | - | CODE-BACKED | Original order ID if this is a retry/resubmission. |
| 8 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 9 | PositionID | bigint | NO | - | CODE-BACKED | Position to be closed. |
| 10 | InstrumentID | int | NO | - | CODE-BACKED | Instrument of the position. |
| 11 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the close request was created. |
| 12 | LastUpdate | datetime | YES | - | CODE-BACKED | Last update timestamp for paging cursor. |
| 13 | ActionType | int | YES | - | CODE-BACKED | Close action type (manual, SL, TP, etc.). |
| 14 | StatusID | int | NO | - | CODE-BACKED | Current status of this delayed order row. |
| 15 | RequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Unique GUID for request deduplication. |
| 16 | UnitsToDeduct | decimal | YES | - | CODE-BACKED | Units to deduct for partial close. NULL for full close. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| * | Trade.DelayedOrderForClose | FROM + self-JOIN | Memory-optimized delayed close orders table |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDelayedOrderForCloseWithPaging (procedure)
+-- Trade.DelayedOrderForClose (table, memory-optimized)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DelayedOrderForClose | Table (memory-optimized) | FROM + self-JOIN for paged reads |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by Dreq service (application layer) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- **Natively compiled** with SCHEMABINDING
- ATOMIC with SNAPSHOT isolation
- Language: us_english

---

## 8. Sample Queries

### 8.1 First batch read of pending close orders

```sql
EXEC Trade.GetDelayedOrderForCloseWithPaging
    @RequestIdentifier = 0,
    @LastUpdate = NULL,
    @MaxRead = 100,
    @StatusID = 1;
```

### 8.2 Resume from a previous batch

```sql
EXEC Trade.GetDelayedOrderForCloseWithPaging
    @RequestIdentifier = 50042,
    @LastUpdate = '2026-03-16 10:00:00',
    @MaxRead = 100,
    @StatusID = 1;
```

### 8.3 Direct query for pending delayed closes

```sql
SELECT  OrderID, COUNT(*) AS PositionCount, MAX(RequestIdentifier) AS MaxReqId
FROM    Trade.DelayedOrderForClose WITH (NOLOCK)
WHERE   StatusID = 1
GROUP BY OrderID
ORDER BY MAX(RequestIdentifier);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDelayedOrderForCloseWithPaging | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDelayedOrderForCloseWithPaging.sql*
