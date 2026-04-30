# Trade.GetUserAndPositionData

> Orchestrator for position-edit pre-execution context loading (TRADEX-1700) - combines GetUserWithRestirctions (user restrictions + optional context), GetOpenPositionData (position detail with optional lock), and GetPlacedOrdersForCloseByPositionId (existing close orders) in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @PositionID - customer and position being edited |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserAndPositionData` is the pre-execution context loader for position edit operations, created for the US project (TRADEX-1700, August 2021). When a customer attempts to modify a position (edit stop-loss, take-profit, or similar), the execution engine calls this procedure to load everything needed in one round-trip: user restrictions, optional full user context, the position's current state, and any existing close orders on that position.

The three sub-procedures cover three distinct concerns:
1. **GetUserWithRestirctions**: Is the customer allowed to perform this operation? What blocks apply?
2. **GetOpenPositionData**: What is the current state of the position? Does it need to be locked for this operation?
3. **GetPlacedOrdersForCloseByPositionId**: Are there existing close orders on this position that would conflict?

The `@LockPosition` flag (passed to GetOpenPositionData) controls whether the position row is locked (UPDLOCK) during this read - required when the edit is about to update the position and must prevent concurrent modifications.

The `@ShouldGetInfo` flag (passed to GetUserWithRestirctions) determines whether full user context (GetUserInfo) is also returned - used when the caller needs credit, regulation, and status data in addition to restrictions.

---

## 2. Business Logic

### 2.1 Three-SP Orchestration

**What**: Calls three sub-procedures in sequence, each returning separate result sets.

**Rules**:
1. `EXEC Trade.GetUserWithRestirctions @CID, @ShouldGetInfo` - 1 or 2 result sets (restrictions; optionally + GetUserInfo)
2. `EXEC Trade.GetOpenPositionData @PositionID, @LockPosition` - position data (with or without UPDLOCK)
3. `EXEC Trade.GetPlacedOrdersForCloseByPositionId @PositionID` - existing close orders for this position

### 2.2 Position Lock Flag

**What**: @LockPosition controls whether the position read acquires an update lock.

**Rules**:
- `@LockPosition = 0` (default): read-only position lookup (for validation without modification intent)
- `@LockPosition = 1`: GetOpenPositionData uses UPDLOCK/serializable isolation to prevent concurrent edits
- This prevents race conditions where two concurrent edits to the same position produce inconsistent state

### 2.3 TRADEX-1700 Context

**What**: Created for the US project (TRADEX-1700) which introduced position edit functionality.

**Rules**:
- Initial creation: Ran Ovadia, 16-08-2021, TRADEX-1700
- Amendment: PositionID changed from INT to BIGINT (16/11/2021) - required by TRADEX-1700 US project for larger position IDs

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Passed to GetUserWithRestirctions. |
| 2 | @ShouldGetInfo | BIT | NO | - | CODE-BACKED | 1 = also return GetUserInfo context (passed to GetUserWithRestirctions); 0 = restrictions only. |
| 3 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position ID being edited. Passed to GetOpenPositionData and GetPlacedOrdersForCloseByPositionId. Changed from INT to BIGINT (TRADEX-1700). |
| 4 | @LockPosition | BIT | YES | 0 | CODE-BACKED | 0 = read-only position lookup; 1 = acquire UPDLOCK for edit operation. Passed to GetOpenPositionData. |

**Result Sets:**

Result Set 1: Trade.GetUserWithRestirctions restrictions (CID, AtomicOperationID, BlockReasonID, OperationTypeID). See Trade.GetUserWithRestirctions.md.

Result Set 2 (conditional - @ShouldGetInfo=1): GetUserInfo columns. See Trade.GetUserInfo.md.

Result Set 3: GetOpenPositionData result (position detail). See Trade.GetOpenPositionData.md.

Result Set 4: GetPlacedOrdersForCloseByPositionId result (existing close orders for the position).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Step 1 | Trade.GetUserWithRestirctions | EXEC | User restrictions + optional GetUserInfo |
| Step 2 | Trade.GetOpenPositionData | EXEC | Position state (with optional lock) |
| Step 3 | Trade.GetPlacedOrdersForCloseByPositionId | EXEC | Existing close orders for position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (US position edit execution engine) | @CID, @PositionID | EXEC caller | Pre-execution context load for position edit (TRADEX-1700) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserAndPositionData (procedure)
+-- Trade.GetUserWithRestirctions (procedure)
|     +-- Customer.BlockedCustomerOperations (table)
|     +-- Trade.OperationTypeForBlockingToAtomic (table)
|     +-- Trade.GetUserInfo (procedure) [conditional]
+-- Trade.GetOpenPositionData (procedure)
+-- Trade.GetPlacedOrdersForCloseByPositionId (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserWithRestirctions | Stored Procedure | User restrictions + optional context |
| Trade.GetOpenPositionData | Stored Procedure | Position detail with optional lock |
| Trade.GetPlacedOrdersForCloseByPositionId | Stored Procedure | Existing close orders for position |

### 6.2 Objects That Depend On This

No documented dependents. Called by execution engine for position edits.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @LockPosition flag | Locking | Controls UPDLOCK acquisition in GetOpenPositionData |
| @ShouldGetInfo flag | Result set count | Determines whether GetUserInfo result set is included |
| @PositionID BIGINT | Data type | Changed from INT to BIGINT per TRADEX-1700 |

---

## 8. Sample Queries

### 8.1 Load position edit context (with lock, no user info)
```sql
EXEC Trade.GetUserAndPositionData
    @CID = 123456,
    @ShouldGetInfo = 0,
    @PositionID = 987654321,
    @LockPosition = 1
-- Returns: restrictions, position data (locked), close orders
```

### 8.2 Load full context (with user info, no lock)
```sql
EXEC Trade.GetUserAndPositionData
    @CID = 123456,
    @ShouldGetInfo = 1,
    @PositionID = 987654321,
    @LockPosition = 0
-- Returns: restrictions, user info, position data, close orders
```

### 8.3 Check sub-procedures independently
```sql
-- Step 1: restrictions
EXEC Trade.GetUserWithRestirctions @CID = 123456, @ShouldGetInfo = 0;
-- Step 2: position
EXEC Trade.GetOpenPositionData @PositionID = 987654321, @LockPosition = 0;
-- Step 3: existing close orders
EXEC Trade.GetPlacedOrdersForCloseByPositionId @PositionID = 987654321;
```

---

## 9. Atlassian Knowledge Sources

**Jira**: TRADEX-1700 (referenced in DDL comment) - US project position edit feature. Created 16-08-2021 by Ran Ovadia. PositionID updated to BIGINT on 16/11/2021.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 1 Jira (TRADEX-1700) | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserAndPositionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserAndPositionData.sql*
