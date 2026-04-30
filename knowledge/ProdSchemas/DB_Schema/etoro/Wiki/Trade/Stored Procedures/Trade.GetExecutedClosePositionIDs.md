# Trade.GetExecutedClosePositionIDs

> Returns PositionIDs of executed close orders for a given execution and tree level, used in the copy-trade close execution flow. Natively compiled for memory-optimized tables.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the PositionIDs of positions whose close orders have been executed for a specific execution ID and tree level. It models "which positions were closed as part of this copy-trade execution at this level of the close tree." Without it, the copy-trade close executor would not know which positions to update or mark as completed. It exists to support the copy-trade close execution flow, where a leader's close triggers cascading closes across followers at various tree levels. The procedure is called by the close execution engine after orders are executed, to fetch the set of positions that completed at a given level. Data flows from ExecutedCloseOrders (what was executed) and CloseExecutionPlan (the tree structure) into a filtered PositionID result set consumed by downstream close logic.

---

## 2. Business Logic

### 2.1 Execution + Level Filtering

**What**: Only positions whose close orders were executed for the given ExecutionID and whose close execution plan level matches the requested level are returned.

**Columns/Parameters Involved**: `@ExecutionID`, `@Lvl`, `eco.PositionID`, `cep.PositionID`, `cep.Level`

**Rules**:
- Join ExecutedCloseOrders (eco) to CloseExecutionPlan (cep) on PositionID.
- Filter eco.ExecutionID = @ExecutionID and cep.Level = @Lvl.
- Each returned PositionID represents a position that was closed as part of this execution at this tree level.
- The procedure is natively compiled and schema-bound for use with memory-optimized tables.

**Diagram**:
```
@ExecutionID, @Lvl
       |
       v
Trade.ExecutedCloseOrders (eco) ----JOIN on PositionID---- Trade.CloseExecutionPlan (cep)
       |                                                        |
       eco.ExecutionID = @ExecutionID                    cep.Level = @Lvl
       |                                                        |
       +--------------------------------------------------------+
                              |
                              v
                    SELECT eco.PositionID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionID | BIGINT | - | - | CODE-BACKED | Execution identifier. Filters to close orders belonging to this execution batch. |
| 2 | @Lvl | INT | - | - | CODE-BACKED | Tree level in the close execution plan. Filters to positions at this level in the hierarchy. |
| 3 | PositionID | BIGINT | - | - | CODE-BACKED | Primary output. Identifier of a position whose close order was executed for the given ExecutionID and Level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| eco.PositionID | Trade.ExecutedCloseOrders | Table | Positions whose close orders were executed. |
| eco.PositionID, cep.PositionID | Trade.CloseExecutionPlan | Table | Links position to tree level. Implicit JOIN on PositionID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetExecutedClosePositionIDs (procedure)
├── Trade.ExecutedCloseOrders (table)
└── Trade.CloseExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecutedCloseOrders | Table | INNER JOIN, filtered by ExecutionID. Source of PositionID for executed closes. |
| Trade.CloseExecutionPlan | Table | INNER JOIN on PositionID, filtered by Level. Provides tree level context. |

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

---

### 7.3 Compilation and Isolation

| Property | Value |
|----------|-------|
| Native Compilation | Yes (WITH NATIVE_COMPILATION) |
| Schema Binding | Yes (SCHEMABINDING) |
| Transaction | ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT) |
| Language | us_english |

---

## 8. Sample Queries

### 8.1 Get executed close position IDs for an execution and level

```sql
EXEC Trade.GetExecutedClosePositionIDs
    @ExecutionID = 123456789,
    @Lvl = 1;
```

### 8.2 Use result set to update positions (conceptual)

```sql
-- Caller typically uses result set to iterate or update
DECLARE @ExecutionID BIGINT = 123456789;
DECLARE @Lvl INT = 1;

-- Positions returned can be used for downstream logic
SELECT PositionID FROM Trade.ExecutedCloseOrders eco WITH (NOLOCK)
INNER JOIN Trade.CloseExecutionPlan cep WITH (NOLOCK) ON cep.PositionID = eco.PositionID
WHERE eco.ExecutionID = @ExecutionID AND cep.Level = @Lvl;
```

### 8.3 Join to position table for audit

```sql
CREATE TABLE #Pos (PositionID BIGINT);
INSERT INTO #Pos EXEC Trade.GetExecutedClosePositionIDs @ExecutionID = 123456789, @Lvl = 1;

SELECT p.PositionID, p.CID, p.InstrumentID, p.OpenRate
FROM #Pos t
JOIN Trade.PositionTbl p WITH (NOLOCK) ON p.PositionID = t.PositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetExecutedClosePositionIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetExecutedClosePositionIDs.sql*
