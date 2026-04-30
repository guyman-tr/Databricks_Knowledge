# Trade.DeleteExecutedOpenOrdersJob

> Archive-and-purge job that moves completed open order results (execution IDs, units, tree info, correlation) from Trade.ExecutedOpenOrders to History, then deletes from Trade.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (TVP of order IDs to archive and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteExecutedOpenOrdersJob archives open order execution results from Trade.ExecutedOpenOrders into History.ExecutedOpenOrders, then removes the archived rows from Trade. ExecutedOpenOrders stores the outcome of open order processing - which position was created, how many units were filled, what adjustment ratio was applied, and the copy-trade tree context. After open order processing is complete, these records are archived for long-term retention.

This procedure exists as part of the post-open cleanup pipeline. The execution results are needed during position creation for settlement and notification, but once complete they belong in History for audit and analysis.

Data flow: (1) Distinct OrderIDs from TVP. (2) ExecutedOpenOrders rows copied to temp table. (3) MERGE into History.ExecutedOpenOrders on OrderID+PositionID+OpenCorrelationID with 30-day partition elimination. (4) DELETE from Trade.ExecutedOpenOrders for archived rows.

---

## 2. Business Logic

### 2.1 Archive-Then-Delete Pattern

**What**: Safely archives open order results before deletion.

**Columns/Parameters Involved**: `@OrderIDs`, `OrderID`, `PositionID`, `OpenCorrelationID`

**Rules**:
- MERGE matches on OrderID + PositionID + OpenCorrelationID (three-part key for uniqueness)
- 30-day partition elimination on OccurredAsDate for History table
- All 8 columns preserved: OrderID, PositionID, ExecutionID, Units, OpenCorrelationID, PostAdjustmentRatio, RequestedUnits, TreeID

### 2.2 Post-Adjustment Tracking

**What**: Captures the difference between requested and actual units for audit.

**Columns/Parameters Involved**: `Units`, `RequestedUnits`, `PostAdjustmentRatio`

**Rules**:
- RequestedUnits: what the order originally asked for
- Units: what was actually filled
- PostAdjustmentRatio: the adjustment factor applied (e.g., for copy-trade proportioning)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the set of OrderIDs whose open order execution results should be archived and deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT/DELETE) | Trade.ExecutedOpenOrders | READ+DELETE | Source - reads open results then deletes after archiving |
| (MERGE) | History.ExecutedOpenOrders | WRITER | Archive target via MERGE |
| (@OrderIDs) | Trade.IdIntList | Type Reference | Input parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteExecutedOpenOrdersJob (procedure)
+-- Trade.ExecutedOpenOrders (table)
+-- History.ExecutedOpenOrders (table, cross-schema)
+-- Trade.IdIntList (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedOpenOrders | Table | Source for archive - SELECT then DELETE |
| History.ExecutedOpenOrders | Table | Archive target via MERGE |
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

### 8.1 Archive open order results for specific orders

```sql
DECLARE @Orders Trade.IdIntList
INSERT INTO @Orders (Id) VALUES (300001), (300002)
EXEC Trade.DeleteExecutedOpenOrdersJob @OrderIDs = @Orders
```

### 8.2 Check pending open order results

```sql
SELECT  OrderID, PositionID, Units, RequestedUnits, PostAdjustmentRatio, TreeID
FROM    Trade.ExecutedOpenOrders WITH (NOLOCK)
ORDER BY OrderID DESC
```

### 8.3 Verify archival in History

```sql
SELECT  TOP 10 OrderID, PositionID, Units, TreeID, OpenCorrelationID
FROM    History.ExecutedOpenOrders WITH (NOLOCK)
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
*Object: Trade.DeleteExecutedOpenOrdersJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteExecutedOpenOrdersJob.sql*
