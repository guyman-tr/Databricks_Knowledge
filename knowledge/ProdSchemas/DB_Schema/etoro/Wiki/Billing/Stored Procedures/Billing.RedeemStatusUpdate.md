# Billing.RedeemStatusUpdate

> The state-machine enforcer for the Redeem lifecycle: validates and applies status transitions on a redeem record, with optional updates to settlement amount, units, manager, and remarks.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID + @PositionID (dual-key safety check) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Every status change on a customer's redemption request must pass through `Billing.RedeemStatusUpdate`. It is the single, authoritative write path for changing `Billing.Redeem.RedeemStatusID`. Before applying any change, it validates the transition against `Dictionary.RedeemStatusStateMachine` - a lookup table that defines which status-to-status transitions are permitted in the business workflow.

The procedure exists to prevent illegal state transitions (e.g., jumping from "Pending" directly to "Completed" without passing through intermediate states). This enforces the redeem lifecycle business rules in the database layer, not just in application code.

It also handles special behavior when transitioning to status 6 (PositionClosed): at that point, it updates the final settlement amount (AmountOnClose) and units count, which are only known after the position has been successfully closed by the trading engine.

Called directly by `Billing.RedeemStatusUpdateByPosition` (which resolves RedeemID from PositionID first) and by `Billing.RedeemPayoutProcess_UpdateStatus` (which also releases processing locks).

---

## 2. Business Logic

### 2.1 State Machine Validation

**What**: All status transitions are validated against Dictionary.RedeemStatusStateMachine before applying.

**Columns/Parameters Involved**: `RedeemStatusID`, `@RedeemStatusID`, `Dictionary.RedeemStatusStateMachine`

**Rules**:
- Before any UPDATE, queries current `RedeemStatusID` from Billing.Redeem.
- Checks `Dictionary.RedeemStatusStateMachine` WHERE `FromStatusID = current` AND `ToStatusID = @RedeemStatusID`.
- If no matching row found: raises RAISERROR(60025) with message "An attempt to modify redeem status from X to Y."
- If found: proceeds with UPDATE.
- After UPDATE: if @@ROWCOUNT=0, raises RAISERROR with "Did not find any record" message (RedeemID/PositionID mismatch safety).

**Diagram**:
```
GET current RedeemStatusID for @RedeemID
     |
     v
CHECK Dictionary.RedeemStatusStateMachine (FromStatusID -> ToStatusID)
     |
     +-- NOT found --> RAISERROR(60025) "Attempt to modify from X to Y"
     |
     +-- Found --> UPDATE Billing.Redeem:
                    RedeemStatusID = @RedeemStatusID (always)
                    RedeemReasonID = @RedeemReasonID (if non-null/non-zero)
                    Remark = @Remark (if non-null)
                    ManagerID = @ManagerID (if non-null)
                    ManagerOpsID = @ManagerOpsId (if non-null)
                    IF @RedeemStatusID = 6 (PositionClosed):
                        AmountOnClose = @Amount
                        Units = ISNULL(@Units, Units)
                    LastModificationDate = GETUTCDATE()
                    WHERE RedeemID = @RedeemID AND PositionID = @PositionID
```

### 2.2 Settlement Finalization on Status 6

**What**: When transitioning to status 6 (PositionClosed), the final settlement data is recorded.

**Columns/Parameters Involved**: `@RedeemStatusID`, `@Amount`, `@Units`, `AmountOnClose`, `Units`

**Rules**:
- `IIF(@RedeemStatusID = 6, @Amount, AmountOnClose)`: AmountOnClose is only updated on the 6 transition.
- `IIF(@RedeemStatusID = 6, ISNULL(@Units, Units), Units)`: Units also only updated on 6 transition.
- This ensures that the requested amount (AmountOnRequest) is not overwritten - only AmountOnClose (the settlement value) changes.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemID | INT | NO | - | CODE-BACKED | Primary key of the Billing.Redeem row to update. Combined with @PositionID for a dual-key safety check (WHERE clause). |
| 2 | @PositionID | BIGINT | NO | - | CODE-BACKED | Expected PositionID on the redeem record. Acts as a safety check - if the RedeemID maps to a different PositionID, the UPDATE finds 0 rows and raises an error. BIGINT since June 2021. |
| 3 | @RedeemStatusID | INT | NO | - | CODE-BACKED | Target status to transition to. Must exist in Dictionary.RedeemStatusStateMachine as a valid transition from the current status. Error 60025 if invalid. |
| 4 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Reason code for the status change. Updated only when non-null and non-zero (preserves existing value if omitted). |
| 5 | @Remark | VARCHAR(500) | YES | NULL | CODE-BACKED | Free-text remark or note. Updated only when non-null (preserves existing). |
| 6 | @Amount | MONEY | YES | NULL | CODE-BACKED | Final settlement amount. Only applied to AmountOnClose when @RedeemStatusID=6 (PositionClosed). Ignored for other transitions. |
| 7 | @Units | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Final unit count after close. Only applied when @RedeemStatusID=6. ISNULL(@Units, Units) preserves existing if not provided. |
| 8 | @ManagerID | INT | YES | NULL | CODE-BACKED | Back-office manager ID. Updated via ISNULL(@ManagerID, ManagerID) - preserves existing if not provided. |
| 9 | @ManagerOpsId | INT | YES | NULL | CODE-BACKED | Operations manager ID. Updated via ISNULL(@ManagerOpsId, ManagerOpsID) - preserves existing if not provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedeemID, @PositionID | Billing.Redeem | UPDATE | Core status update and conditional field updates |
| @RedeemStatusID | Dictionary.RedeemStatusStateMachine | Lookup | Validates the FromStatusID -> ToStatusID transition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RedeemStatusUpdateByPosition | EXEC callee | Direct call | Wrapper that resolves RedeemID from PositionID then calls this |
| Billing.RedeemPayoutProcess_UpdateStatus | EXEC callee | Direct call | Orchestrator that releases lock then calls this |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemStatusUpdate (procedure)
├── Billing.Redeem (table)
└── Dictionary.RedeemStatusStateMachine (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Current status SELECT + status UPDATE |
| Dictionary.RedeemStatusStateMachine | Table | State transition validation lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemStatusUpdateByPosition | Procedure | Calls this after looking up RedeemID from PositionID |
| Billing.RedeemPayoutProcess_UpdateStatus | Procedure | Calls this as part of the lock-release + status-update transaction |
| Billing.SetRedeemStatus | Procedure | Direct bulk UPDATE (bypasses state machine - different use case) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| State machine check | Business rule | Transition must exist in Dictionary.RedeemStatusStateMachine. Error 60025 on invalid transition. |
| Dual-key WHERE | Data integrity | UPDATE WHERE RedeemID = @RedeemID AND PositionID = @PositionID prevents mismatched updates. |
| Conditional AmountOnClose | Status-driven | AmountOnClose and Units only updated on status 6 transition. |

---

## 8. Sample Queries

### 8.1 Transition redeem to PositionClosed (status 6) with settlement amount

```sql
EXEC Billing.RedeemStatusUpdate
    @RedeemID = 1001,
    @PositionID = 9876543210,
    @RedeemStatusID = 6,
    @Amount = 485.50,
    @Units = 9.75000000
```

### 8.2 Update redeem with a reason and remark (no amount change)

```sql
EXEC Billing.RedeemStatusUpdate
    @RedeemID = 1002,
    @PositionID = 9876543211,
    @RedeemStatusID = 20,  -- Terminated
    @RedeemReasonID = 5,
    @Remark = 'Customer cancelled via support ticket',
    @ManagerID = 99999
```

### 8.3 View the valid state transitions defined in the state machine

```sql
SELECT rsm.FromStatusID, rs_from.Name AS FromStatus,
       rsm.ToStatusID, rs_to.Name AS ToStatus
FROM Dictionary.RedeemStatusStateMachine rsm WITH (NOLOCK)
JOIN Dictionary.RedeemStatus rs_from WITH (NOLOCK) ON rs_from.RedeemStatusID = rsm.FromStatusID
JOIN Dictionary.RedeemStatus rs_to WITH (NOLOCK) ON rs_to.RedeemStatusID = rsm.ToStatusID
ORDER BY rsm.FromStatusID, rsm.ToStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callers analyzed (RedeemStatusUpdateByPosition, RedeemPayoutProcess_UpdateStatus) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemStatusUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemStatusUpdate.sql*
