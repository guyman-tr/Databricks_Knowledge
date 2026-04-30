# Trade.CloseExecutionPlanTbl

> A memory-optimized table-valued parameter type for close order execution plans, specifying which positions to close, at what hierarchy level, how many units, and the close action type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID, Level, Units |
| **Partition** | N/A |
| **Indexes** | 1 (hash on PositionID) |

---

## 1. Business Meaning

Trade.CloseExecutionPlanTbl is a memory-optimized table-valued parameter (TVP) type that carries the execution plan for closing positions - especially in copy-trade trees. When closing positions, the system generates a plan specifying which positions to close, at what level in the tree hierarchy, how many units, the close action type, and whether the position is hedged.

This type exists to support close-order creation in complex scenarios - copy-trade trees require a structured plan so that closes happen in the correct order and with the right parameters. Without it, close logic would need to pass many separate parameters or process row-by-row.

Trade.OrderForCloseCreate receives a CloseExecutionPlanTbl, JOINs against it, and creates the corresponding close orders. The hash index on PositionID with 512 buckets is sized for typical batch sizes.

---

## 2. Business Logic

### 2.1 Position Close Hierarchy

**What**: The execution plan encodes a tree-level-aware close order. Level indicates depth in the copy-trade tree; closes may need to proceed level-by-level.

**Columns/Parameters Involved**: `PositionID`, `Level`, `Units`, `CID`, `CloseActionType`, `IsHedged`

**Rules**:
- Each row represents one position close instruction with a target unit count
- Level (smallint) identifies the hierarchy depth for tree-aware processing
- IsHedged indicates whether the position has a corresponding hedge - affects close logic
- CloseActionType determines the type of close (e.g., full, partial, specific action)

**Diagram**:
```
PositionID -> Level -> Units
    |           |        |
    v           v        v
  Tree ID   Depth in   Amount to
  to close  hierarchy   close
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position ID - identifies the position to close. Hash index on this column optimizes JOINs during close order creation. |
| 2 | Level | smallint | NO | - | CODE-BACKED | Hierarchy level in the copy-trade tree. Used for ordered close processing - lower levels may be closed first. |
| 3 | Units | decimal(16, 6) | NO | - | CODE-BACKED | Number of units to close for this position. Must match or be less than the position's open units. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID - the account that owns the position. Links the close plan to the correct customer. |
| 5 | CloseActionType | tinyint | NO | - | CODE-BACKED | Type of close action. Values define the business close operation (e.g., full close, partial, specific action). |
| 6 | IsHedged | bit | NO | - | CODE-BACKED | 1 = position has a corresponding hedge; 0 = no hedge. Affects how the close is executed and whether hedge positions are closed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | Identifies the position row to close |
| CID | Customer.CustomerTbl | Implicit | Identifies the customer owning the position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForCloseCreate | Parameter (TVP) | Parameter (TVP) | Receives the close execution plan and creates close orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForCloseCreate | Stored Procedure | READONLY parameter for close order creation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX_PositionID | NONCLUSTERED HASH | PositionID | - | - | Active |

Hash index with 512 buckets. Memory-optimized types use hash or nonclustered indexes only.

### 7.2 Constraints

None declared beyond NOT NULL on columns.

---

## 8. Sample Queries

### 8.1 Declare and populate CloseExecutionPlanTbl for single position close

```sql
DECLARE @Plan Trade.CloseExecutionPlanTbl;
INSERT INTO @Plan (PositionID, Level, Units, CID, CloseActionType, IsHedged)
VALUES (987654321, 1, 10.5, 12345, 1, 0);
EXEC Trade.OrderForCloseCreate @ExecutionPlan = @Plan;
```

### 8.2 Build execution plan for multiple positions from same customer

```sql
DECLARE @Plan Trade.CloseExecutionPlanTbl;
INSERT INTO @Plan (PositionID, Level, Units, CID, CloseActionType, IsHedged)
SELECT  PositionID, 1, OpenUnits, CID, 1, IsHedged
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   CID = 12345 AND IsOpen = 1 AND InstrumentID = 100;
EXEC Trade.OrderForCloseCreate @ExecutionPlan = @Plan;
```

### 8.3 Tree-level closes with explicit levels

```sql
DECLARE @Plan Trade.CloseExecutionPlanTbl;
INSERT INTO @Plan (PositionID, Level, Units, CID, CloseActionType, IsHedged)
VALUES (111, 0, 5.0, 100, 1, 1), (222, 1, 3.0, 100, 1, 0);
EXEC Trade.OrderForCloseCreate @ExecutionPlan = @Plan;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseExecutionPlanTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CloseExecutionPlanTbl.sql*
