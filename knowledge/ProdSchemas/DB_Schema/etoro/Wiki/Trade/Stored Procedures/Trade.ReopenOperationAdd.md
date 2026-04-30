# Trade.ReopenOperationAdd

> Creates a new reopen operation record in Trade.ReopenOperation and returns the generated ReopenOperationID for the caller to use when adding child positions or mirrors to reopen.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns @ReopenOperationID (SCOPE_IDENTITY of created row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReopenOperationAdd creates the parent reopen operation record in Trade.ReopenOperation, which serves as the header for a batch of positions (or mirrors) to be reopened. The caller receives the new ReopenOperationID and uses it to insert child rows into Trade.PositionToReopen or Trade.MirrorToReopen before triggering validation and execution.

This procedure exists as the controlled INSERT path for reopen operations. The reopen workflow requires a parent record (this) before child positions can be associated. Centralizing creation here allows the dual-return pattern (RETURN value + SELECT result set) to support both EXEC-based callers (which read RETURN codes) and ORM/application callers (which read result sets).

Data flow: Called at the start of a reopen workflow - either manually by back-office users (IsManual=1) or by automated procedures (IsManual=0, e.g., Trade.ReopenForUnalignedSlCryptoPositions). After calling this, the workflow continues with inserting child records, running Trade.ReopenOperationValidation, sending approval via Trade.ReopenOperationSendApprovalRequest, and executing via Trade.PositionsReopen or Trade.MirrorsReopen.

---

## 2. Business Logic

### 2.1 Dual-Return Pattern (Historical)

**What**: The procedure both SELECTs the new ReopenOperationID as a result set AND returns it via RETURN. The code comment reads "crap code so select and return" indicating this was a workaround to support multiple calling conventions.

**Columns/Parameters Involved**: `@ReopenOperationID`

**Rules**:
- SCOPE_IDENTITY() is captured after INSERT to get the new ReopenOperationID.
- SELECT @ReopenOperationID AS ReopenOperationID - sends a single-row result set for ORM/application callers.
- RETURN @ReopenOperationID - sends the value as a return code for EXEC callers.
- Both paths return the same value. Callers that use RETURN codes will get it there; callers that read result sets get it from SELECT.
- Note: RETURN with a non-zero/non-error value is unconventional in SQL Server (typically 0=success, negative=error), but is used here for convenience.

### 2.2 ReopenType Classification

**What**: @ReopenOperationType (defaults to 1) determines whether this is a position reopen or mirror reopen operation.

**Columns/Parameters Involved**: `@ReopenOperationType`, `ReopenTypeID`

**Rules**:
- 1 = Position reopen (default) - child rows go into Trade.PositionToReopen; execution via Trade.PositionsReopen.
- 2 = Mirror reopen - child rows go into Trade.MirrorToReopen; execution via Trade.MirrorsReopen.
- Stored as ReopenTypeID in Trade.ReopenOperation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | VARCHAR(255) | NO | - | CODE-BACKED | The back-office username or automated process name initiating this reopen. Written to Trade.ReopenOperation.UserName. Used for audit trail. |
| 2 | @ValidateUserBalance | TINYINT | NO | 0 | CODE-BACKED | Whether to validate customer balance before reopening. 0=skip balance check (default), 1=validate. Written to Trade.ReopenOperation.ValidateUserBalance. |
| 3 | @RequestedStopRate | dtPrice | YES | NULL | CODE-BACKED | Optional stop-loss rate to apply to reopened positions. NULL=use original SL. Written to Trade.ReopenOperation.RequestedStopRate. |
| 4 | @RequestedLimitRate | dtPrice | YES | NULL | CODE-BACKED | Optional take-profit rate to apply to reopened positions. NULL=use original TP. Written to Trade.ReopenOperation.RequestedLimitRate. |
| 5 | @CompensateOnStopLossDelta | TINYINT | NO | 0 | CODE-BACKED | Whether to compensate customers for any stop-loss delta from the original. 0=no compensation (default), 1=compensate. Written to Trade.ReopenOperation.CompensateOnStopLossDelta. |
| 6 | @IsManual | TINYINT | NO | 1 | CODE-BACKED | Whether this is a manually initiated reopen (1=manual, 0=automated). Default 1. Written to Trade.ReopenOperation.IsManual. Automated callers (e.g., Trade.ReopenForUnalignedSlCryptoPositions) pass 0. |
| 7 | @ReopenOperationType | TINYINT | NO | 1 | CODE-BACKED | Reopen type: 1=Position reopen (default), 2=Mirror reopen. Written to Trade.ReopenOperation.ReopenTypeID. Determines which child table and execution procedure to use. |
| 8 | @AllowUpdateMirrorSL | BIT | NO | 0 | CODE-BACKED | Whether to allow updating the mirror stop-loss when reopening. 0=do not update (default), 1=allow update. Written to Trade.ReopenOperation.AllowUpdateMirrorSL. |
| 9 | @AuditReopenDescription | VARCHAR(2000) | YES | NULL | CODE-BACKED | Free-text description of why the reopen is being performed. Written to Trade.ReopenOperation.ReopenDescription. Used for audit trail. |
| 10 | @AuditReopenReasonID | INT | YES | NULL | CODE-BACKED | Structured reason code for the reopen. Written to Trade.ReopenOperation.ReopenReasonID. FK to reason code lookup table. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 11 | ReopenOperationID | int | NO | - | CODE-BACKED | The new ReopenOperationID generated by SCOPE_IDENTITY() after INSERT. Also returned via RETURN for EXEC-based callers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (procedure) | Trade.ReopenOperation | Writer (INSERT) | Creates a new parent reopen operation row. |
| @ReopenOperationType | Dictionary.ReopenType | Implicit | Values 1=Position, 2=Mirror per Dictionary.ReopenType lookup. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ReopenForUnalignedSlCryptoPositions | - | Caller | Automated reopen for crypto positions with misaligned SL. Calls this with IsManual=0. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReopenOperationAdd (procedure)
└── Trade.ReopenOperation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReopenOperation | Table | INSERT - creates a new reopen operation header row. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReopenForUnalignedSlCryptoPositions | Procedure | Calls this (via batch #23) to create reopen operations for crypto SL misalignment correction. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a manual position reopen operation

```sql
DECLARE @NewID INT;
EXEC @NewID = Trade.ReopenOperationAdd
    @UserName = 'ops.user@etoro.com',
    @ValidateUserBalance = 1,
    @RequestedStopRate = NULL,
    @RequestedLimitRate = NULL,
    @CompensateOnStopLossDelta = 0,
    @IsManual = 1,
    @ReopenOperationType = 1,
    @AllowUpdateMirrorSL = 0,
    @AuditReopenDescription = 'Position closed incorrectly during settlement',
    @AuditReopenReasonID = 5;
SELECT @NewID AS CreatedReopenOperationID;
```

### 8.2 Create an automated mirror reopen operation

```sql
EXEC Trade.ReopenOperationAdd
    @UserName = 'AutomatedJob',
    @ValidateUserBalance = 0,
    @IsManual = 0,
    @ReopenOperationType = 2,
    @AllowUpdateMirrorSL = 1;
```

### 8.3 Verify created operation

```sql
SELECT TOP 1 ReopenOperationID, Occurred, UserName, IsManual, ReopenTypeID, IsExecuted
FROM Trade.ReopenOperation WITH (NOLOCK)
ORDER BY ReopenOperationID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenOperationAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReopenOperationAdd.sql*
