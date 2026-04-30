# Trade.CleanupOrderForExecutionChangeLogJob

> Archives orphaned order execution change log records from Trade.OrderForExecutionChangeLog to History.OrderForExecutionChangeLog when the corresponding orders no longer exist in Trade.OrderForClose or Trade.OrderForOpen.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OrderID / ChangeLogID (identifies orphaned change log records) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CleanupOrderForExecutionChangeLogJob is a maintenance procedure that runs as part of the "[etoro - US CleanupJob]" SQL Agent job. It identifies change log records for orders that no longer exist in either the open orders (Trade.OrderForOpen) or close orders (Trade.OrderForClose) queues - meaning those orders have been fully executed and removed from active processing.

Without this cleanup, Trade.OrderForExecutionChangeLog would accumulate indefinitely as orders complete their lifecycle. This table logs every state change during order execution (status transitions, rate updates, amount changes), so it grows rapidly during high-volume trading periods.

The procedure uses EXCEPT against both OrderForClose and OrderForOpen (UNION ALL) to find orphaned OrderIDs, stages the change log records into a temp table, MERGEs them into History.OrderForExecutionChangeLog (with partition elimination on OccurredAsDate), and then DELETEs from the source table.

---

## 2. Business Logic

### 2.1 Orphan Detection Pattern

**What**: Identifies change log records whose parent orders have completed their lifecycle.

**Columns/Parameters Involved**: `OrderID`, `ChangeLogID`

**Rules**:
- An orphan is an OrderID present in Trade.OrderForExecutionChangeLog but NOT in Trade.OrderForClose AND NOT in Trade.OrderForOpen
- Uses EXCEPT against UNION ALL of both active order tables
- Covers both open and close order lifecycle completion

**Diagram**:
```
Trade.OrderForExecutionChangeLog
          |
          EXCEPT
          |
(Trade.OrderForClose UNION ALL Trade.OrderForOpen)
          |
          = Orphaned OrderIDs
          |
    +-----+-----+
    |             |
  MERGE        DELETE
    |             |
History.       Trade.
OrderFor       OrderFor
Execution      Execution
ChangeLog      ChangeLog
```

### 2.2 Archive-Then-Delete Pattern

**What**: Archives orphaned change log records to History before deleting from Trade.

**Rules**:
- MERGE key: ChangeLogID (unique per change log entry)
- Partition elimination: OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE()
- WHEN NOT MATCHED: INSERT into History
- WHEN MATCHED: UPDATE existing History record (idempotent)
- DELETE from Trade only after successful MERGE (@@ROWCOUNT > 0)

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
| OrderID, ChangeLogID | Trade.OrderForExecutionChangeLog | READ + DELETE | Source: reads orphaned change log records, deletes after archiving |
| OrderID | Trade.OrderForClose | READ | Reference: used in EXCEPT to identify still-active close orders |
| OrderID | Trade.OrderForOpen | READ | Reference: used in EXCEPT to identify still-active open orders |
| ChangeLogID | History.OrderForExecutionChangeLog | MERGE (INSERT/UPDATE) | Target: archives orphaned change log records with partition elimination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job "[etoro - US CleanupJob]" | Scheduled | EXEC | Called by the US cleanup job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CleanupOrderForExecutionChangeLogJob (procedure)
+-- Trade.OrderForExecutionChangeLog (table)
+-- Trade.OrderForClose (table)
+-- Trade.OrderForOpen (table)
+-- History.OrderForExecutionChangeLog (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForExecutionChangeLog | Table | READ (orphan detection) + DELETE (cleanup) |
| Trade.OrderForClose | Table | READ (EXCEPT reference for active close orders) |
| Trade.OrderForOpen | Table | READ (EXCEPT reference for active open orders) |
| History.OrderForExecutionChangeLog | Table | MERGE (archive destination) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job "[etoro - US CleanupJob]" (external) | Job | Scheduled execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Partition elimination | Performance | MERGE targets OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE() |
| Temp table indexes | Performance | Creates clustered indexes on #OrderIDs(OrderID) and #OrderForExecutionChangeLog(ChangeLogID) |
| TRY/CATCH | Error handling | Wraps entire flow; RAISERROR on failure |

---

## 8. Sample Queries

### 8.1 Check for orphaned execution change log records

```sql
SELECT COUNT(*) AS OrphanCount
FROM   Trade.OrderForExecutionChangeLog cl WITH (NOLOCK)
WHERE  NOT EXISTS (SELECT 1 FROM Trade.OrderForClose ofc WITH (NOLOCK) WHERE ofc.OrderID = cl.OrderID)
  AND  NOT EXISTS (SELECT 1 FROM Trade.OrderForOpen ofo WITH (NOLOCK) WHERE ofo.OrderID = cl.OrderID);
```

### 8.2 Review recent change log archival to History

```sql
SELECT TOP 10 ChangeLogID, OrderID, OrderType, StatusID, ChangeOccurred
FROM   History.OrderForExecutionChangeLog WITH (NOLOCK)
WHERE  OccurredAsDate >= CAST(GETUTCDATE() - 1 AS DATE)
ORDER BY ChangeOccurred DESC;
```

### 8.3 Check change log volume by status

```sql
SELECT StatusID, COUNT(*) AS LogCount
FROM   Trade.OrderForExecutionChangeLog WITH (NOLOCK)
GROUP BY StatusID
ORDER BY LogCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CleanupOrderForExecutionChangeLogJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CleanupOrderForExecutionChangeLogJob.sql*
