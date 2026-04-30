# Trade.GetExecutedOpenPositionCorrelationIDs

> Returns OpenCorrelationIDs of executed open orders for a given execution and tree level. Mirrors the close flow but for position opens. Natively compiled for memory-optimized tables.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OpenCorrelationID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the OpenCorrelationIDs of open orders that have been executed for a specific execution ID and tree level. It models "which open order correlation IDs completed as part of this copy-trade execution at this level of the open tree." Without it, the copy-trade open executor would not know which open orders to associate with completed positions at each level. It exists to support the copy-trade open execution flow, the counterpart to GetExecutedClosePositionIDs. The procedure is called by the open execution engine after orders are executed, to fetch the set of OpenCorrelationIDs that completed at a given level. Data flows from ExecutedOpenOrders (what was executed) and OpenExecutionPlan (the tree structure) into a filtered OpenCorrelationID result set consumed by downstream open logic.

---

## 2. Business Logic

### 2.1 Execution + Level Filtering

**What**: Only OpenCorrelationIDs whose open orders were executed for the given ExecutionID and whose open execution plan level matches the requested level are returned.

**Columns/Parameters Involved**: `@ExecutionID`, `@Lvl`, `eoo.OpenCorrelationID`, `oep.OpenCorrelationID`, `oep.Level`

**Rules**:
- Join ExecutedOpenOrders (eoo) to OpenExecutionPlan (oep) on OpenCorrelationID.
- Filter eoo.ExecutionID = @ExecutionID and oep.Level = @Lvl.
- Each returned OpenCorrelationID represents an open order that was executed as part of this execution at this tree level.
- The procedure is natively compiled and schema-bound for use with memory-optimized tables.

**Diagram**:
```
@ExecutionID, @Lvl
       |
       v
Trade.ExecutedOpenOrders (eoo) ----JOIN on OpenCorrelationID---- Trade.OpenExecutionPlan (oep)
       |                                                              |
       eoo.ExecutionID = @ExecutionID                          oep.Level = @Lvl
       |                                                              |
       +--------------------------------------------------------------+
                              |
                              v
                    SELECT eoo.OpenCorrelationID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | BIGINT | - | - | CODE-BACKED | Execution identifier. Filters to open orders belonging to this execution batch. |
| 2 | @Lvl | INT | - | - | CODE-BACKED | Tree level in the open execution plan. Filters to open orders at this level in the hierarchy. |
| 3 | OpenCorrelationID | BIGINT | - | - | CODE-BACKED | Primary output. Correlation ID of an open order that was executed for the given ExecutionID and Level. Used to link executed opens to positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| eoo.OpenCorrelationID | Trade.ExecutedOpenOrders | Table | Open orders that were executed. |
| eoo.OpenCorrelationID, oep.OpenCorrelationID | Trade.OpenExecutionPlan | Table | Links open order correlation to tree level. Implicit JOIN on OpenCorrelationID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetExecutedOpenPositionCorrelationIDs (procedure)
├── Trade.ExecutedOpenOrders (table)
└── Trade.OpenExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedOpenOrders | Table | INNER JOIN, filtered by ExecutionID. Source of OpenCorrelationID for executed opens. |
| Trade.OpenExecutionPlan | Table | INNER JOIN on OpenCorrelationID, filtered by Level. Provides tree level context. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Not analyzed in this phase | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

### 7.3 Compilation and Isolation

| Property | Value |
|----------|-------|
| Native Compilation | Yes (WITH NATIVE_COMPILATION) |
| Schema Binding | Yes (SCHEMABINDING) |
| Transaction | ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT) |
| Language | us_english |

---

## 8. Sample Queries

### 8.1 Get executed open correlation IDs for an execution and level

```sql
EXEC Trade.GetExecutedOpenPositionCorrelationIDs
    @ExecutionID = 123456789,
    @Lvl = 1;
```

### 8.2 Use result set in downstream open logic (conceptual)

```sql
DECLARE @ExecutionID BIGINT = 123456789;
DECLARE @Lvl INT = 1;

SELECT OpenCorrelationID FROM Trade.ExecutedOpenOrders eoo WITH (NOLOCK)
INNER JOIN Trade.OpenExecutionPlan oep WITH (NOLOCK) ON oep.OpenCorrelationID = eoo.OpenCorrelationID
WHERE eoo.ExecutionID = @ExecutionID AND oep.Level = @Lvl;
```

### 8.3 Join to order or position table for audit

```sql
CREATE TABLE #Corr (OpenCorrelationID BIGINT);
INSERT INTO #Corr EXEC Trade.GetExecutedOpenPositionCorrelationIDs @ExecutionID = 123456789, @Lvl = 1;

SELECT c.OpenCorrelationID, o.CID, o.InstrumentID, o.Amount
FROM #Corr c
JOIN Trade.OpenOrders o WITH (NOLOCK) ON o.OpenCorrelationID = c.OpenCorrelationID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetExecutedOpenPositionCorrelationIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetExecutedOpenPositionCorrelationIDs.sql*
