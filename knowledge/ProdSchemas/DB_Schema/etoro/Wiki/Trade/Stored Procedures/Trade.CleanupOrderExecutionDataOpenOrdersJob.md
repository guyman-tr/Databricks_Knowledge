# Trade.CleanupOrderExecutionDataOpenOrdersJob

> Archives orphaned open-order execution data from Trade.OrderExecutionData to History.OrderExecutionData when the corresponding orders no longer exist in Trade.OrderForOpen.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OrderID (identifies orphaned execution records) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CleanupOrderExecutionDataOpenOrdersJob is a maintenance/cleanup procedure that runs as a scheduled SQL Agent job. It identifies execution data records for open orders (OrderType 17 or 18) where the corresponding order no longer exists in the Trade.OrderForOpen table - meaning the order has been fully processed, cancelled, or otherwise removed from the active orders queue.

Without this cleanup, Trade.OrderExecutionData would grow unbounded as completed/cancelled open orders leave behind orphaned execution records. This would degrade query performance on what is a high-volume table used during active trading.

The procedure uses an EXCEPT pattern to find orphaned OrderIDs, stages them into a temp table, MERGEs them into History.OrderExecutionData (using partition elimination on OccurredAsDate for the last 30 days), and then DELETEs the original records from Trade.OrderExecutionData. The entire flow is wrapped in TRY/CATCH.

---

## 2. Business Logic

### 2.1 Orphan Detection Pattern

**What**: Identifies execution records whose parent orders have been removed from the active open-orders queue.

**Columns/Parameters Involved**: `OrderID`, `OrderType`

**Rules**:
- Only considers OrderType IN (17, 18) - open order execution types
- An orphan is an OrderID present in Trade.OrderExecutionData but NOT in Trade.OrderForOpen
- Uses EXCEPT for set-based orphan detection

**Diagram**:
```
Trade.OrderExecutionData (OrderType 17,18)
          |
          EXCEPT
          |
Trade.OrderForOpen
          |
          = Orphaned OrderIDs
          |
    +-----+-----+
    |             |
  MERGE        DELETE
    |             |
History.       Trade.
OrderExecution OrderExecution
Data           Data
```

### 2.2 Archive-Then-Delete Pattern

**What**: Archives orphaned records to History before deleting from Trade.

**Rules**:
- Uses MERGE with partition elimination on OccurredAsDate (last 30 days) for History table
- WHEN NOT MATCHED: INSERT new historical record
- WHEN MATCHED: UPDATE existing historical record (idempotent re-runs)
- Only DELETEs from Trade after successful MERGE (@@ROWCOUNT > 0 check)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure has no parameters. It operates on a fixed set of tables using internal logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderExecutionData | READ + DELETE | Source table: reads orphaned open-order execution records (OrderType 17,18), deletes after archiving |
| OrderID | Trade.OrderForOpen | READ | Reference table: used in EXCEPT to identify orphaned OrderIDs |
| OrderID | History.OrderExecutionData | MERGE (INSERT/UPDATE) | Target table: archives orphaned execution records with partition elimination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled | EXEC | Called by a scheduled cleanup job (not defined in SSDT) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CleanupOrderExecutionDataOpenOrdersJob (procedure)
+-- Trade.OrderExecutionData (table)
+-- Trade.OrderForOpen (table)
+-- History.OrderExecutionData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderExecutionData | Table | READ (orphan detection) + DELETE (cleanup) |
| Trade.OrderForOpen | Table | READ (EXCEPT reference for active orders) |
| History.OrderExecutionData | Table | MERGE (archive destination) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job (external) | Job | Scheduled execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Partition elimination | Performance | MERGE targets OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE() to limit History table scan |
| Temp table indexes | Performance | Creates clustered index on #OrderIDs(OrderID) and nonclustered on #OpenOrderExecutionData(OrderID) |
| TRY/CATCH | Error handling | Wraps entire flow; RAISERROR on failure |

---

## 8. Sample Queries

### 8.1 Check for orphaned open-order execution records

```sql
SELECT COUNT(*) AS OrphanCount
FROM   Trade.OrderExecutionData oed WITH (NOLOCK)
WHERE  oed.OrderType IN (17, 18)
  AND  NOT EXISTS (SELECT 1 FROM Trade.OrderForOpen ofo WITH (NOLOCK) WHERE ofo.OrderID = oed.OrderID);
```

### 8.2 Review recent archival activity in History

```sql
SELECT TOP 10 OrderID, OrderType, Occurred, OrderExecutionTime
FROM   History.OrderExecutionData WITH (NOLOCK)
WHERE  OccurredAsDate >= CAST(GETUTCDATE() - 1 AS DATE)
ORDER BY Occurred DESC;
```

### 8.3 Check execution data distribution by OrderType

```sql
SELECT OrderType, COUNT(*) AS RecordCount
FROM   Trade.OrderExecutionData WITH (NOLOCK)
GROUP BY OrderType
ORDER BY RecordCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CleanupOrderExecutionDataOpenOrdersJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CleanupOrderExecutionDataOpenOrdersJob.sql*
