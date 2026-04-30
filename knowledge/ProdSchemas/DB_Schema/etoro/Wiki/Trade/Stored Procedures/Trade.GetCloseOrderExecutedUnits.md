# Trade.GetCloseOrderExecutedUnits

> Returns the total units already executed for a close order, filtered by hedge aggregation status, used to track partial execution progress in the position close flow.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns SUM of executed close units by ExecutionID and hedge status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This natively compiled procedure calculates how many units have already been executed for a given close execution, segmented by whether the positions are hedged or non-hedged. During the close flow, positions may be closed in batches - this procedure tracks execution progress to determine how many units remain to be processed.

It exists because close operations can span multiple execution rounds (especially in copy-trading trees with many levels). The system needs to know the cumulative units already closed to avoid over-execution and to track progress through the close plan.

Data flows from Trade.ExecutedCloseOrders (which records completed close executions) joined with Trade.CloseExecutionPlan (which categorizes positions by hedge status). The result feeds back into the close execution engine to determine remaining work.

---

## 2. Business Logic

### 2.1 Hedge-Segregated Execution Tracking

**What**: Close execution units are tracked separately for hedged vs non-hedged positions.

**Columns/Parameters Involved**: `@ExecutionID`, `@IsAggregatedHedged`

**Rules**:
- The IsHedged flag on CloseExecutionPlan determines whether a position's close is part of a hedged aggregation
- This separation allows the system to process hedged and non-hedged closes independently
- Returns 0 (via ISNULL) when no units have been executed yet

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | BIGINT | NO | - | CODE-BACKED | Identifier for the close execution batch. Filters Trade.ExecutedCloseOrders to a specific execution round. |
| 2 | @IsAggregatedHedged | BIT | NO | - | CODE-BACKED | Hedge aggregation filter: 1=return only units from hedged positions, 0=return only units from non-hedged positions. Applied via CloseExecutionPlan.IsHedged. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (unnamed) | DECIMAL | NO | - | CODE-BACKED | Total executed units for the specified execution and hedge status. SUM of ExecutedCloseOrders.Units where the corresponding CloseExecutionPlan entry matches the hedge filter. Returns 0 if no rows match. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionID | Trade.ExecutedCloseOrders | JOIN | Filters executed close orders by execution batch |
| PositionID | Trade.CloseExecutionPlan | JOIN | Links executed orders to their plan entries for hedge status filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close Execution Engine | EXEC | Caller | Checks cumulative execution progress during multi-round closes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCloseOrderExecutedUnits (procedure, natively compiled)
├── Trade.ExecutedCloseOrders (table, memory-optimized)
└── Trade.CloseExecutionPlan (table, memory-optimized)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedCloseOrders | Table | Source of executed units, filtered by ExecutionID |
| Trade.CloseExecutionPlan | Table | JOINed on PositionID to filter by IsHedged status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Close Execution Engine | External Service | Calls to check execution progress |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- **Natively compiled** with SCHEMABINDING - runs entirely in memory
- Uses ATOMIC block with SNAPSHOT isolation level
- All referenced tables must be memory-optimized

---

## 8. Sample Queries

### 8.1 Check executed units for a non-hedged execution

```sql
EXEC Trade.GetCloseOrderExecutedUnits
    @ExecutionID = 98765,
    @IsAggregatedHedged = 0;
```

### 8.2 Check executed units for a hedged execution

```sql
EXEC Trade.GetCloseOrderExecutedUnits
    @ExecutionID = 98765,
    @IsAggregatedHedged = 1;
```

### 8.3 Directly query execution progress with position details

```sql
SELECT eco.ExecutionID,
       cep.IsHedged,
       SUM(eco.Units) AS TotalExecutedUnits,
       COUNT(*) AS PositionsExecuted
FROM Trade.ExecutedCloseOrders eco WITH (NOLOCK)
INNER JOIN Trade.CloseExecutionPlan cep WITH (NOLOCK)
    ON cep.PositionID = eco.PositionID
WHERE eco.ExecutionID = 98765
GROUP BY eco.ExecutionID, cep.IsHedged;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.CloseExecutionPlan](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13796114493) | Confluence | IsHedged flag prevents double-processing; close execution flow context |

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCloseOrderExecutedUnits | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCloseOrderExecutedUnits.sql*
