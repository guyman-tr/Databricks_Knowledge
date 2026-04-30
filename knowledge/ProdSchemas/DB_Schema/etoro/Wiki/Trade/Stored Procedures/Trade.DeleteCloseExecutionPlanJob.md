# Trade.DeleteCloseExecutionPlanJob

> Archive-and-purge job that moves completed close execution plan rows from Trade.CloseExecutionPlan to History.CloseExecutionPlan, then deletes the source rows.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (TVP of order IDs to archive and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteCloseExecutionPlanJob archives close execution plan records from the hot Trade.CloseExecutionPlan table into History.CloseExecutionPlan and then removes them from Trade. The close execution plan details how a position close order was decomposed (which positions to close, at what units, for which CID, whether hedged), and once the order is complete these records are no longer needed in the operational table.

This procedure exists as part of the post-close cleanup pipeline. After close orders are fully processed, a batch job passes the completed OrderIDs into this procedure to move the execution plan data to the History schema for long-term retention while keeping the Trade table lean for real-time operations.

Data flow: (1) Distinct OrderIDs extracted from the TVP. (2) Close execution plan rows are copied to a temp table. (3) MERGE into History.CloseExecutionPlan (INSERT if new, UPDATE if exists) with 30-day partition elimination on OccurredAsDate. (4) DELETE from Trade.CloseExecutionPlan for successfully archived rows. Error handling wraps the entire operation with a descriptive error message.

---

## 2. Business Logic

### 2.1 Archive-Then-Delete Pattern

**What**: Safely moves data from Trade to History using MERGE before deletion.

**Columns/Parameters Involved**: `@OrderIDs`, `OrderID`, `PositionID`

**Rules**:
- MERGE uses Source.OrderID = Target.OrderID AND Source.PositionID = Target.PositionID as the match key
- Partition elimination: Target.OccurredAsDate BETWEEN GETUTCDATE()-30 AND GETUTCDATE()
- INSERT when NOT MATCHED, UPDATE when MATCHED (idempotent - re-running is safe)
- DELETE only executes after successful MERGE (@@ROWCOUNT > 0 guard)

### 2.2 TVP Input Pattern

**What**: Order IDs are passed as a table-valued parameter for batch processing.

**Columns/Parameters Involved**: `@OrderIDs`

**Rules**:
- Uses Trade.IdIntList TVP type (contains Id column)
- DISTINCT applied to handle duplicate OrderIDs in the input
- Temp table #OrderIDs created with index for efficient JOIN during copy phase

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the set of OrderIDs whose close execution plan rows should be archived and deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Trade.CloseExecutionPlan | READ+DELETE | Reads execution plan rows for the given OrderIDs, then deletes after archiving |
| (MERGE) | History.CloseExecutionPlan | WRITER | Archives rows via MERGE (INSERT or UPDATE) |
| (@OrderIDs) | Trade.IdIntList | Type Reference | Uses this user-defined table type for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteCloseExecutionPlanJob (procedure)
+-- Trade.CloseExecutionPlan (table)
+-- History.CloseExecutionPlan (table, cross-schema)
+-- Trade.IdIntList (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseExecutionPlan | Table | Source for archive - SELECT then DELETE |
| History.CloseExecutionPlan | Table | Archive target via MERGE |
| Trade.IdIntList | User Defined Type | Input parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Archive close execution plans for specific orders

```sql
DECLARE @Orders Trade.IdIntList
INSERT INTO @Orders (Id) VALUES (100001), (100002), (100003)
EXEC Trade.DeleteCloseExecutionPlanJob @OrderIDs = @Orders
```

### 8.2 Check rows pending archival

```sql
SELECT  OrderID, COUNT(*) AS PlanRows
FROM    Trade.CloseExecutionPlan WITH (NOLOCK)
GROUP BY OrderID
ORDER BY OrderID
```

### 8.3 Verify archival in History

```sql
SELECT  TOP 10 OrderID, PositionID, Units, CloseActionType, IsHedged
FROM    History.CloseExecutionPlan WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() AS DATE)
ORDER BY OrderID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteCloseExecutionPlanJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteCloseExecutionPlanJob.sql*
