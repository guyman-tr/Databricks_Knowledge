# Trade.CleanUpExecutedOpenOrdersJob

> Archives completed executed open orders from Trade.ExecutedOpenOrders to History.ExecutedOpenOrders using MERGE, then deletes the archived rows. Part of the US CleanupJob.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous job |
| **Partition** | History.ExecutedOpenOrders partitioned by OccurredAsDate |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CleanUpExecutedOpenOrdersJob moves completed open order execution records from the hot operational table to history. An executed open order is considered "completed" when its OrderID no longer appears in Trade.OrderForOpen (the pending open orders queue). This preserves the full execution detail including units, correlation IDs, post-adjustment ratios, and tree IDs.

Part of the `[etoro - US CleanupJob]` SQL Agent job. Same archive pattern: EXCEPT to find completed orders, stage to temp table, MERGE to history with partition elimination, DELETE from active.

---

## 2. Business Logic

### 2.1 Completed Order Detection

**What**: Finds OrderIDs in Trade.ExecutedOpenOrders that are not in Trade.OrderForOpen.

### 2.2 MERGE to History

**What**: Upserts into History.ExecutedOpenOrders with partition elimination on OccurredAsDate (last 30 days).

**Columns Archived**: OrderID, PositionID, ExecutionID, Units, OpenCorrelationID, PostAdjustmentRatio, RequestedUnits, TreeID

**Match Key**: OrderID + PositionID + OpenCorrelationID (three-part match ensures uniqueness for partial fills)

### 2.3 Delete from Active

**What**: Removes archived rows from Trade.ExecutedOpenOrders after successful MERGE.

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
| (reads) | Trade.ExecutedOpenOrders | SELECT + DELETE | Source: executed open order details |
| (reads) | Trade.OrderForOpen | SELECT (EXCEPT) | Reference: active open orders |
| (writes) | History.ExecutedOpenOrders | MERGE (INSERT/UPDATE) | Target: archived executed open orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [etoro - US CleanupJob] | SQL Agent Job | EXEC | Scheduled cleanup job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CleanUpExecutedOpenOrdersJob (procedure)
+-- Trade.ExecutedOpenOrders (table)
+-- Trade.OrderForOpen (table)
+-- History.ExecutedOpenOrders (table, partitioned)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedOpenOrders | Table | SELECT source + DELETE |
| Trade.OrderForOpen | Table | EXCEPT reference |
| History.ExecutedOpenOrders | Table | MERGE target |

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
| Partition elimination | Performance | History MERGE filters OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE() |
| Nonclustered index on temp | Performance | #ExecutedOpenOrders uses nonclustered index on OrderID (not clustered) |
| Three-part MERGE match | Uniqueness | OrderID + PositionID + OpenCorrelationID ensures partial fill uniqueness |
| TRY/CATCH with RAISERROR | Error handling | Captures and re-raises with procedure name prefix |

---

## 8. Sample Queries

### 8.1 Run the cleanup

```sql
EXEC Trade.CleanUpExecutedOpenOrdersJob;
```

### 8.2 Check counts

```sql
SELECT 'Active' AS Source, COUNT(*) AS Cnt FROM Trade.ExecutedOpenOrders WITH (NOLOCK)
UNION ALL
SELECT 'History (30d)', COUNT(*) FROM History.ExecutedOpenOrders WITH (NOLOCK)
WHERE OccurredAsDate >= CAST(GETUTCDATE()-30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CleanUpExecutedOpenOrdersJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CleanUpExecutedOpenOrdersJob.sql*
