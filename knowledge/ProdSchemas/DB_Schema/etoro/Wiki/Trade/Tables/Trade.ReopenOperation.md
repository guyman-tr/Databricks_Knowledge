# Trade.ReopenOperation

> Tracks position reopen operations for closed positions that need to be reopened after corporate actions, error corrections, or other events, with an approval workflow and execution lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ReopenOperationID |
| **Partition** | No |
| **Indexes** | 1 (PK) |

---

## 1. Business Meaning

**WHAT:** `ReopenOperation` is the parent record for a batch of positions (or mirrors) that must be reopened after they were closed. Each row represents one reopen operation request, which can contain multiple positions via the child table `Trade.PositionToReopen` or mirrors via `Trade.MirrorToReopen`. The table stores approval settings, requested stop/limit rates, and execution status. Operations are created manually by back-office users or by automated jobs (e.g., `Trade.ReopenForUnalignedSlCryptoPositions`).

**WHY:** When positions are closed unexpectedly (e.g., settlement changes, system errors, corporate actions, or crypto stop-loss misalignments), customers may need those positions reopened at the prior terms. The reopen workflow requires validation, optional approval, and execution tracking. This table centralizes that lifecycle so operations can be audited, canceled, or re-executed.

**HOW:** `Trade.ReopenOperationAdd` creates a new row and returns `ReopenOperationID`. Callers then insert child rows into `Trade.PositionToReopen` or `Trade.MirrorToReopen`. `Trade.ReopenOperationValidation` runs business rules and populates `AggregatedData` with XML. `Trade.ReopenOperationSendApprovalRequest` emails approval requests. After approval, `Trade.PositionsReopen` or `Trade.MirrorsReopen` execute the reopens and set `IsExecuted = 1`. `Trade.ReopenOperationSendResult` emails execution results. `Trade.ReopenOperationCancel` cancels pending positions and sets `IsExecuted = 2`.

---

## 2. Business Logic

### 2.1 Reopen Types (Dictionary.ReopenType)

**What**: `ReopenTypeID` classifies the operation. 1 = Position reopen, 2 = Mirror reopen. Different flows execute each type (`PositionsReopen` vs `MirrorsReopen`).

**Columns/Parameters Involved**: ReopenTypeID

**Rules**:
- FK to `Dictionary.ReopenType.ID`. Values: 1=Position, 2=Mirror
- Default 1 (Position)
- ReopenTypeID=2 operations use `Trade.MirrorToReopen`; ReopenTypeID=1 uses `Trade.PositionToReopen`

### 2.2 Approval and Execution Lifecycle

**What**: Operations move from created -> validated -> (optional) approval requested -> executed or canceled.

**Columns/Parameters Involved**: IsManual, IsExecuted, ValidateUserBalance, AggregatedData

**Rules**:
- IsExecuted: 0=pending, 1=executed, 2=canceled
- IsManual default 1 (manual operations)
- ValidateUserBalance controls balance checks during validation
- AggregatedData is populated by ReopenOperationValidation with XML snapshot for approval emails

### 2.3 Stop/Limit and Mirror Settings

**What**: RequestedStopRate and RequestedLimitRate apply to reopened positions. AllowUpdateMirrorSL allows stop-loss updates on mirror children.

**Columns/Parameters Involved**: RequestedStopRate, RequestedLimitRate, CompensateOnStopLossDelta, AllowUpdateMirrorSL

**Rules**:
- ReopenOperationValidation rejects negative StopRate or LimitRate
- CompensateOnStopLossDelta default 0
- AllowUpdateMirrorSL default 0

---

## 3. Data Overview

| ReopenOperationID | Occurred | UserName | ReopenTypeID | IsManual | IsExecuted | Meaning |
|------------------|----------|----------|--------------|----------|------------|---------|
| 68 | 2025-03-06 12:02 | be-user | 1 | 1 | 1 | Position reopen, manual, executed |
| 67 | 2025-03-06 11:43 | be-user | 1 | 1 | 1 | Same pattern |
| 66 | 2025-03-06 10:09 | be-user | 1 | 1 | 1 | Position reopens dominate in sample |

