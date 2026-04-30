# Trade.DeleteExecutionPlanChangeLogJob

> Archive-and-purge job that moves execution plan change log entries from Trade.ExecutionPlanChangeLog to History, then deletes from Trade.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (TVP of order IDs to archive and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteExecutionPlanChangeLogJob archives execution plan change log entries from Trade.ExecutionPlanChangeLog into History.ExecutionPlanChangeLog, then removes the archived rows. The change log tracks modifications to execution plans during order processing - when units, amounts, or position assignments change during the execution pipeline, those changes are recorded here for audit purposes.

This procedure exists as part of the post-order cleanup pipeline. Change log entries are diagnostic/audit data that support investigation of execution anomalies but are not needed in the hot operational table once the order is fully settled.

Data flow: (1) Distinct OrderIDs from TVP. (2) ExecutionPlanChangeLog rows copied to temp table. (3) MERGE into History.ExecutionPlanChangeLog on ChangeLogID with 30-day partition elimination. (4) DELETE from Trade.ExecutionPlanChangeLog for archived rows.

---

## 2. Business Logic

### 2.1 Archive-Then-Delete Pattern

**What**: Safely archives change log entries before deletion.

**Columns/Parameters Involved**: `@OrderIDs`, `ChangeLogID`

**Rules**:
- MERGE matches on ChangeLogID (unique identifier for each change event)
- 30-day partition elimination on OccurredAsDate for History table
- All 9 columns preserved: ChangeLogID, ChangeOccurred, OrderID, Units, Level, Amount, OpenCorrelationID, PositionID, SettlementType

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the set of OrderIDs whose execution plan change log entries should be archived and deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT/DELETE) | Trade.ExecutionPlanChangeLog | READ+DELETE | Source - reads change log entries then deletes after archiving |
| (MERGE) | History.ExecutionPlanChangeLog | WRITER | Archive target via MERGE |
| (@OrderIDs) | Trade.IdIntList | Type Reference | Input parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteExecutionPlanChangeLogJob (procedure)
+-- Trade.ExecutionPlanChangeLog (table)
+-- History.ExecutionPlanChangeLog (table, cross-schema)
+-- Trade.IdIntList (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutionPlanChangeLog | Table | Source for archive - SELECT then DELETE |
| History.ExecutionPlanChangeLog | Table | Archive target via MERGE |
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

### 8.1 Archive change log for specific orders

```sql
DECLARE @Orders Trade.IdIntList
INSERT INTO @Orders (Id) VALUES (400001), (400002)
EXEC Trade.DeleteExecutionPlanChangeLogJob @OrderIDs = @Orders
```

### 8.2 Check pending change log entries

```sql
SELECT  ChangeLogID, OrderID, PositionID, Units, Amount, ChangeOccurred
FROM    Trade.ExecutionPlanChangeLog WITH (NOLOCK)
ORDER BY ChangeOccurred DESC
```

### 8.3 Verify archival in History

```sql
SELECT  TOP 10 ChangeLogID, OrderID, Units, Amount, ChangeOccurred
FROM    History.ExecutionPlanChangeLog WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() AS DATE)
ORDER BY ChangeLogID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteExecutionPlanChangeLogJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteExecutionPlanChangeLogJob.sql*
