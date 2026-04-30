# Saga.SagaStepStatuses

> Immutable history log of every status transition for each saga step, providing a complete audit trail of individual step execution including scheduling, retries, and completion.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 NC (SagaStepId+Created DESC) |

---

## 1. Business Meaning

This table records every status transition that an individual saga step undergoes during execution, providing the most granular audit trail in the saga framework. While `Saga.SagaSteps.StepStatusTypeId` holds only the current (denormalized) status, this table preserves the complete history of each step's state changes with timestamps - enabling detailed analysis of retry patterns, scheduling behavior, and execution timing.

With approximately 2.86M rows across 935K steps, steps average about 3 status entries each. This reflects the typical pattern where many steps pass through a Schedule phase before execution (Schedule -> Start -> Done), while immediate steps only produce 2 entries (Start -> Done). Steps that encounter transient failures produce additional Retry entries.

Status records are created by two procedures: `Saga.InsertSagaStep` creates the initial status entry atomically with the step record, and `Saga.InsertSagaStepStatus` creates subsequent transition entries while simultaneously updating the denormalized status on `Saga.SagaSteps`.

---

## 2. Business Logic

### 2.1 Step Status Transition Patterns

**What**: Each step status entry records one state transition event, forming a chronological log of the step's execution lifecycle.

**Columns/Parameters Involved**: `SagaStepId`, `StepStatusTypeId`, `Created`

**Rules**:
- Every step has at least one entry (the initial status at creation time)
- Immediate steps: Start -> Done (2 entries)
- Polling/scheduled steps: Schedule -> Start -> Done (3 entries) - used for steps that wait for external service results at timed intervals
- Retry steps: Start -> Retry -> Start -> Done (4+ entries, with potential multiple retry cycles)
- Failed steps: Start -> Failed (2 entries) - permanent step failure triggers saga-level rollback
- Schedule entries (990K) indicate most steps go through a scheduling phase before execution, consistent with the saga's event-driven polling architecture

**Diagram**:
```
Immediate step:   [1: Start] --> [4: Done]                    (2 entries)
Polling step:     [5: Schedule] --> [1: Start] --> [4: Done]   (3 entries)
Retry step:       [1: Start] --> [3: Retry] --> [1: Start] --> [4: Done]  (4+ entries)
Failed step:      [1: Start] --> [2: Failed]                   (2 entries, triggers saga rollback)
```

---

## 3. Data Overview

| Id | SagaStepId | Created | StepStatusTypeId | Meaning |
|----|-----------|---------|------------------|---------|
| 2882450 | 935405 | 2026-04-15 10:20:05.630 | 1 (Start) | Step 935405 began execution. This is the entry point for a step's active processing phase. |
| 2882451 | 935405 | 2026-04-15 10:20:06.400 | 4 (Done) | Same step completed 770ms later. The sub-second duration indicates a fast, synchronous step (likely a no-op or local check). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key. Provides global chronological ordering of all step status transitions across all saga steps. |
| 2 | SagaStepId | bigint | NO | - | VERIFIED | References `Saga.SagaSteps.Id`. Groups all status entries belonging to the same saga step. Indexed with Created (DESC) for efficient "latest status" lookups. |
| 3 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this status transition occurred. Set to GETUTCDATE() by `InsertSagaStepStatus` or the creation time from `InsertSagaStep` for the initial entry. Used for calculating step execution duration and identifying timing bottlenecks. |
| 4 | StepStatusTypeId | tinyint | NO | - | VERIFIED | The step status that was entered at this transition point. Values: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule. See [Step Status Type](../../_glossary.md#step-status-type). (Saga.StepStatusTypes) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaStepId | Saga.SagaSteps | Implicit FK | Links this status entry to the parent saga step |
| StepStatusTypeId | Saga.StepStatusTypes | Implicit FK (Lookup) | The step lifecycle state entered at this transition: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=Schedule |

### 5.2 Referenced By (other objects point to this)

No inbound references from other tables.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.SagaStepStatuses (table)
├── Saga.SagaSteps (table) [implicit FK - SagaStepId]
│   ├── Saga.SagaRuns (table) [implicit FK - SagaRunId]
│   │   └── Saga.SagaStatusTypes (table) [implicit FK - SagaStatusTypeId]
│   └── Saga.StepStatusTypes (table) [implicit FK - StepStatusTypeId]
└── Saga.StepStatusTypes (table) [implicit FK - StepStatusTypeId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaSteps | Table | Implicit FK - SagaStepId references the parent saga step |
| Saga.StepStatusTypes | Table | Implicit FK - StepStatusTypeId references the step status lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.InsertSagaStep | Stored Procedure | WRITER - inserts initial status entry during step creation |
| Saga.InsertSagaStepStatus | Stored Procedure | WRITER - inserts subsequent status transition entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaStepStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Saga_SagaStepStatuses__SagaStepId_Created | NC | SagaStepId ASC, Created DESC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Full status history for a specific step
```sql
SELECT sss.Id, sss.Created, sst.Name AS StepStatus
FROM Saga.SagaStepStatuses sss WITH (NOLOCK)
JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sss.StepStatusTypeId = sst.Id
WHERE sss.SagaStepId = @SagaStepId
ORDER BY sss.Created ASC
```

### 8.2 Steps with retries (potential transient failure patterns)
```sql
SELECT ss.SagaRunId, ss.StepIndex, COUNT(*) AS TransitionCount,
       SUM(CASE WHEN sss.StepStatusTypeId = 3 THEN 1 ELSE 0 END) AS RetryCount
FROM Saga.SagaStepStatuses sss WITH (NOLOCK)
JOIN Saga.SagaSteps ss WITH (NOLOCK) ON sss.SagaStepId = ss.Id
GROUP BY ss.SagaRunId, ss.StepIndex
HAVING SUM(CASE WHEN sss.StepStatusTypeId = 3 THEN 1 ELSE 0 END) > 0
ORDER BY RetryCount DESC
```

### 8.3 Complete step timeline for a saga run
```sql
SELECT ss.StepIndex, sss.Created, sst.Name AS StepStatus,
       DATEDIFF(MILLISECOND, LAG(sss.Created) OVER (PARTITION BY ss.SagaRunId ORDER BY sss.Id), sss.Created) AS DurationMs
FROM Saga.SagaStepStatuses sss WITH (NOLOCK)
JOIN Saga.SagaSteps ss WITH (NOLOCK) ON sss.SagaStepId = ss.Id
JOIN Saga.StepStatusTypes sst WITH (NOLOCK) ON sss.StepStatusTypeId = sst.Id
WHERE ss.SagaRunId = @SagaRunId
ORDER BY sss.Id ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | Polling step intervals: TR approval waits at 60s intervals, C2P completion at 30s intervals - explaining the high Schedule entry count in step status history |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaStepStatuses | Type: Table | Source: WalletDB/Saga/Tables/Saga.SagaStepStatuses.sql*
