# Trade.DeleteCloseOrderExecutionData

> Archive-and-purge job that moves close order execution data (rates, timestamps, execution IDs) from Trade to History, then deletes the source rows.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (TVP of order IDs to archive and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteCloseOrderExecutionData archives order execution metadata (execution rates, timestamps, order types) from Trade.OrderExecutionData into History.OrderExecutionData, then removes the archived rows from Trade. This data tracks the technical details of how each close order was executed: execution rate, any rate discounts/spreads, execution timing, and the execution engine's reference ID.

This procedure exists as part of the post-close cleanup pipeline. Once close orders are fully settled, the execution metadata is no longer needed in the hot operational table. Archiving preserves the audit trail in History while keeping Trade.OrderExecutionData small for real-time operations.

Data flow: (1) Distinct OrderIDs extracted from the TVP. (2) OrderExecutionData rows for those orders copied to temp table. (3) MERGE into History.OrderExecutionData (INSERT if new, UPDATE if exists) with 30-day partition elimination. (4) DELETE from Trade.OrderExecutionData for archived rows.

---

## 2. Business Logic

### 2.1 Archive-Then-Delete Pattern

**What**: Safely moves execution data from Trade to History using MERGE before deletion.

**Columns/Parameters Involved**: `@OrderIDs`, `OrderID`

**Rules**:
- MERGE matches on Source.OrderID = Target.OrderID with partition elimination on OccurredAsDate
- INSERT when NOT MATCHED, UPDATE when MATCHED (idempotent)
- DELETE only after successful MERGE (@@ROWCOUNT > 0 guard)
- Error handling with descriptive message prefix "Proc Trade.DeleteCloseOrderExecutionData Failed"

### 2.2 Execution Rate Columns

**What**: Captures the full execution rate breakdown for audit and analysis.

**Columns/Parameters Involved**: `ExecutionRate`, `ExecutionRateDiscounted`, `ExecutionRateSpreaded`, `ExecutionRateID`

**Rules**:
- ExecutionRate: the raw execution price
- ExecutionRateDiscounted: rate after any discount applied
- ExecutionRateSpreaded: rate after spread adjustment
- ExecutionRateID: reference to the rate provider/engine
- All rate columns preserved in History for post-trade analysis

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the set of OrderIDs whose execution data should be archived and deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Trade.OrderExecutionData | READ+DELETE | Reads execution data for the given OrderIDs, then deletes after archiving |
| (MERGE) | History.OrderExecutionData | WRITER | Archives rows via MERGE (INSERT or UPDATE) |
| (@OrderIDs) | Trade.IdIntList | Type Reference | Uses this user-defined table type for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteCloseOrderExecutionData (procedure)
+-- Trade.OrderExecutionData (table)
+-- History.OrderExecutionData (table, cross-schema)
+-- Trade.IdIntList (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderExecutionData | Table | Source for archive - SELECT then DELETE |
| History.OrderExecutionData | Table | Archive target via MERGE |
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

### 8.1 Archive execution data for specific orders

```sql
DECLARE @Orders Trade.IdIntList
INSERT INTO @Orders (Id) VALUES (100001), (100002)
EXEC Trade.DeleteCloseOrderExecutionData @OrderIDs = @Orders
```

### 8.2 Check pending execution data

```sql
SELECT  OrderID, ExecutionID, OrderType, ExecutionRate, ExecutionRateDiscounted
FROM    Trade.OrderExecutionData WITH (NOLOCK)
ORDER BY Occurred DESC
```

### 8.3 Verify archival in History

```sql
SELECT  TOP 10 OrderID, ExecutionID, ExecutionRate, Occurred
FROM    History.OrderExecutionData WITH (NOLOCK)
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
*Object: Trade.DeleteCloseOrderExecutionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteCloseOrderExecutionData.sql*
