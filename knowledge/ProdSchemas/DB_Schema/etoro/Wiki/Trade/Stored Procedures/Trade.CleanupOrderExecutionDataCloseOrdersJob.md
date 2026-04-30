# Trade.CleanupOrderExecutionDataCloseOrdersJob

> Archives completed close-order execution data from Trade.OrderExecutionData (OrderType 19/20) to History.OrderExecutionData using MERGE, then deletes the archived rows. Part of the US CleanupJob.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous job |
| **Partition** | History.OrderExecutionData partitioned by OccurredAsDate |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CleanupOrderExecutionDataCloseOrdersJob moves completed close-specific order execution data from the hot operational table to history. Unlike the other cleanup procedures that archive entire tables, this one selectively targets rows with OrderType IN (19, 20) in Trade.OrderExecutionData, which correspond to close-related order types. A row is considered "completed" when its OrderID no longer appears in Trade.OrderForClose.

The procedure preserves execution-level detail: execution timing, rate data (discounted, spreaded, raw), and rate IDs. These records are critical for reconciliation and audit of execution quality.

Part of the `[etoro - US CleanupJob]` SQL Agent job.

---

## 2. Business Logic

### 2.1 Completed Order Detection

**What**: Finds OrderIDs with OrderType IN (19, 20) in Trade.OrderExecutionData that are not in Trade.OrderForClose.

**Rules**:
- Only targets close-related order types (19 and 20)
- Other order types remain in the active table

### 2.2 MERGE to History

**What**: Upserts into History.OrderExecutionData with partition elimination on OccurredAsDate (last 30 days).

**Columns Archived**: OrderID, ExecutionID, OrderExecutionTime, OrderType, Occurred, ExecutionRateDiscounted, ExecutionRateSpreaded, ExecutionRateID, ExecutionRate

**Match Key**: OrderID only (plus partition elimination)

### 2.3 Delete from Active

**What**: Removes archived rows from Trade.OrderExecutionData after successful MERGE.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.OrderExecutionData | SELECT + DELETE | Source: close-order execution data (OrderType 19, 20) |
| (reads) | Trade.OrderForClose | SELECT (EXCEPT) | Reference: active close orders |
| (writes) | History.OrderExecutionData | MERGE (INSERT/UPDATE) | Target: archived order execution data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [etoro - US CleanupJob] | SQL Agent Job | EXEC | Scheduled cleanup job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CleanupOrderExecutionDataCloseOrdersJob (procedure)
+-- Trade.OrderExecutionData (table)
+-- Trade.OrderForClose (table)
+-- History.OrderExecutionData (table, partitioned)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderExecutionData | Table | SELECT source + DELETE |
| Trade.OrderForClose | Table | EXCEPT reference |
| History.OrderExecutionData | Table | MERGE target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| [etoro - US CleanupJob] | SQL Agent Job | Scheduled execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OrderType filter | Selectivity | Only processes OrderType IN (19, 20) - close-related types |
| Partition elimination | Performance | History MERGE filters OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE() |
| Temp table clustered index | Performance | #closeOrderExecutionData indexed on OrderID |
| TRY/CATCH with RAISERROR | Error handling | Captures and re-raises with procedure name prefix |

---

## 8. Sample Queries

### 8.1 Run the cleanup

```sql
EXEC Trade.CleanupOrderExecutionDataCloseOrdersJob;
```

### 8.2 Check close-order execution data counts

```sql
SELECT 'Active (Type 19/20)' AS Source, COUNT(*) AS Cnt
FROM   Trade.OrderExecutionData WITH (NOLOCK) WHERE OrderType IN (19, 20)
UNION ALL
SELECT 'History (30d)', COUNT(*)
FROM   History.OrderExecutionData WITH (NOLOCK)
WHERE  OccurredAsDate >= CAST(GETUTCDATE()-30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CleanupOrderExecutionDataCloseOrdersJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CleanupOrderExecutionDataCloseOrdersJob.sql*
