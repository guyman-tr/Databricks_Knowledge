# Trade.IdIntList

> A table-valued parameter type for passing batches of bigint IDs to stored procedures, enabling efficient set-based operations instead of row-by-row processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Id (bigint) - clustered PK |
| **Partition** | N/A |
| **Indexes** | Clustered PK on Id |

---

## 1. Business Meaning

Trade.IdIntList is a generic table-valued parameter (TVP) type used across the Trade schema to pass batches of bigint identifiers into stored procedures. Rather than issuing individual calls for each ID, callers populate an IdIntList with all the IDs they need to process and pass it as a single READONLY parameter - enabling efficient set-based filtering via JOINs inside the procedure.

This type exists because many Trade operations - order processing, execution plan cleanup, data API exports, BSL message acknowledgment - need to act on sets of IDs simultaneously. Without it, each operation would require either dynamic SQL with comma-delimited strings or repeated single-ID calls, both of which are slower and less safe.

Application services populate this type with position IDs, order IDs, execution plan IDs, or other bigint identifiers, then pass it to stored procedures that JOIN against it to filter their working set. The clustered primary key on Id ensures efficient lookups and prevents duplicate entries.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type used purely as a parameter container.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers - they hold data only during procedure execution.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Generic bigint identifier. The meaning depends on the consuming procedure: position IDs (GetPositionsForDataApi, GetPositionsChangesForDataApi), order IDs (OrderForOpenJob, OrderForCloseJob), execution plan IDs (DeleteCloseExecutionPlanJob, DeleteOpenExecutionPlanJob), or other bigint entity IDs. Clustered PK with IGNORE_DUP_KEY=OFF enforces uniqueness. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a generic container type - the semantic meaning of Id is determined by the consuming procedure.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForDataApi | @PositionIDs | Parameter (TVP) | Filters positions by a set of IDs for data API export |
| Trade.GetPositionsChangesForDataApi | @PositionIDs | Parameter (TVP) | Filters position changes by a set of IDs for data API export |
| Trade.GetAggregatedPositionsForDataApi | @PositionIDs | Parameter (TVP) | Filters aggregated position data by a set of IDs |
| Trade.GetPositionsBreakdownForDataApi | @PositionIDs | Parameter (TVP) | Filters position breakdown data by a set of IDs |
| Trade.GetOrdersForDataApi | @OrderIDs | Parameter (TVP) | Filters orders by a set of IDs for data API export |
| Trade.OrderForOpenJob | @OrderIDs | Parameter (TVP) | Batch processes open order job items |
| Trade.OrderForCloseJob | @OrderIDs | Parameter (TVP) | Batch processes close order job items |
| Trade.DeleteCloseExecutionPlanJob | @IDs | Parameter (TVP) | Bulk deletes close execution plan entries |
| Trade.DeleteOpenExecutionPlanJob | @IDs | Parameter (TVP) | Bulk deletes open execution plan entries |
| Trade.DeleteExecutedOpenOrdersJob | @IDs | Parameter (TVP) | Bulk deletes executed open order records |
| Trade.DeleteExecutedCloseOrdersJob | @IDs | Parameter (TVP) | Bulk deletes executed close order records |
| Trade.DeleteExecutionPlanChangeLogJob | @IDs | Parameter (TVP) | Bulk deletes execution plan change log entries |
| Trade.DeleteOrderForExecutionChangeLogJob | @IDs | Parameter (TVP) | Bulk deletes order execution change log entries |
| Trade.DeleteCloseOrderExecutionData | @IDs | Parameter (TVP) | Bulk deletes close order execution data |
| Trade.DeleteOpenOrderExecutionData | @IDs | Parameter (TVP) | Bulk deletes open order execution data |
| Trade.AcknowledgeMessagesBSL | @IDs | Parameter (TVP) | Acknowledges processed BSL messages by ID |
| Trade.AcknowledgeMessagesBSLTest | @IDs | Parameter (TVP) | Test version of BSL message acknowledgment |
| Trade.GenerateCloseMultiplePositionsList | @PositionIDs | Parameter (TVP) | Generates close orders for multiple positions at once |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForDataApi | Stored Procedure | READONLY parameter for batch position filtering |
| Trade.GetPositionsChangesForDataApi | Stored Procedure | READONLY parameter for batch position filtering |
| Trade.GetAggregatedPositionsForDataApi | Stored Procedure | READONLY parameter for batch position filtering |
| Trade.GetPositionsBreakdownForDataApi | Stored Procedure | READONLY parameter for batch position filtering |
| Trade.GetOrdersForDataApi | Stored Procedure | READONLY parameter for batch order filtering |
| Trade.OrderForOpenJob | Stored Procedure | READONLY parameter for batch order processing |
| Trade.OrderForCloseJob | Stored Procedure | READONLY parameter for batch order processing |
| Trade.DeleteCloseExecutionPlanJob | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.DeleteOpenExecutionPlanJob | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.DeleteExecutedOpenOrdersJob | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.DeleteExecutedCloseOrdersJob | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.DeleteExecutionPlanChangeLogJob | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.DeleteOrderForExecutionChangeLogJob | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.DeleteCloseOrderExecutionData | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.DeleteOpenOrderExecutionData | Stored Procedure | READONLY parameter for bulk deletion |
| Trade.AcknowledgeMessagesBSL | Stored Procedure | READONLY parameter for batch acknowledgment |
| Trade.GenerateCloseMultiplePositionsList | Stored Procedure | READONLY parameter for batch close generation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | IGNORE_DUP_KEY = OFF - duplicate IDs are rejected, ensuring each ID is processed exactly once |

---

## 8. Sample Queries

### 8.1 Declare and populate an IdIntList for use as a procedure parameter

```sql
DECLARE @IDs Trade.IdIntList;
INSERT INTO @IDs (Id) VALUES (100001), (100002), (100003);
EXEC Trade.GetPositionsForDataApi @PositionIDs = @IDs;
```

### 8.2 Use IdIntList to bulk-delete execution plan entries

```sql
DECLARE @PlanIDs Trade.IdIntList;
INSERT INTO @PlanIDs (Id)
SELECT  CloseExecutionPlanID
FROM    Trade.CloseExecutionPlan WITH (NOLOCK)
WHERE   CreateDate < DATEADD(DAY, -30, GETUTCDATE());

EXEC Trade.DeleteCloseExecutionPlanJob @IDs = @PlanIDs;
```

### 8.3 Use IdIntList to batch-acknowledge BSL messages

```sql
DECLARE @MsgIDs Trade.IdIntList;
INSERT INTO @MsgIDs (Id)
SELECT  TOP 1000 MessageID
FROM    Trade.ManageBSL WITH (NOLOCK)
WHERE   Status = 2;

EXEC Trade.AcknowledgeMessagesBSL @IDs = @MsgIDs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 18 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IdIntList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.IdIntList.sql*
