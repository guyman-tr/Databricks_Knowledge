# Wallet.SagaSteps

> Records individual steps within saga runs, capturing the step index, request/response payloads, and execution status for each atomic operation in the distributed transaction workflow.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table records the individual steps within each saga run from `Wallet.SagaRuns`. Each saga consists of multiple sequential steps (e.g., AML check, blockchain submit, confirmation wait). Each row captures one step's execution: its index in the sequence, the request sent, the response received, and the step's status. FK to SagaRuns and Dictionary.StepStatusTypes.

The `Request` and `Response` columns store the full JSON payloads exchanged during each step, providing a detailed audit trail of the saga execution.

---

## 2. Business Logic

### 2.1 Sequential Step Execution

**What**: Steps execute in order within a saga, with rollback capability on failure.

**Columns/Parameters Involved**: `SagaRunId`, `StepIndex`, `StepStatusTypeId`

**Rules**:
- StepIndex defines execution order (0, 1, 2, ...)
- Unique constraint on (SagaRunId, StepIndex) ensures no duplicate steps
- StepStatusTypeId: 1=Start, 2=Failed, 3=Retry, 4=Done. See [Step Status Type](../../_glossary.md#step-status-type).
- On failure, compensating steps execute in reverse order (saga rollback pattern)

---

## 3. Data Overview

N/A for saga execution detail table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. FK target for Wallet.SagaStepStatuses. |
| 2 | SagaRunId | bigint | NO | - | VERIFIED | Parent saga run. FK to Wallet.SagaRuns.Id. |
| 3 | StepIndex | tinyint | NO | - | CODE-BACKED | Zero-based step sequence number within the saga. |
| 4 | Request | varchar(max) | YES | - | CODE-BACKED | JSON request payload sent during this step's execution. |
| 5 | Response | varchar(max) | YES | - | CODE-BACKED | JSON response payload received from this step's execution. |
| 6 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of step creation. |
| 7 | StepStatusTypeId | tinyint | NO | - | VERIFIED | Step status: 1=Start, 2=Failed, 3=Retry, 4=Done. See [Step Status Type](../../_glossary.md#step-status-type). FK to Dictionary.StepStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaRunId | Wallet.SagaRuns | FK | Parent saga run |
| StepStatusTypeId | Dictionary.StepStatusTypes | FK | Step status value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SagaStepStatuses | SagaStepId | Implicit | Status history for this step |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SagaSteps (table)
├── Wallet.SagaRuns (table)
└── Dictionary.StepStatusTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | FK target for SagaRunId |
| Dictionary.StepStatusTypes | Table | FK target for StepStatusTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaStepStatuses | Table | Implicit on SagaStepId |
| Wallet.InsertSagaStep | Stored Procedure | Creates step records |
| Wallet.GetSagaStep | Stored Procedure | Reads step details |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaSteps | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...SagaRunId_StepIndex | NC UNIQUE | SagaRunId, StepIndex | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Created | DEFAULT | getutcdate() |
| FK_...SagaRunId | FK | -> Wallet.SagaRuns.Id |
| FK_...StepStatusTypeId | FK | -> Dictionary.StepStatusTypes.Id |

---

## 8. Sample Queries

### 8.1 Get all steps for a saga run
```sql
SELECT ss.StepIndex, sst.Name AS Status, ss.Created
FROM Wallet.SagaSteps ss WITH (NOLOCK)
JOIN Dictionary.StepStatusTypes sst WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
WHERE ss.SagaRunId = 163847 ORDER BY ss.StepIndex
```

### 8.2 Failed steps
```sql
SELECT TOP 20 ss.SagaRunId, ss.StepIndex, ss.Response, ss.Created
FROM Wallet.SagaSteps ss WITH (NOLOCK)
WHERE ss.StepStatusTypeId = 2 ORDER BY ss.Created DESC
```

### 8.3 Steps per saga
```sql
SELECT SagaRunId, COUNT(*) AS StepCount, MAX(StepIndex) AS MaxStep
FROM Wallet.SagaSteps WITH (NOLOCK) GROUP BY SagaRunId ORDER BY StepCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SagaSteps | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SagaSteps.sql*
