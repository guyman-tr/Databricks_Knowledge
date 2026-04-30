# Trade.CleanupCloseExecutionPlanJob

> Archives completed close execution plans from Trade.CloseExecutionPlan to History.CloseExecutionPlan using MERGE, then deletes the archived rows from the active table. Part of the US CleanupJob.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous job |
| **Partition** | History.CloseExecutionPlan partitioned by OccurredAsDate |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CleanupCloseExecutionPlanJob is one of several cleanup procedures called by the `[etoro - US CleanupJob]` SQL Agent job. It moves completed close execution plan records from the hot operational table (Trade.CloseExecutionPlan) to the history table (History.CloseExecutionPlan), keeping the active table small for performance.

A close execution plan row is considered "completed" when its OrderID no longer exists in Trade.OrderForClose (the pending close orders queue). The procedure uses an EXCEPT pattern to identify completed orders, stages them in a temp table with a clustered index, then uses MERGE to upsert into History with partition elimination (OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE()), and finally DELETEs the staged rows from the active table.

---

## 2. Business Logic

### 2.1 Completed Order Detection

**What**: Finds OrderIDs that exist in Trade.CloseExecutionPlan but NOT in Trade.OrderForClose.

**Rules**:
- EXCEPT pattern: SELECT OrderID FROM Trade.CloseExecutionPlan EXCEPT SELECT OrderID FROM Trade.OrderForClose
- These are orders whose close has fully completed and no longer need to be in the hot table

### 2.2 Stage to Temp Table

**What**: Copies the completed rows into #CloseExecutionPlan with a clustered index for efficient MERGE.

**Columns**: OrderID, PositionID, Units, Level, CID, CloseActionType, IsHedged

### 2.3 MERGE to History

**What**: Upserts staged data into History.CloseExecutionPlan.

**Rules**:
- Match on OrderID + PositionID + OccurredAsDate partition elimination (last 30 days)
- NOT MATCHED: INSERT new rows
- MATCHED: UPDATE existing rows (handles re-processing)

### 2.4 Delete from Active

**What**: Removes archived rows from Trade.CloseExecutionPlan.

**Rules**:
- Only deletes if MERGE affected rows (@@ROWCOUNT > 0)
- JOIN delete on OrderID

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
| (reads) | Trade.CloseExecutionPlan | SELECT + DELETE | Source: completed close execution plans |
| (reads) | Trade.OrderForClose | SELECT (EXCEPT) | Reference: active close orders |
| (writes) | History.CloseExecutionPlan | MERGE (INSERT/UPDATE) | Target: archived close execution plans |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [etoro - US CleanupJob] | SQL Agent Job | EXEC | Scheduled cleanup job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CleanupCloseExecutionPlanJob (procedure)
+-- Trade.CloseExecutionPlan (table)
+-- Trade.OrderForClose (table)
+-- History.CloseExecutionPlan (table, partitioned)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseExecutionPlan | Table | SELECT source + DELETE |
| Trade.OrderForClose | Table | EXCEPT reference |
| History.CloseExecutionPlan | Table | MERGE target |

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
| Temp table clustered index | Performance | #CloseExecutionPlan indexed on (OrderID, PositionID) before MERGE |
| TRY/CATCH with RAISERROR | Error handling | Captures and re-raises errors with procedure name prefix |

---

## 8. Sample Queries

### 8.1 Run the cleanup

```sql
EXEC Trade.CleanupCloseExecutionPlanJob;
```

### 8.2 Check pending vs completed close execution plans

```sql
SELECT 'Active' AS Source, COUNT(*) AS Cnt FROM Trade.CloseExecutionPlan WITH (NOLOCK)
UNION ALL
SELECT 'Pending Orders', COUNT(*) FROM Trade.OrderForClose WITH (NOLOCK)
UNION ALL
SELECT 'History (30d)', COUNT(*) FROM History.CloseExecutionPlan WITH (NOLOCK)
WHERE OccurredAsDate >= CAST(GETUTCDATE()-30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CleanupCloseExecutionPlanJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CleanupCloseExecutionPlanJob.sql*
