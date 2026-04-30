# Trade.GetUserWithRestirctions

> Returns all active blocking restrictions for a customer (mapped to atomic operation IDs via Trade.OperationTypeForBlockingToAtomic), and optionally also calls Trade.GetUserInfo to load full user context. Core pre-execution restriction validator referenced directly in the trading-execution-services application.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @ShouldGetInfo |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserWithRestirctions` (note: "Restirctions" is a typo in the original - it persists in all callers and the app code) is a pre-execution restriction validator that answers: "what operations is this customer blocked from, and what is the relevant context for each block?" The execution engine calls this before processing any order to determine if the customer has any blocks that should prevent the operation.

The first result set maps each `Customer.BlockedCustomerOperations` entry for the customer to an `AtomicOperationID` via `Trade.OperationTypeForBlockingToAtomic`. The atomic operation ID is the fine-grained permission unit used by the execution engine to decide whether a specific trade action (open, close, copy start, etc.) is permitted. The join to this mapping table translates high-level block types (OperationTypeID) into specific atomic operation codes.

The `@ShouldGetInfo` flag allows callers to combine restriction check + full user context in a single round-trip (when 1) or get just restrictions (when 0). This is a performance optimization: if the caller already has user context from a prior call, they can pass @ShouldGetInfo=0.

The procedure is referenced in `trading-execution-services` as `OrderStatusUpdateContextDataProcName = "[Trade].[GetUserWithRestirctions]"`, confirming its role in the order status update context loading path.

---

## 2. Business Logic

### 2.1 Restriction to Atomic Operation Mapping

**What**: Maps blocking restrictions to atomic operation IDs.

**Columns**: `CID, AtomicOperationID, BlockReasonID, OperationTypeID`

**Rules**:
- `Customer.BlockedCustomerOperations`: all active blocks for @CID (no status filter - all rows for this CID are returned)
- `INNER JOIN Trade.OperationTypeForBlockingToAtomic OTFBA ON BCO.OperationTypeID = OTFBA.OperationTypeID`: maps each block's OperationTypeID to one or more AtomicOperationIDs
- The mapping table may be one-to-many (one OperationTypeID -> multiple AtomicOperationIDs)
- Result: the execution engine checks if the AtomicOperationID for the requested action appears in this list

### 2.2 Optional GetUserInfo

**What**: When @ShouldGetInfo=1, also returns full user context.

**Rules**:
- `IF (@ShouldGetInfo = 1) EXEC Trade.GetUserInfo @CID`
- Returns as the second result set when called
- Eliminates a second round-trip when both restrictions and user context are needed
- Wrapped in TRY/CATCH with THROW re-raise

### 2.3 Error Handling

**What**: BEGIN TRY/CATCH with THROW.

**Rules**:
- Any error in the restriction query or GetUserInfo call is re-thrown to the caller
- No custom error handling - THROW propagates the original error with full context

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose restrictions are loaded. |
| 2 | @ShouldGetInfo | BIT | NO | - | CODE-BACKED | 1 = also execute Trade.GetUserInfo @CID (adds second result set); 0 = restrictions only. |

**Result Set 1 - Blocking Restrictions:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 3 | CID | INT | NO | CODE-BACKED | Customer ID (same as @CID for all rows). |
| 4 | AtomicOperationID | INT | NO | CODE-BACKED | Fine-grained atomic operation ID from Trade.OperationTypeForBlockingToAtomic. Used by execution engine to match against requested operation. |
| 5 | BlockReasonID | INT | NO | CODE-BACKED | Reason code for this block from Customer.BlockedCustomerOperations. FK to Dictionary.BlockReason or similar. |
| 6 | OperationTypeID | INT | NO | CODE-BACKED | High-level operation type being blocked. FK to Trade.OperationTypeForBlockingToAtomic. |

**Result Set 2 (conditional - @ShouldGetInfo=1 only):**
- All columns from Trade.GetUserInfo (see Trade.GetUserInfo.md for full column list)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Result Set 1 | Customer.BlockedCustomerOperations | FROM | All blocks for @CID |
| Result Set 1 | Trade.OperationTypeForBlockingToAtomic | INNER JOIN | Maps OperationTypeID to AtomicOperationID |
| Result Set 2 | Trade.GetUserInfo | EXEC (conditional) | Full user context when @ShouldGetInfo=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUserInfoWithCopyRestirctions | EXEC | Caller | Copy-trade pre-execution orchestrator |
| Trade.GetUserAndPositionData | EXEC | Caller | Position-edit pre-execution orchestrator (TRADEX-1700) |
| trading-execution-services | OrderStatusUpdateContextDataProcName | App reference | `"[Trade].[GetUserWithRestirctions]"` in ExecutionContextDataRepository.cs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserWithRestirctions (procedure)
+-- Customer.BlockedCustomerOperations (table)
+-- Trade.OperationTypeForBlockingToAtomic (table)
+-- Trade.GetUserInfo (procedure) [conditional on @ShouldGetInfo=1]
      +-- Trade.GetTotalManualOrdersForOpenAmount (function)
      +-- Trade.Mirror (table)
      +-- Customer.Customer (table)
      +-- BackOffice.Customer (table)
      +-- ...
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | Source of all active blocks for @CID |
| Trade.OperationTypeForBlockingToAtomic | Table | Maps OperationTypeID to AtomicOperationID |
| Trade.GetUserInfo | Stored Procedure | Optional second result set when @ShouldGetInfo=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserInfoWithCopyRestirctions | Stored Procedure | EXEC caller |
| Trade.GetUserAndPositionData | Stored Procedure | EXEC caller |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRY/CATCH THROW | Error handling | Re-raises errors to caller without consuming them |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| No NoLock on BlockedCustomerOperations | Read consistency | Reads without NOLOCK hint (consistent read for blocking decisions) |

---

## 8. Sample Queries

### 8.1 Get restrictions only (fast path)
```sql
EXEC Trade.GetUserWithRestirctions @CID = 123456, @ShouldGetInfo = 0
-- Returns: CID, AtomicOperationID, BlockReasonID, OperationTypeID
```

### 8.2 Get restrictions + full user info (single round-trip)
```sql
EXEC Trade.GetUserWithRestirctions @CID = 123456, @ShouldGetInfo = 1
-- Returns: result set 1 (restrictions) + result set 2 (GetUserInfo)
```

### 8.3 Inspect the atomic operation mapping
```sql
SELECT OTFBA.OperationTypeID, OTFBA.AtomicOperationID
FROM Trade.OperationTypeForBlockingToAtomic OTFBA WITH (NOLOCK)
ORDER BY OTFBA.OperationTypeID, OTFBA.AtomicOperationID
```

---

## 9. Atlassian Knowledge Sources

No dedicated Confluence page found for this SP in the TRAD/DB folder. Referenced in trading-execution-services application code (confirmed via `OrderStatusUpdateContextDataProcName`).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 1 repo (trading-execution-services) | Corrections: 0 applied*
*Object: Trade.GetUserWithRestirctions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserWithRestirctions.sql*
