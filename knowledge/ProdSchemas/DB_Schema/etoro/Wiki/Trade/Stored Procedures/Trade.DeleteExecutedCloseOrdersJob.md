# Trade.DeleteExecutedCloseOrdersJob

> Archive-and-purge job that moves completed close order results (net profit, partial close ratios, fees, taxes) from Trade.ExecutedCloseOrders to History, then deletes from Trade.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (TVP of order IDs to archive and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteExecutedCloseOrdersJob archives close order execution results from Trade.ExecutedCloseOrders into History.ExecutedCloseOrders, then removes the archived rows from Trade. ExecutedCloseOrders stores the financial outcome of close operations - net profit, units closed, partial close ratios, fees, and taxes. After close processing is complete, these results are archived for long-term retention.

This procedure exists as part of the post-close cleanup pipeline. The financial results in ExecutedCloseOrders are needed during close processing for settlement and notification, but once complete they belong in History for reporting and audit.

Data flow: (1) Distinct OrderIDs from TVP. (2) ExecutedCloseOrders rows copied to temp table. (3) MERGE into History.ExecutedCloseOrders on OrderID+PositionID with 30-day partition elimination. (4) DELETE from Trade.ExecutedCloseOrders for archived rows.

---

## 2. Business Logic

### 2.1 Archive-Then-Delete Pattern

**What**: Safely archives close order results before deletion.

**Columns/Parameters Involved**: `@OrderIDs`, `OrderID`, `PositionID`

**Rules**:
- MERGE matches on OrderID AND PositionID (composite key - one order can close multiple positions in partial close scenarios)
- 30-day partition elimination on OccurredAsDate for History table
- All 14 financial columns preserved: OrderID, PositionID, ExecutionID, Units, NetProfit, PartialClosePositionID, PartialClosedPositionAmount, OpenPositionAmount, OpenUnits, PartialCloseRatio, OpenUnitsBaseValueInCents, Amount, CloseTotalTaxes, CloseTotalFees

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the set of OrderIDs whose close order execution results should be archived and deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT/DELETE) | Trade.ExecutedCloseOrders | READ+DELETE | Source - reads close results then deletes after archiving |
| (MERGE) | History.ExecutedCloseOrders | WRITER | Archive target via MERGE |
| (@OrderIDs) | Trade.IdIntList | Type Reference | Input parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteExecutedCloseOrdersJob (procedure)
+-- Trade.ExecutedCloseOrders (table)
+-- History.ExecutedCloseOrders (table, cross-schema)
+-- Trade.IdIntList (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedCloseOrders | Table | Source for archive - SELECT then DELETE |
| History.ExecutedCloseOrders | Table | Archive target via MERGE |
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

### 8.1 Archive close order results for specific orders

```sql
DECLARE @Orders Trade.IdIntList
INSERT INTO @Orders (Id) VALUES (200001), (200002)
EXEC Trade.DeleteExecutedCloseOrdersJob @OrderIDs = @Orders
```

### 8.2 Check pending close results

```sql
SELECT  OrderID, PositionID, NetProfit, Units, PartialCloseRatio, CloseTotalTaxes, CloseTotalFees
FROM    Trade.ExecutedCloseOrders WITH (NOLOCK)
ORDER BY OrderID DESC
```

### 8.3 Verify archival in History

```sql
SELECT  TOP 10 OrderID, PositionID, NetProfit, Units
FROM    History.ExecutedCloseOrders WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() AS DATE)
ORDER BY OrderID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteExecutedCloseOrdersJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteExecutedCloseOrdersJob.sql*
