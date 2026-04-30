# Dictionary.Steps

## 1. Business Meaning

**What it is**: A registry table mapping step IDs to stored procedure names for the platform's asynchronous action execution framework. Each step represents a "post-action" procedure that runs asynchronously after a primary trading or customer operation completes.

**Why it exists**: Many trading and customer operations trigger follow-up actions that should not block the primary operation (e.g., logging, analytics, mirror operations). The async execution framework (`Internal.AsyncExecuter*` procedures) uses this table to resolve which stored procedure to call for each step. The step registry also syncs to the `DB_Logs` database via triggers for cross-database monitoring.

**How it works**: The `Internal.ActionSteps` table queues pending async actions with a `StepID`. The family of `Internal.AsyncExecuter` procedures (1-9 + specialized variants for MIMO, Registration, EditStopLoss) dequeue actions and use `StepID` to resolve the procedure name from this table. INSERT/UPDATE/DELETE triggers on this table sync changes to the `DBLogs_Dictionary_Steps` synonym (pointing to `DB_Logs.Dictionary.Steps`) for cross-database consistency.

---

## 2. Business Logic

### Async Post-Action Steps
| StepID | ProcName | Trigger Event |
|--------|----------|---------------|
| 1 | Trade.PostClosePositionActions | After position close |
| 2 | Trade.PostOpenPositionActions | After position open |
| 3 | History.PostLogIn | After user login |
| 4 | Trade.PostEditStopLossPosition | After stop-loss edit |
| 5 | History.PostPositionFail | After position failure |
| 6 | History.PostDetachMirrorPosition | After mirror detach |
| 7 | Customer.PostMIMOOperations | After MIMO (Move In/Move Out) |
| 8 | Customer.PostRegisterOperations | After customer registration |
| 9 | Customer.PostUpdateBasicUserInfo | After basic info update |
| 10 | Customer.PostUpdateContactUserInfo | After contact info update |
| 11 | Trade.AsyncOrdersChangeLog | After order changes |
| 12 | Customer.PostUpdateRiskUserInfo | After risk info update |

### Execution Pattern
```
Primary operation → INSERT into Internal.ActionSteps (StepID, parameters)
    → Internal.AsyncExecuter{N} picks up action
    → Resolves ProcName from Dictionary.Steps
    → EXEC @ProcName with parameters
    → Action logged to DB_Logs
```

---

## 3. Data Overview

| StepID | ProcName | Business Meaning |
|--------|----------|------------------|
| 1 | Trade.PostClosePositionActions | Post-close async processing |
| 2 | Trade.PostOpenPositionActions | Post-open async processing |
| 7 | Customer.PostMIMOOperations | Post-MIMO async processing |
| 8 | Customer.PostRegisterOperations | Post-registration async processing |

*12 rows — all async post-action procedures in the execution framework*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **StepID** | int | NOT NULL | — | Primary key. Async step identifier. Range: 1-12. Maps 1:1 to a specific post-action stored procedure. | `MCP` |
| **ProcName** | varchar(60) | NOT NULL | — | Fully qualified stored procedure name (schema.name). The async executor calls this procedure when processing actions with this StepID. | `MCP+CODE` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf registry table.*

### Referenced By (other objects point to this table)
| Referencing Object | Column | Relationship | Business Meaning |
|-------------------|--------|--------------|------------------|
| Internal.ActionSteps | StepID | Implicit FK | Queued async actions reference step definitions |
| Internal.AsyncExecuter (1-9) | StepID | Lookup | 9+ async executor procedures resolve ProcName by StepID |
| Internal.AsyncExecuter_MIMO | StepID | Lookup | MIMO-specific async executor |
| Internal.AsyncExecuter_Registration | StepID | Lookup | Registration-specific async executor |
| Internal.AsyncExecuter_EditStopLoss | StepID | Lookup | Stop-loss edit-specific async executor |
| DBLogs_Dictionary_Steps | StepID | Trigger sync | Cross-database replication via synonym |

---

## 6. Dependencies

### Depends On
*None — leaf registry table.*

### Depended On By
- `Internal.ActionSteps` — async action queue
- 12+ `Internal.AsyncExecuter*` procedures — async execution framework
- `DB_Logs.Dictionary.Steps` — cross-database monitoring (via synonym + triggers)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `StepID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Triggers | `Tr_IUASteps` (INSERT/UPDATE → MERGE to DB_Logs), `Tr_DASteps` (DELETE → DELETE from DB_Logs) |
| Filegroup | PRIMARY |
| Row Count | 12 |

---

## 8. Sample Queries

```sql
-- Get all async steps
SELECT  StepID, ProcName
FROM    Dictionary.Steps WITH (NOLOCK)
ORDER BY StepID;

-- Find trading-related async steps
SELECT  StepID, ProcName
FROM    Dictionary.Steps WITH (NOLOCK)
WHERE   ProcName LIKE 'Trade.%'
ORDER BY StepID;

-- Check pending actions by step
SELECT  S.ProcName, COUNT(*) AS PendingActions
FROM    Internal.ActionSteps A WITH (NOLOCK)
JOIN    Dictionary.Steps S WITH (NOLOCK) ON S.StepID = A.StepID
GROUP BY S.ProcName
ORDER BY PendingActions DESC;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. The async execution framework is an internal infrastructure component for post-action processing.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (12 rows), codebase traced (12+ AsyncExecuter consumers, cross-database triggers, Internal.ActionSteps queue)*
