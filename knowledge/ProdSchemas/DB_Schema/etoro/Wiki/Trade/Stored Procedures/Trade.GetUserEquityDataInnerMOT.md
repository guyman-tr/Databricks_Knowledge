# Trade.GetUserEquityDataInnerMOT

> Natively compiled (in-memory OLTP) stored procedure that returns a customer's pending close orders in StatusID=11 ("Waiting for market") - the in-flight close operations that reduce effective open position size during equity calculation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer whose pending close orders are retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserEquityDataInnerMOT` is a natively compiled (WITH NATIVE_COMPILATION, SCHEMABINDING) stored procedure used exclusively by `Trade.GetUserEquityData` to retrieve the fourth result set: pending close orders. It targets orders with StatusID=11 ("Waiting for market") - these are close requests that have been submitted to the execution engine but have not yet been filled by the market.

These pending-close records are critical for equity calculation: if a position has an in-flight close order, the equity engine must subtract the `UnitsToDeduct` from the open position's units when computing current exposure. Without this, the same units would be counted as both open (from Trade.Position) and in-process-of-closing, leading to double-counting of exposure.

The use of native compilation reflects the hot-path nature of equity calculation: this is called frequently during position open/close pre-execution, and every millisecond matters. The SNAPSHOT isolation level (required by natively compiled procedures) avoids shared locks on the OrderForClose and CloseExecutionPlan tables.

---

## 2. Business Logic

### 2.1 Pending Close Detection (StatusID=11)

**What**: Returns only orders in the "Waiting for market" state.

**Columns**: `ofc.StatusID = 11`

**Rules**:
- StatusID=11 = "Waiting for market" (as confirmed in Trade.GetUserEquityDataInnerMOT DDL comment and consistent with Trade.GetTreeNodesByParentPositionAndTreeId pending close exclusion logic)
- These orders have been placed but not yet executed - the position is still technically open but scheduled to close
- Terminal statuses (Filled, Cancelled, Rejected) are NOT included

### 2.2 Join Between OrderForClose and CloseExecutionPlan

**What**: Gets the PositionID for each pending order by joining to the execution plan.

**Rules**:
- `Trade.OrderForClose` holds the order (CID, StatusID, UnitsToDeduct, RequestGuid)
- `Trade.CloseExecutionPlan` maps OrderID -> PositionID (one order can target multiple positions in a tree close, but this returns all affected positions)
- Filter applied on OrderForClose (CID = @CID) first, then joined to CloseExecutionPlan for position linkage

### 2.3 Native Compilation Constraints

**What**: Technical requirements imposed by native compilation.

**Rules**:
- `WITH NATIVE_COMPILATION, SCHEMABINDING`: all referenced objects must be schema-bound; no dynamic SQL, no temp tables, no NOLOCK hints
- `EXECUTE AS OWNER`: runs under owner security context
- `BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')`: SNAPSHOT isolation is mandatory for natively compiled procs - avoids pessimistic locking
- All referenced tables must support in-memory OLTP access (OrderForClose and CloseExecutionPlan are disk-based tables accessed via interop)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Trade.OrderForClose to this customer's pending close orders. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | OrderID | BIGINT | NO | - | CODE-BACKED | Close order identifier. From Trade.OrderForClose. |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | Position being closed by this order. From Trade.CloseExecutionPlan. One OrderID may appear multiple times if closing a tree. |
| 4 | UnitsToDeduct | DECIMAL | YES | - | CODE-BACKED | Units to remove from the open position when the close fills. The equity engine subtracts these from AmountInUnitsDecimal to avoid double-counting exposure. |
| 5 | RequestGuid | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Idempotency GUID for this close request. Used to deduplicate retry scenarios. |
| 6 | StatusID | INT | NO | - | CODE-BACKED | Always 11 (hardcoded filter in WHERE clause = "Waiting for market"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.OrderForClose | FROM | Source of pending close orders (CID, StatusID, UnitsToDeduct, RequestGuid) |
| JOIN | Trade.CloseExecutionPlan | INNER JOIN | Maps OrderID to PositionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUserEquityData | EXEC | Caller | Called for result set 4 (pending close orders) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserEquityDataInnerMOT (natively compiled procedure)
+-- Trade.OrderForClose (table)
+-- Trade.CloseExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForClose | Table | Source of pending close order records (CID filter, StatusID filter) |
| Trade.CloseExecutionPlan | Table | Maps OrderID to affected PositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserEquityData | Stored Procedure | EXEC caller - uses this as result set 4 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH NATIVE_COMPILATION | Execution | Compiled to native machine code; cannot use NOLOCK, temp tables, dynamic SQL |
| SCHEMABINDING | Schema lock | Referenced objects cannot be dropped/modified without dropping this SP first |
| EXECUTE AS OWNER | Security | Runs under the database owner context |
| TRANSACTION ISOLATION LEVEL = SNAPSHOT | Isolation | Required for natively compiled procedures; avoids shared locks |
| StatusID = 11 | Business filter | Only "Waiting for market" orders returned; terminal/other states excluded |

---

## 8. Sample Queries

### 8.1 Call directly for a customer's pending closes
```sql
EXEC Trade.GetUserEquityDataInnerMOT @CID = 123456
```

### 8.2 Equivalent disk-based query for debugging
```sql
-- Same logic but with NOLOCK (not valid in natively compiled proc)
SELECT ofc.OrderID, cep.PositionID, ofc.UnitsToDeduct, ofc.RequestGuid, ofc.StatusID
FROM Trade.OrderForClose ofc WITH (NOLOCK)
     INNER JOIN Trade.CloseExecutionPlan cep WITH (NOLOCK) ON ofc.OrderID = cep.OrderID
WHERE ofc.CID = 123456
  AND ofc.StatusID = 11
```

### 8.3 Check what StatusID=11 means
```sql
SELECT ID, Name FROM Dictionary.OrderForExecutionStatus WITH (NOLOCK)
WHERE ID = 11
-- Expected: "Waiting for market" or equivalent
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian documentation found. Internal execution infrastructure component.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserEquityDataInnerMOT | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserEquityDataInnerMOT.sql*
