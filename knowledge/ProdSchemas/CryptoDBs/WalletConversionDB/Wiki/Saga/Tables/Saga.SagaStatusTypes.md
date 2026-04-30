# Saga.SagaStatusTypes

> Lookup table defining the possible lifecycle states for saga orchestration runs in the wallet conversion system.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

SagaStatusTypes defines the complete set of lifecycle states that a saga orchestration run can be in. The saga pattern is used in WalletConversionDB to coordinate multi-step distributed operations (such as crypto-to-fiat conversions) where each step must either all succeed or be rolled back as a unit. This table is the canonical source for what each status integer means.

Without this table, the system would have no authoritative definition of saga run states. Every procedure that filters, transitions, or reports on saga runs depends on these status values to determine which sagas are active, which need recovery, and which have completed.

Saga runs are created by `Saga.InsertSagaRunWithLeaseTime` with an initial status (typically 1=Start). Status transitions are performed by `Saga.InsertSagaRunStatus`, which updates `SagaRuns.SagaStatusTypeId` and logs the transition into `SagaRunStatuses`. Multiple query procedures filter on status to find active, abandoned, or recoverable sagas.

---

## 2. Business Logic

### 2.1 Saga Lifecycle State Machine

**What**: The five status types represent the complete state machine governing saga run progression from initiation through completion or failure.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- A saga starts in `Start` (1) and progresses forward through its steps
- If any step fails, the saga transitions to `Rollback` (2) and compensation steps execute in reverse
- If all steps (forward or rollback) complete successfully, the saga moves to `Completed` (3)
- If rollback itself fails or the saga cannot recover, it moves to `Failed` (4), requiring manual intervention
- An operator can forcibly halt a saga by setting it to `ForceStop` (5), bypassing normal flow

**Diagram**:
```
[Start (1)] --all steps succeed--> [Completed (3)]
     |
     +--step fails--> [Rollback (2)] --rollback succeeds--> [Completed (3)]
     |                      |
     |                      +--rollback fails--> [Failed (4)]
     |
     +--operator halts--> [ForceStop (5)]

Active states: Start (1), Rollback (2)
Terminal states: Completed (3), Failed (4), ForceStop (5)
```

### 2.2 Recovery and Abandonment Detection

**What**: Active saga statuses (Start, Rollback) are the basis for identifying sagas that need recovery.

**Columns/Parameters Involved**: `Id`

**Rules**:
- `GetSagaRunsForRecovery` targets sagas in status 1 (Start) or 2 (Rollback) - these are the only recoverable states
- `GetAllAbandonedSagaRuns` targets sagas in status 1 (Start) whose lease has expired (LastUpdaed > 1 hour ago in SagaLeaseTime)
- `GetSagaRunsByStatusAndName` pre-filters to status IN (1, 2) before applying name filter
- Terminal states (3, 4, 5) are never targeted by recovery procedures

---

## 3. Data Overview

| Id | Name | Meaning |
|----|------|---------|
| 1 | Start | Saga is actively executing forward steps. Recovery processes monitor these sagas and restart them if their lease expires without progress. |
| 2 | Rollback | A step failed and the saga is executing compensation steps in reverse order. Still considered active and eligible for recovery if it stalls. |
| 3 | Completed | All saga steps (forward or compensation) finished successfully. The distributed operation is fully committed or fully rolled back. Terminal state. |
| 4 | Failed | Saga could not complete forward execution AND rollback also failed or was impossible. Requires manual investigation and intervention. Terminal state. |
| 5 | ForceStop | An operator manually halted the saga, bypassing the normal lifecycle. Used for stuck sagas that cannot be automatically recovered. Terminal state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | VERIFIED | Primary key identifying the saga status type. Used as FK target by `SagaRuns.SagaStatusTypeId` and `SagaRunStatuses.SagaStatusTypeId`. Values: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type) for full business definitions. |
| 2 | Name | varchar(64) | NO | - | VERIFIED | Human-readable label for the status. Used in application code for display and logging. Maps 1:1 with Id values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.SagaRuns | SagaStatusTypeId | Implicit FK (Lookup) | Current lifecycle status of each saga run. Filtered by most query procedures. |
| Saga.SagaRunStatuses | SagaStatusTypeId | Implicit FK (Lookup) | Historical status transitions for saga runs. Each row records a point-in-time status change. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SagaStatusTypeId column references this lookup |
| Saga.SagaRunStatuses | Table | SagaStatusTypeId column references this lookup |
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | Inserts initial status into SagaRuns using @SagaStatusTypeId parameter |
| Saga.InsertSagaRunStatus | Stored Procedure | Updates SagaRuns.SagaStatusTypeId and logs transition to SagaRunStatuses |
| Saga.GetSagaRunsByStatus | Stored Procedure | Filters SagaRuns by @SagaStatusTypeId parameter |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | Filters for status = 1 (Start) to find abandoned sagas |
| Saga.GetSagaRunsForRecovery | Stored Procedure | Filters for status IN (1, 2) to find recoverable sagas |
| Saga.GetSagaRunsByStatusAndName | Stored Procedure | Pre-filters for status IN (1, 2) then applies name filter |
| Saga.GetAllSagaRunsWithLimitsByStatus | Stored Procedure | Filters SagaRuns by @SagaStatusTypeId with result limit |
| Saga.GetAllSagaRunsWithLimitsByStatusAndThreshold | Stored Procedure | Filters SagaRuns by @SagaStatusTypeId with time threshold and limit |
| Saga.GetSagaRunsByStatusAndThreshold | Stored Procedure | Filters SagaRuns by @SagaStatusTypeId, name, and time threshold |
| Saga.GetSagaRunsWithLimitsByStatus | Stored Procedure | Filters SagaRuns by @SagaStatusTypeId and name with limit |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaStatusTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SagaStatusTypes | PRIMARY KEY | Unique identity for each status type. tinyint allows max 255 types (5 currently used). |

---

## 8. Sample Queries

### 8.1 List all saga status types
```sql
SELECT Id, Name
FROM Saga.SagaStatusTypes WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Count saga runs by status with status name
```sql
SELECT st.Id, st.Name, COUNT(sr.Id) AS RunCount
FROM Saga.SagaStatusTypes st WITH (NOLOCK)
LEFT JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.SagaStatusTypeId = st.Id
GROUP BY st.Id, st.Name
ORDER BY st.Id
```

### 8.3 Find all active (non-terminal) saga runs with status label
```sql
SELECT sr.Id, sr.SagaName, sr.SagaKey, sr.Created, st.Name AS StatusName
FROM Saga.SagaRuns sr WITH (NOLOCK)
INNER JOIN Saga.SagaStatusTypes st WITH (NOLOCK) ON sr.SagaStatusTypeId = st.Id
WHERE sr.SagaStatusTypeId IN (1, 2) -- Start, Rollback (active states)
ORDER BY sr.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaStatusTypes | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.SagaStatusTypes.sql*
