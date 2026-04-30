# Trade.CleanupExecutedCloseOrdersJob

> Archives completed executed close orders from Trade.ExecutedCloseOrders to History.ExecutedCloseOrders using MERGE, then deletes the archived rows. Part of the US CleanupJob.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous job |
| **Partition** | History.ExecutedCloseOrders partitioned by OccurredAsDate |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CleanupExecutedCloseOrdersJob moves completed close order execution records from the hot operational table to history. An executed close order is considered "completed" when its OrderID no longer appears in Trade.OrderForClose. This procedure preserves the full execution detail including partial close information, net profit, taxes, and fees.

Part of the `[etoro - US CleanupJob]` SQL Agent job. Same archive pattern as the other cleanup procedures: EXCEPT to find completed orders, stage to temp table, MERGE to history with partition elimination, DELETE from active.

---

## 2. Business Logic

### 2.1 Completed Order Detection

**What**: Finds OrderIDs in Trade.ExecutedCloseOrders that are not in Trade.OrderForClose.

### 2.2 MERGE to History

**What**: Upserts into History.ExecutedCloseOrders with partition elimination on OccurredAsDate (last 30 days).

**Columns Archived**: OrderID, PositionID, ExecutionID, Units, NetProfit, PartialClosePositionID, PartialClosedPositionAmount, OpenPositionAmount, OpenUnits, PartialCloseRatio, OpenUnitsBaseValueInCents, Amount, CloseTotalTaxes, CloseTotalFees

### 2.3 Delete from Active

**What**: Removes archived rows from Trade.ExecutedCloseOrders after successful MERGE.

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
| (reads) | Trade.ExecutedCloseOrders | SELECT + DELETE | Source: executed close order details |
| (reads) | Trade.OrderForClose | SELECT (EXCEPT) | Reference: active close orders |
| (writes) | History.ExecutedCloseOrders | MERGE (INSERT/UPDATE) | Target: archived executed close orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [etoro - US CleanupJob] | SQL Agent Job | EXEC | Scheduled cleanup job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CleanupExecutedCloseOrdersJob (procedure)
+-- Trade.ExecutedCloseOrders (table)
+-- Trade.OrderForClose (table)
+-- History.ExecutedCloseOrders (table, partitioned)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedCloseOrders | Table | SELECT source + DELETE |
| Trade.OrderForClose | Table | EXCEPT reference |
| History.ExecutedCloseOrders | Table | MERGE target |

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
| Temp table clustered index | Performance | #ExecutedCloseOrders indexed on (OrderID, PositionID) before MERGE |
| TRY/CATCH with RAISERROR | Error handling | Captures and re-raises errors with procedure name prefix |

---

## 8. Sample Queries

### 8.1 Run the cleanup

```sql
EXEC Trade.CleanupExecutedCloseOrdersJob;
```

### 8.2 Check counts

```sql
SELECT 'Active' AS Source, COUNT(*) AS Cnt FROM Trade.ExecutedCloseOrders WITH (NOLOCK)
UNION ALL
SELECT 'History (30d)', COUNT(*) FROM History.ExecutedCloseOrders WITH (NOLOCK)
WHERE OccurredAsDate >= CAST(GETUTCDATE()-30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CleanupExecutedCloseOrdersJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CleanupExecutedCloseOrdersJob.sql*
