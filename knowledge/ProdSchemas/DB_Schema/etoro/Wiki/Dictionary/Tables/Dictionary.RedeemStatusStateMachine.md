# Dictionary.RedeemStatusStateMachine

> State machine table defining the 31 valid status transitions for redeem (copy-fund exit) processing — from New through PositionPending, Approved, ReadyToRedeem, PositionClosing, PositionClosed, TransactionInProcess to TransactionDone, with Rejected/Terminated/FailedToCancel error paths.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (State Machine) |
| **Key Identifier** | Composite PK (FromStatusID, ToStatusID) |
| **Partition** | MAIN filegroup |
| **Row Count** | 31 (MCP verified) |
| **Indexes** | 1 active (composite PK clustered) |

---

## 1. Business Meaning

Dictionary.RedeemStatusStateMachine is a state transition table that governs which status changes are valid during redeem (copy-fund exit) processing. Unlike simple lookup tables, this table defines a graph of allowed transitions — each row is an edge from one RedeemStatus to another. Before any status update, the system validates that the proposed transition exists in this table.

The state machine enforces a structured processing pipeline: a redemption starts as New (100), transitions through PositionPending (1) where positions are queued for closure, gets Approved (3), becomes ReadyToRedeem (4) when all conditions are met, enters PositionClosing (5) as positions are actually closed, reaches PositionClosed (6), then TransactionInProcess (7) as funds are transferred, and finally TransactionDone (8) upon completion.

At almost every stage, the redemption can be diverted to error states: Rejected (2) for validation failures, Terminated (20) for hard stops, or FailedToCancel (21) for cancel failures. A special TransferNegativeBalance (25) state handles cases where the copy has negative equity.

Billing.RedeemStatusUpdate validates transitions by querying `WHERE FromStatusID = @OldRedeemStatusID AND ToStatusID = @RedeemStatusID` — if no row matches, the transition is blocked.

---

## 2. Business Logic

### 2.1 Happy Path Flow

**What**: The normal (successful) redeem processing flow.

**Columns/Parameters Involved**: `FromStatusID`, `ToStatusID`

**Rules**:
- New (100) → PositionPending (1): Redemption request accepted, positions queued
- PositionPending (1) → Approved (3): Pre-validation passed
- Approved (3) → ReadyToRedeem (4): All conditions met, ready to execute
- ReadyToRedeem (4) → PositionClosing (5): Position closure initiated
- PositionClosing (5) → PositionClosed (6): All positions successfully closed
- PositionClosed (6) → TransactionInProcess (7): Fund transfer initiated
- TransactionInProcess (7) → TransactionDone (8): Funds transferred, redemption complete

**Diagram**:
```
Happy Path:
  New (100) ──► PositionPending (1) ──► Approved (3) ──► ReadyToRedeem (4)
                                                              │
       ┌──────────────────────────────────────────────────────┘
       │
       ▼
  PositionClosing (5) ──► PositionClosed (6) ──► TransactionInProcess (7) ──► TransactionDone (8)
```

### 2.2 Error and Alternative Paths

**What**: Error handling, rejection, and special case transitions.

**Columns/Parameters Involved**: `FromStatusID`, `ToStatusID`

**Rules**:
- **Rejection**: PositionPending → Rejected (2), ReadyToRedeem → Rejected (2), TransactionInProcess → Rejected (2). Redemption can be rejected at multiple stages.
- **Termination**: Almost every state can transition to Terminated (20) — hard stop for cancellation, system errors, or administrative decisions. States: New, PositionPending, Rejected, Approved, ReadyToRedeem, PositionClosing, PositionClosed, TransferNegativeBalance.
- **FailedToCancel (21)**: When a cancellation attempt fails. Can occur from: New, PositionPending, Rejected, Approved, ReadyToRedeem, PositionClosing, PositionClosed, TransactionInProcess.
- **Negative Balance (25)**: ReadyToRedeem → TransferNegativeBalance (25) when copy has negative equity. TransferNegativeBalance → ReadyToRedeem (4) when balance is resolved. TransferNegativeBalance → Terminated (20) if unresolvable.
- **Self-transition**: PositionPending (1) → PositionPending (1) — allows re-processing within the pending state.
- **Recovery**: Rejected (2) → Approved (3) — a previously rejected redemption can be re-approved.
- **Skip**: ReadyToRedeem (4) → PositionClosed (6) — positions may already be closed (no closing needed).

---

## 3. Data Overview

### State Transition Matrix