*Live data: ReopenTypeID=1 (Position) most common; IsExecuted=1 for completed operations.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReopenOperationID | int | NO | IDENTITY | CODE-BACKED | Primary key. Generated on insert. |
| 2 | Occurred | datetime | NO | getutcdate() | CODE-BACKED | When the reopen operation was created. |
| 3 | ValidateUserBalance | tinyint | NO | - | CODE-BACKED | Whether to validate customer balance before execution. |
| 4 | UserName | varchar(100) | NO | - | CODE-BACKED | User or system that initiated the operation (e.g., be-user, job name). |
| 5 | AggregatedData | xml | YES | - | CODE-BACKED | XML snapshot for approval emails, populated by ReopenOperationValidation. |
| 6 | RequestedStopRate | dtPrice | YES | - | CODE-BACKED | Requested stop-loss rate for reopened positions. |
| 7 | RequestedLimitRate | dtPrice | YES | - | CODE-BACKED | Requested take-profit rate for reopened positions. |
| 8 | CompensateOnStopLossDelta | tinyint | NO | 0 | CODE-BACKED | Whether to compensate for stop-loss delta. |
| 9 | IsManual | tinyint | NO | 1 | CODE-BACKED | 1=manual operation, 0=automated. |
| 10 | IsExecuted | tinyint | NO | 0 | CODE-BACKED | 0=pending, 1=executed, 2=canceled. |
| 11 | ReopenTypeID | tinyint | NO | 1 | VERIFIED | FK to Dictionary.ReopenType. 1=Position, 2=Mirror. |
| 12 | AllowUpdateMirrorSL | bit | NO | 0 | CODE-BACKED | Whether to allow stop-loss updates on mirror child positions. |
| 13 | ReopenDescription | varchar(2000) | YES | - | CODE-BACKED | Human-readable description or audit reason. |
| 14 | ReopenReasonID | int | YES | - | NAME-INFERRED | Optional reason lookup for the reopen. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| ReopenTypeID | Dictionary.ReopenType | FK | Reopen type: Position or Mirror |
| ReopenReasonID | (Unknown) | Implicit | Optional reason reference |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Trade.PositionToReopen | ReopenOperationID | Child | Positions to reopen |
| Trade.MirrorToReopen | ReopenOperationID | Child | Mirrors to reopen |
| Trade.ReopenOperationAdd | INSERT | WRITER | Creates operations |
| Trade.ReopenOperation_Get | SELECT | READER | Lists operations |
| Trade.ReopenOperationValidation | AggregatedData | WRITER | Populates XML |
| Trade.ReopenOperationSendApprovalRequest | ReopenOperationID | READER | Builds approval email |
| Trade.ReopenOperationSendResult | ReopenOperationID | READER | Sends result email |
| Trade.ReopenOperationCancel | IsExecuted | WRITER | Sets IsExecuted=2 |
| Trade.PositionsReopen | ReopenOperationID | READER/WRITER | Executes position reopens |
| Trade.MirrorsReopen | ReopenOperationID | READER/WRITER | Executes mirror reopens |
| Trade.PositionReopen | (indirect via PositionToReopen) | - | Per-position execution |
| Trade.MirrorReopen | (indirect via MirrorToReopen) | - | Per-mirror execution |
| Trade.ReopenForUnalignedSlCryptoPositions | ReopenOperationAdd | - | Automated job creates operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ReopenType (table)
    ^
    |
Trade.ReopenOperation (table)
    |
    +-- Trade.PositionToReopen (table)
    +-- Trade.MirrorToReopen (table)
```

### 6.1 Objects This Depends On

| Object | Dependency |
|--------|------------|
| Dictionary.ReopenType | FK ReopenTypeID |

### 6.2 Objects That Depend On This

| Object | Dependency |
|--------|------------|
| Trade.PositionToReopen | ReopenOperationID |
| Trade.MirrorToReopen | ReopenOperationID |
| Trade.ReopenOperationAdd | INSERT |
| Trade.ReopenOperation_Get | SELECT |
| Trade.ReopenOperationValidation | SELECT/UPDATE |
| Trade.ReopenOperationSendApprovalRequest | SELECT |
| Trade.ReopenOperationSendResult | SELECT |
| Trade.ReopenOperationCancel | UPDATE |
| Trade.PositionsReopen | SELECT/UPDATE |
| Trade.MirrorsReopen | SELECT/UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Description |
|------------|------|-------------|-------------|
| PK_ReopenOperation | CLUSTERED PK | ReopenOperationID ASC | Primary key |

### 7.2 Constraints

| Constraint | Type | Description |
|------------|------|-------------|
| PK_ReopenOperation | PRIMARY KEY | ReopenOperationID |
| DF_ReopenOperation_Occurred | DEFAULT | getutcdate() for Occurred |
| DF_ReopenOperation_CompensateOnStopLossDelta | DEFAULT | 0 |
| DF (IsManual) | DEFAULT | 1 |
| DF (IsExecuted) | DEFAULT | 0 |
| DF (ReopenTypeID) | DEFAULT | 1 |
| DF (AllowUpdateMirrorSL) | DEFAULT | 0 |
| FK_ReopenOperation_ReopenTypeID | FOREIGN KEY | ReopenTypeID -> Dictionary.ReopenType.ID |

---

## 8. Sample Queries

```sql
-- List recent reopen operations
SELECT TOP 10 ReopenOperationID, Occurred, UserName, ReopenTypeID, IsManual, IsExecuted
FROM   Trade.ReopenOperation WITH (NOLOCK)
ORDER  BY ReopenOperationID DESC;

-- Reopen operations with type label
SELECT ro.ReopenOperationID, ro.Occurred, ro.UserName, rt.ReopenType, ro.IsExecuted
FROM   Trade.ReopenOperation ro WITH (NOLOCK)
       JOIN Dictionary.ReopenType rt WITH (NOLOCK) ON ro.ReopenTypeID = rt.ID
ORDER  BY ro.ReopenOperationID DESC;

-- Pending operations (not executed)
SELECT ReopenOperationID, Occurred, UserName, ReopenTypeID
FROM   Trade.ReopenOperation WITH (NOLOCK)
WHERE  IsExecuted = 0
ORDER  BY ReopenOperationID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10 | Sources: DDL, 10+ procedures, MCP live data, Dictionary.ReopenType*
