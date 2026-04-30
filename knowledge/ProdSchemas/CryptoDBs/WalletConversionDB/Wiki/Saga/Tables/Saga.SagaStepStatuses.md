# Saga.SagaStepStatuses

> Append-only audit trail recording every status transition for individual saga steps, providing granular execution history for debugging, retry tracking, and step-level lifecycle analysis.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + 1 NC) |

---

## 1. Business Meaning

SagaStepStatuses is an append-only history table recording every status transition for each saga step. While `Saga.SagaSteps.StepStatusTypeId` stores only the current status, this table preserves the full timeline of each step's execution - including retry attempts, scheduling, and eventual completion or failure. With ~6.4 entries per step on average (1.16M rows / 181K steps), it captures a significantly richer execution story than the step table alone.

Without this table, operators would have no visibility into step-level retry behavior, execution timing, or the progression of long-running steps through multiple status changes. When investigating conversion failures, the step status history reveals whether a step was retried, how many times, and the timing between attempts.

Rows are created by two procedures: `Saga.InsertSagaStep` inserts the initial status atomically with the step row, and `Saga.InsertSagaStepStatus` uses an OUTPUT clause to atomically capture each subsequent status change from SagaSteps into this table.

---

## 2. Business Logic

### 2.1 Step Execution Patterns

**What**: The status history reveals common step execution patterns including retries and scheduling cycles.

**Columns/Parameters Involved**: `SagaStepId`, `StepStatusTypeId`, `Created`

**Rules**:
- Simple success path: Start (1) -> Done (4) - 2 entries per step
- Retry path: Start (1) -> Failed (2) -> Retry (3) -> Start (1) -> Done (4) - 5 entries per step
- Scheduled execution: Schedule (5) -> Start (1) -> Done (4) - 3 entries per step
- The ~6.4 average entries per step indicates many steps go through scheduling and/or retry cycles
- Live data shows step 180967 cycling between Schedule (5) and Start (1), indicating polling/scheduling behavior
- Timestamps between entries reveal wait times between retries and scheduling delays

### 2.2 Atomic Status Logging via OUTPUT Clause

**What**: InsertSagaStepStatus uses SQL OUTPUT clause to ensure step status history is never out of sync with the current step status.

**Columns/Parameters Involved**: `SagaStepId`, `Created`, `StepStatusTypeId`

**Rules**:
- InsertSagaStepStatus UPDATEs SagaSteps.StepStatusTypeId and uses `OUTPUT @SagaStepId, GETUTCDATE(), @StepStatusTypeId INTO Saga.SagaStepStatuses`
- This is identical to the pattern used for SagaRunStatuses - atomic, race-condition-free logging
- The Created timestamp is set to GETUTCDATE() in the OUTPUT clause

---

## 3. Data Overview

| Id | SagaStepId | StepStatusTypeId | Created | Meaning |
|----|-----------|------------------|---------|---------|
| 1157217 | 180967 | 1 (Start) | 2026-04-15 08:46:23 | Step 180967 execution began. First active-state entry for this execution attempt. |
| 1157218 | 180967 | 5 (Schedule) | 2026-04-15 08:46:23 | Same step immediately scheduled (same second as Start) - indicates the step dispatched work and moved to polling state. |
| 1157216 | 180966 | 4 (Done) | 2026-04-15 08:46:23 | Step 180966 completed successfully. Terminal entry for this step. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate primary key. Provides global chronological ordering of all step status transitions. |
| 2 | SagaStepId | bigint | NO | - | VERIFIED | Foreign key to Saga.SagaSteps.Id identifying which step this status transition belongs to. Multiple rows per SagaStepId (one per transition). Indexed with Created (DESC) for most-recent-first retrieval. |
| 3 | Created | datetime2(7) | NO | - | VERIFIED | UTC timestamp when the status transition occurred. Set to GETUTCDATE() either in InsertSagaStep (initial) or via OUTPUT clause in InsertSagaStepStatus (subsequent). Indexed with SagaStepId for efficient history lookup. |
| 4 | StepStatusTypeId | tinyint | NO | - | VERIFIED | The status that was assigned during this transition. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). Implicit FK to Saga.StepStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaStepId | Saga.SagaSteps | Implicit FK | Links each status entry to its parent step via SagaSteps.Id |
| StepStatusTypeId | Saga.StepStatusTypes | Implicit FK (Lookup) | Status value assigned during this transition |

### 5.2 Referenced By (other objects point to this)

No other objects reference this table directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.InsertSagaStep | Stored Procedure | WRITER - inserts initial status row |
| Saga.InsertSagaStepStatus | Stored Procedure | WRITER - inserts transition rows via OUTPUT clause |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaStepStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_Saga_SagaStepStatuses__SagaStepId_Created | NC | SagaStepId ASC, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SagaStepStatuses | PRIMARY KEY | Identity-based PK for chronological ordering. DATA_COMPRESSION = PAGE. |

---

## 8. Sample Queries

### 8.1 Get full status history for a specific step
```sql
SELECT ss.Id, ss.SagaStepId, sst.Name AS Status, ss.Created
FROM Saga.SagaStepStatuses ss WITH (NOLOCK)
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE ss.SagaStepId = @SagaStepId
ORDER BY ss.Created ASC
```

### 8.2 Find steps with retry patterns (multiple Start entries)
```sql
SELECT SagaStepId, COUNT(*) AS TransitionCount,
       SUM(CASE WHEN StepStatusTypeId = 1 THEN 1 ELSE 0 END) AS StartCount,
       SUM(CASE WHEN StepStatusTypeId = 3 THEN 1 ELSE 0 END) AS RetryCount
FROM Saga.SagaStepStatuses WITH (NOLOCK)
WHERE Created > DATEADD(DAY, -1, GETUTCDATE())
GROUP BY SagaStepId
HAVING SUM(CASE WHEN StepStatusTypeId = 3 THEN 1 ELSE 0 END) > 0
ORDER BY RetryCount DESC
```

### 8.3 Step execution timeline for a saga run
```sql
SELECT s.StepIndex, sst.Name AS Status, ss.Created
FROM Saga.SagaStepStatuses ss WITH (NOLOCK)
INNER JOIN Saga.SagaSteps s WITH (NOLOCK) ON s.Id = ss.SagaStepId
INNER JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sst.Id = ss.StepStatusTypeId
WHERE s.SagaRunId = @SagaRunId
ORDER BY s.StepIndex, ss.Created ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaStepStatuses | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.SagaStepStatuses.sql*