| From State | Valid Transitions To |
|---|---|
| New (100) | PositionPending (1), Terminated (20), FailedToCancel (21) |
| PositionPending (1) | PositionPending (1), Rejected (2), Approved (3), Terminated (20), FailedToCancel (21) |
| Rejected (2) | Approved (3), Terminated (20), FailedToCancel (21) |
| Approved (3) | ReadyToRedeem (4), Terminated (20), FailedToCancel (21) |
| ReadyToRedeem (4) | Rejected (2), PositionClosing (5), PositionClosed (6), Terminated (20), FailedToCancel (21), TransferNegativeBalance (25) |
| PositionClosing (5) | PositionClosed (6), Terminated (20), FailedToCancel (21) |
| PositionClosed (6) | TransactionInProcess (7), Terminated (20), FailedToCancel (21) |
| TransactionInProcess (7) | Rejected (2), TransactionDone (8), FailedToCancel (21) |
| TransferNegativeBalance (25) | ReadyToRedeem (4), Terminated (20) |

### Terminal States

- **TransactionDone (8)**: Success — no outgoing transitions
- **Terminated (20)**: Hard stop — no outgoing transitions (terminal error)
- **FailedToCancel (21)**: Cancel failure — no outgoing transitions (terminal error)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FromStatusID | int | NO | - | VERIFIED | Source status in the transition. FK to Dictionary.RedeemStatus.RedeemStatusID. Combined with ToStatusID forms the composite PK. Validated by Billing.RedeemStatusUpdate before allowing status changes. |
| 2 | ToStatusID | int | NO | - | VERIFIED | Target status in the transition. FK to Dictionary.RedeemStatus.RedeemStatusID. If no row exists for a given (FromStatusID, ToStatusID) pair, the transition is blocked — this is the enforcement mechanism. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.RedeemStatus | RedeemStatusID | Explicit FK (FK_RedeemStatusStateMachine_RedeemStatus) | FromStatusID references valid redeem statuses |
| Dictionary.RedeemStatus | RedeemStatusID | Explicit FK (FK_RedeemStatusStateMachine_RedeemStatus1) | ToStatusID references valid redeem statuses |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RedeemStatusUpdate | FromStatusID, ToStatusID | WHERE validation | Validates that proposed status transition is allowed before executing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.RedeemStatus (table)
  ▲
  └── Dictionary.RedeemStatusStateMachine (FK on both FromStatusID and ToStatusID)
        └── validated by Billing.RedeemStatusUpdate
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RedeemStatus | Table | FK on FromStatusID and ToStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemStatusUpdate | Stored Procedure | Validates transitions before execution |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RedeemStatusStateMachine | CLUSTERED PK | FromStatusID ASC, ToStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RedeemStatusStateMachine | PRIMARY KEY | Composite key (FromStatusID, ToStatusID), FILLFACTOR 95, MAIN filegroup |
| FK_RedeemStatusStateMachine_RedeemStatus | FOREIGN KEY | FromStatusID → Dictionary.RedeemStatus.RedeemStatusID |
| FK_RedeemStatusStateMachine_RedeemStatus1 | FOREIGN KEY | ToStatusID → Dictionary.RedeemStatus.RedeemStatusID |

---

## 8. Sample Queries

### 8.1 List all valid transitions with status names
```sql
SELECT  f.Name              AS FromStatus,
        t.Name              AS ToStatus
FROM    Dictionary.RedeemStatusStateMachine sm WITH (NOLOCK)
JOIN    Dictionary.RedeemStatus f WITH (NOLOCK)
        ON sm.FromStatusID = f.RedeemStatusID
JOIN    Dictionary.RedeemStatus t WITH (NOLOCK)
        ON sm.ToStatusID = t.RedeemStatusID
ORDER BY sm.FromStatusID, sm.ToStatusID;
```

### 8.2 Check if a specific transition is allowed
```sql
SELECT  CASE WHEN EXISTS (
            SELECT  1
            FROM    Dictionary.RedeemStatusStateMachine WITH (NOLOCK)
            WHERE   FromStatusID = @CurrentStatus
                    AND ToStatusID = @ProposedStatus
        ) THEN 'ALLOWED' ELSE 'BLOCKED' END AS TransitionResult;
```

### 8.3 Find terminal states (no outgoing transitions)
```sql
SELECT  rs.RedeemStatusID,
        rs.Name
FROM    Dictionary.RedeemStatus rs WITH (NOLOCK)
WHERE   NOT EXISTS (
            SELECT  1
            FROM    Dictionary.RedeemStatusStateMachine sm WITH (NOLOCK)
            WHERE   sm.FromStatusID = rs.RedeemStatusID
        );
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (31 transitions) and codebase analysis of Billing.RedeemStatusUpdate transition validation.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RedeemStatusStateMachine | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RedeemStatusStateMachine.sql*
