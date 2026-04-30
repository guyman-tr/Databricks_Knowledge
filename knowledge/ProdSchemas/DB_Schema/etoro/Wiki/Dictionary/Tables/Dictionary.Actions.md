# Dictionary.Actions

> Lookup table defining the 12 async action types — position operations, login events, CopyTrading operations, and customer lifecycle events — that can be queued for step-by-step execution in the Internal action engine.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ActionID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Actions defines the action types that can be processed by the Internal async action execution engine. Each action represents a multi-step operation that is broken down into discrete steps (tracked in Internal.ActionSteps) and queued for asynchronous execution.

This table is the backbone of the platform's async processing framework. Complex operations like closing a position, editing a stop loss, or handling CopyTrading (MIMO) operations are decomposed into ordered steps. The engine picks up queued actions, executes each step, and tracks completion. This architecture ensures reliability and recoverability for critical financial operations.

Actions are queued into Internal.ActionsToExecute_EditStopLoss and Internal.ActionsToExecute_MIMOOperations (both with FK constraints pointing back to Dictionary.Actions). Each action has its execution steps defined in Internal.ActionSteps. History.ActionsLog and History.ActionsLog_EditStopLoss track completed action executions for audit purposes.

---

## 2. Business Logic

### 2.1 Action Categories

**What**: Classification of async operations processed by the Internal action engine.

**Columns/Parameters Involved**: `ActionID`, `ActionName`

**Rules**:
- **Trade operations (1-5)**: PositionClose (1), PositionOpen (2), EditStopLoss (4), PositionFail (5) — core trading actions that modify positions
- **Session events (3)**: LogIn (3) — post-login operations triggered asynchronously
- **CopyTrading (6-7)**: DetachMirrorPosition (6), MIMO Operations (7) — Mirror/In/Mirror/Out copy-trade lifecycle operations
- **Customer lifecycle (8-10, 12)**: PostRegisterOperations (8), PostUpdateBasicUserInfo (9), PostUpdateContactUserInfo (10), PostUpdateRiskUserInfo (12) — post-registration and post-update hooks that run asynchronously
- **Change tracking (11)**: AsyncOrdersChangeLog (11) — async logging of order changes

**Diagram**:
```
Internal Action Engine:

  Queue (ActionsToExecute_*)          Steps (ActionSteps)         Log (ActionsLog)
  ──────────────────────────          ────────────────────         ────────────────
  ActionID ──FK──► Dictionary.Actions  ActionID ──FK──► Dictionary.Actions
       │                                    │
       └── Step 1 → Step 2 → Step N ──────►└── Completed → History.ActionsLog
```

---

## 3. Data Overview

| ActionID | ActionName | Meaning |
|---|---|---|
| 1 | PositionClose | Async position close operation — decomposes into steps like calculating P&L, releasing margin, updating history, and notifying the user. |
| 2 | PositionOpen | Async position open operation — validates margin, creates position record, sets up monitoring. |
| 6 | DetachMirrorPosition | Detaches a copied position from its CopyTrading leader. The position remains open but no longer mirrors leader trades. |
| 7 | MIMO Operations | Mirror/In/Mirror/Out — handles the full lifecycle of CopyTrading relationships including copying positions, stopping copy, and fund allocation. |
| 8 | Customer.PostRegisterOperations | Post-registration hooks executed asynchronously after a customer completes sign-up: CRM sync, default settings, welcome notifications. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionID | int | NO | - | VERIFIED | Primary key identifying the action type. Referenced by FK from Internal.ActionsToExecute_EditStopLoss, Internal.ActionsToExecute_MIMOOperations, and Internal.ActionSteps. Values 1-12 covering trade, session, CopyTrading, and customer lifecycle actions. |
| 2 | ActionName | varchar(50) | NO | - | VERIFIED | Human-readable name of the action. Often matches the procedure or service method name that initiates the action (e.g., 'Customer.PostRegisterOperations'). Used in logging and monitoring to identify what operation is being processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.ActionsToExecute_EditStopLoss | ActionID | Explicit FK | Queue of edit-stop-loss actions awaiting execution |
| Internal.ActionsToExecute_MIMOOperations | ActionID | Explicit FK | Queue of CopyTrading MIMO actions awaiting execution |
| Internal.ActionSteps | ActionID | Explicit FK | Execution steps defined for each action type |
| History.ActionsLog | ActionID | Implicit | Completed action execution history |
| History.ActionsLog_EditStopLoss | ActionID | Implicit | Completed edit-stop-loss action history |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.ActionsToExecute_EditStopLoss | Table | FK — action execution queue |
| Internal.ActionsToExecute_MIMOOperations | Table | FK — MIMO action queue |
| Internal.ActionSteps | Table | FK — step definitions per action |
| History.ActionsLog | Table | Action execution audit trail |
| History.ActionsLog_EditStopLoss | Table | Edit SL action audit trail |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryActions | CLUSTERED PK | ActionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryActions | PRIMARY KEY | Unique action type identifier on PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all action types
```sql
SELECT  ActionID,
        ActionName
FROM    Dictionary.Actions WITH (NOLOCK)
ORDER BY ActionID;
```

### 8.2 Show action steps per action type
```sql
SELECT  da.ActionName,
        das.*
FROM    Internal.ActionSteps das WITH (NOLOCK)
JOIN    Dictionary.Actions da WITH (NOLOCK)
        ON das.ActionID = da.ActionID
ORDER BY da.ActionID, das.ActionID;
```

### 8.3 Find queued MIMO operations with action names
```sql
SELECT  da.ActionName,
        ate.*
FROM    Internal.ActionsToExecute_MIMOOperations ate WITH (NOLOCK)
JOIN    Dictionary.Actions da WITH (NOLOCK)
        ON ate.ActionID = da.ActionID
ORDER BY ate.ActionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Actions | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Actions.sql*
