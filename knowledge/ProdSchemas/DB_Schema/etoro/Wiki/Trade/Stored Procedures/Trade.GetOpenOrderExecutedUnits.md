# Trade.GetOpenOrderExecutedUnits

> Native-compiled procedure that returns the total units already opened for a given execution batch, filtered by hedged or non-hedged plan nodes - used to track fill progress during position-open execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExecutionID BIGINT + @IsAggregatedHedged BIT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenOrderExecutedUnits` computes the sum of units that have already been opened (i.e., positions created) for a specific execution batch (`ExecutionID`), restricted to either the hedged or non-hedged portion of the open-execution plan. It returns a single scalar: `SUM(ExecutedOpenOrders.Units)`, or `0` if no units have been executed yet.

**WHY:** During order-for-open execution, positions may be filled partially or in multiple batches. The execution engine needs to know how many units have already been opened to decide whether the order is fully filled, partially filled, or still pending. The hedged vs non-hedged split is important because hedged positions follow a different aggregation path.

**HOW:** Called from the trading execution services during the open-order processing pipeline. After each execution attempt, the caller queries this SP to check cumulative fill progress. JOINs `ExecutedOpenOrders` to `OpenExecutionPlan` via `OpenCorrelationID` so that the `IsHedged` filter from the plan is applied to the executed results. Runs natively compiled with SNAPSHOT isolation for speed.

---

## 2. Business Logic

### 2.1 Hedged vs Non-Hedged Aggregation Split

**What:** The `@IsAggregatedHedged` flag splits the unit count into two separate aggregations: one for hedged plan nodes and one for non-hedged. This reflects that hedged positions go through a different execution path (hedge engine) and their fill tracking is separate.

**Columns/Parameters Involved:** `@IsAggregatedHedged`, `oep.IsHedged`, `eoo.Units`

**Rules:**
- `@IsAggregatedHedged = 1`: return SUM(Units) for executed units on hedged plan nodes
- `@IsAggregatedHedged = 0`: return SUM(Units) for executed units on non-hedged plan nodes
- The JOIN `eoo.OpenCorrelationID = oep.OpenCorrelationID` links each executed position back to its plan node to get the `IsHedged` flag
- Returns `ISNULL(SUM(...), 0)` - always returns 0 rather than NULL when no rows match

**Diagram:**
```
ExecutionID=X execution batch:
  OpenExecutionPlan rows: IsHedged=0 (3 nodes) + IsHedged=1 (1 node)
  ExecutedOpenOrders rows linked via OpenCorrelationID

  @IsAggregatedHedged=0 -> SUM(eoo.Units) for non-hedged nodes = total CFD units opened
  @IsAggregatedHedged=1 -> SUM(eoo.Units) for hedged nodes = total hedged units opened
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | bigint | NO | - | CODE-BACKED | Input: the execution batch ID. References Trade.ExecutedOpenOrders.ExecutionID. Groups all position opens that were processed together in one execution cycle. |
| 2 | @IsAggregatedHedged | bit | NO | - | CODE-BACKED | Input: hedge filter. 1=sum units for hedged plan nodes only; 0=sum units for non-hedged plan nodes only. Corresponds to Trade.OpenExecutionPlan.IsHedged. |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | (unnamed scalar) | decimal/numeric | NO | 0 | CODE-BACKED | SUM of Trade.ExecutedOpenOrders.Units for the given ExecutionID and IsHedged filter. Returns 0 (not NULL) if no matching rows found. Represents total units successfully opened in this execution batch for the specified hedge category. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionID | Trade.ExecutedOpenOrders | Direct query | Filters ExecutedOpenOrders by ExecutionID |
| OpenCorrelationID | Trade.OpenExecutionPlan | JOIN | Joins plan to executed orders via OpenCorrelationID to retrieve IsHedged flag |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application execution services | N/A | CALLER | Called during open-order processing to check fill progress |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenOrderExecutedUnits (procedure)
├── Trade.ExecutedOpenOrders (table)
└── Trade.OpenExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedOpenOrders | Table | SELECT SUM(Units) WHERE ExecutionID = @ExecutionID |
| Trade.OpenExecutionPlan | Table | INNER JOIN via OpenCorrelationID to filter by IsHedged |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application execution services | External | Queries fill progress during open-order processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Execution Mode:** Native compilation (`WITH NATIVE_COMPILATION, SCHEMABINDING`). `ATOMIC` block with `TRANSACTION ISOLATION LEVEL = SNAPSHOT`.

---

## 8. Sample Queries

### 8.1 Get total non-hedged units opened for an execution batch
```sql
EXEC Trade.GetOpenOrderExecutedUnits @ExecutionID = 987654321, @IsAggregatedHedged = 0
```

### 8.2 Get total hedged units opened for an execution batch
```sql
EXEC Trade.GetOpenOrderExecutedUnits @ExecutionID = 987654321, @IsAggregatedHedged = 1
```

### 8.3 Manual equivalent query - verify fill progress
```sql
SELECT ISNULL(SUM(eoo.Units), 0) AS ExecutedUnits,
       oep.IsHedged
FROM   Trade.ExecutedOpenOrders eoo WITH (NOLOCK)
       INNER JOIN Trade.OpenExecutionPlan oep WITH (NOLOCK)
           ON oep.OpenCorrelationID = eoo.OpenCorrelationID
WHERE  eoo.ExecutionID = 987654321
GROUP  BY oep.IsHedged
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenOrderExecutedUnits | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenOrderExecutedUnits.sql*
