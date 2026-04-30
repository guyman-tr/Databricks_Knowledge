# Saga.InsertSagaRunStatus

> Atomically transitions a saga run to a new status, updating the current state in SagaRuns and logging the transition to SagaRunStatuses in a single OUTPUT operation.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: UpdateStatus BIT (1=success, 0=saga not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertSagaRunStatus is the saga status transition procedure - the mechanism by which a saga moves from one lifecycle state to another. It atomically updates the current status in SagaRuns AND logs the transition to SagaRunStatuses using an OUTPUT clause, ensuring the history is always in sync with the current state.

This is one of the most critical procedures in the saga system. Every status change (Start -> Completed, Start -> Rollback, Rollback -> Failed, etc.) flows through this procedure. It is called by the saga orchestrator whenever a step succeeds, fails, or requires saga-level state change.

---

## 2. Business Logic

### 2.1 Atomic Status Update + History Logging

**What**: Uses OUTPUT clause to simultaneously update SagaRuns and INSERT into SagaRunStatuses.

**Columns/Parameters Involved**: `@SagaKey`, `@SagaStatusTypeId`

**Rules**:
- UPDATE SagaRuns SET SagaStatusTypeId = @SagaStatusTypeId WHERE SagaKey = @SagaKey
- OUTPUT INSERTED.Id, GETUTCDATE(), @SagaStatusTypeId INTO SagaRunStatuses
- Returns UpdateStatus BIT: 1 if @@rowcount > 0, 0 if saga not found
- Identifies saga by SagaKey (GUID), not by Id (bigint)
- No validation that the new status is a valid transition from the current status - the application layer enforces the state machine

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level identifier of the saga run to transition. Used in WHERE clause to find the SagaRuns row. |
| 2 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | New status to assign. 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). |

**Return:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | UpdateStatus | BIT | VERIFIED | 1 = status updated successfully, 0 = SagaKey not found (no rows affected) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | UPDATE target | Updates SagaStatusTypeId for the matching saga |
| OUTPUT | Saga.SagaRunStatuses | INSERT (via OUTPUT) | Logs the transition atomically |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.InsertSagaRunStatus (procedure)
├── Saga.SagaRuns (table)
└── Saga.SagaRunStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | UPDATE target - changes SagaStatusTypeId |
| Saga.SagaRunStatuses | Table | INSERT target (via OUTPUT) - logs transition |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Transition saga to Completed
```sql
EXEC Saga.InsertSagaRunStatus @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E', @SagaStatusTypeId = 3
```

### 8.2 Transition saga to Rollback
```sql
EXEC Saga.InsertSagaRunStatus @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E', @SagaStatusTypeId = 2
```

### 8.3 Verify transition was recorded
```sql
SELECT rs.SagaRunId, st.Name AS Status, rs.Created
FROM Saga.SagaRunStatuses rs WITH (NOLOCK)
INNER JOIN Saga.SagaStatusTypes st WITH (NOLOCK) ON st.Id = rs.SagaStatusTypeId
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = rs.SagaRunId
WHERE sr.SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
ORDER BY rs.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.InsertSagaRunStatus | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.InsertSagaRunStatus.sql*
