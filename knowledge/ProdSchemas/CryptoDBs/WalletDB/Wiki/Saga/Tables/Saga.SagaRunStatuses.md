# Saga.SagaRunStatuses

> Immutable history log of every status transition for each saga run, providing a complete audit trail of saga lifecycle progression from initiation through terminal state.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 2 NC (SagaRunId+Created DESC, SagaRunId+Id DESC) |

---

## 1. Business Meaning

This table records every status transition that a saga run undergoes during its lifecycle, providing an immutable audit trail. While `Saga.SagaRuns.SagaStatusTypeId` holds only the current (denormalized) status, this table preserves the complete history of state changes with timestamps - enabling investigation of when each transition occurred and how long the saga spent in each state.

With approximately 208K rows, this table averages about 2 entries per saga. Successful sagas produce 2 entries (Start + Completed), while failed sagas produce 3 entries (Start + Rollback + Failed). This simple distribution pattern confirms the clean saga lifecycle state machine.

Status records are created by two procedures: `Saga.InsertSagaRunWithLeaseTime` creates the initial Start entry atomically with the saga run, and `Saga.InsertSagaRunStatus` creates subsequent transition entries while simultaneously updating the denormalized status on `Saga.SagaRuns`. The dual-index strategy (SagaRunId+Created DESC, SagaRunId+Id DESC) optimizes retrieval of the most recent status for a given saga.

---

## 2. Business Logic

### 2.1 Status Transition History Pattern

**What**: Each row records one state transition event, forming a chronological log of the saga's lifecycle.

**Columns/Parameters Involved**: `SagaRunId`, `SagaStatusTypeId`, `Created`

**Rules**:
- Every saga has at least one entry (the initial Start at creation time)
- Successful sagas: Start -> Completed (2 entries)
- Failed sagas: Start -> Rollback -> Failed (3 entries)
- The most recent entry's SagaStatusTypeId matches `Saga.SagaRuns.SagaStatusTypeId` (kept in sync by `InsertSagaRunStatus`)
- Time between entries reveals processing duration: Start-to-Completed typically ~1 minute for ExternalReceiveTransactionSaga

**Diagram**:
```
Success path (96%):     [1: Start] --------> [3: Completed]      (2 entries)
Failure path (4%):      [1: Start] -> [2: Rollback] -> [4: Failed]  (3 entries)
```

---

## 3. Data Overview

| Id | SagaRunId | Created | SagaStatusTypeId | Meaning |
|----|-----------|---------|------------------|---------|
| 208209 | 102230 | 2026-04-15 10:06:18 | 1 (Start) | Saga 102230 initiated. This is always the first entry for every saga run. |
| 208210 | 102230 | 2026-04-15 10:07:21 | 3 (Completed) | Same saga completed ~1 minute later. The 63-second gap represents total processing time across all 11+ steps. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key. Provides global chronological ordering of all status transitions across all saga runs. Used in IX_Saga_SagaRunStatuses__SagaRunId_Id for retrieving the latest status per saga. |
| 2 | SagaRunId | bigint | NO | - | VERIFIED | References `Saga.SagaRuns.Id`. Groups all status entries belonging to the same saga run. Indexed with Created (DESC) and Id (DESC) for efficient "latest status" lookups. |
| 3 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this status transition occurred. Set to GETUTCDATE() by `InsertSagaRunStatus` or the creation time from `InsertSagaRunWithLeaseTime` for the initial entry. Used for chronological ordering and calculating time spent in each state. |
| 4 | SagaStatusTypeId | tinyint | NO | - | VERIFIED | The saga status that was entered at this transition point. Values: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). (Saga.SagaStatusTypes) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaRunId | Saga.SagaRuns | Implicit FK | Links this status entry to the parent saga run |
| SagaStatusTypeId | Saga.SagaStatusTypes | Implicit FK (Lookup) | The lifecycle state entered at this transition: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop |

### 5.2 Referenced By (other objects point to this)

No inbound references from other tables.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.SagaRunStatuses (table)
├── Saga.SagaRuns (table) [implicit FK - SagaRunId]
│   └── Saga.SagaStatusTypes (table) [implicit FK - SagaStatusTypeId]
└── Saga.SagaStatusTypes (table) [implicit FK - SagaStatusTypeId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | Implicit FK - SagaRunId references the parent saga run |
| Saga.SagaStatusTypes | Table | Implicit FK - SagaStatusTypeId references the status lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | WRITER - inserts initial Start status entry during saga creation |
| Saga.InsertSagaRunStatus | Stored Procedure | WRITER - inserts subsequent status transition entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaRunStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Saga_SagaRunStatuses__SagaRunId_Created | NC | SagaRunId ASC, Created DESC | - | - | Active |
| IX_Saga_SagaRunStatuses__SagaRunId_Id | NC | SagaRunId ASC, Id DESC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Full status history for a saga run
```sql
SELECT srs.Id, srs.Created, sst.Name AS Status
FROM Saga.SagaRunStatuses srs WITH (NOLOCK)
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON srs.SagaStatusTypeId = sst.Id
WHERE srs.SagaRunId = @SagaRunId
ORDER BY srs.Created ASC
```

### 8.2 Average processing duration by saga type
```sql
SELECT sr.SagaName,
       AVG(DATEDIFF(SECOND, start_status.Created, end_status.Created)) AS AvgDurationSeconds
FROM Saga.SagaRuns sr WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 Created FROM Saga.SagaRunStatuses WITH (NOLOCK)
    WHERE SagaRunId = sr.Id AND SagaStatusTypeId = 1 ORDER BY Id ASC
) start_status
CROSS APPLY (
    SELECT TOP 1 Created FROM Saga.SagaRunStatuses WITH (NOLOCK)
    WHERE SagaRunId = sr.Id AND SagaStatusTypeId IN (3, 4) ORDER BY Id DESC
) end_status
WHERE sr.SagaStatusTypeId IN (3, 4)
GROUP BY sr.SagaName
```

### 8.3 Recently failed sagas with transition timeline
```sql
SELECT sr.Id AS SagaRunId, sr.SagaName, srs.Created, sst.Name AS Status
FROM Saga.SagaRuns sr WITH (NOLOCK)
JOIN Saga.SagaRunStatuses srs WITH (NOLOCK) ON sr.Id = srs.SagaRunId
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON srs.SagaStatusTypeId = sst.Id
WHERE sr.SagaStatusTypeId = 4
ORDER BY sr.Id DESC, srs.Created ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | Saga lifecycle transitions: forward steps execute sequentially, failure triggers compensating rollback, HA recovery uses status history to determine saga state after pod restarts |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaRunStatuses | Type: Table | Source: WalletDB/Saga/Tables/Saga.SagaRunStatuses.sql*
