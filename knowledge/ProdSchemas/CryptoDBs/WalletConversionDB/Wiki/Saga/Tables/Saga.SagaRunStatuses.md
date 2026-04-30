# Saga.SagaRunStatuses

> Append-only audit trail recording every status transition for saga runs, providing a complete chronological history of each saga's lifecycle progression.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (PK + 2 NC) |

---

## 1. Business Meaning

SagaRunStatuses is an append-only history table that records every status transition for saga runs. While `Saga.SagaRuns.SagaStatusTypeId` stores only the current status, this table preserves the complete timeline - when each transition occurred and what status was assigned. This enables audit trails, debugging timeline reconstruction, and analysis of saga behavior patterns.

Without this table, the system would only know a saga's current state, not how it got there. When investigating failures or performance issues, the status history reveals whether a saga went directly to Failed, or first to Rollback then Failed, and how long each transition took.

Rows are created by two procedures: `Saga.InsertSagaRunWithLeaseTime` inserts the initial Start (1) status when the saga is created, and `Saga.InsertSagaRunStatus` uses OUTPUT clause to atomically capture each subsequent status change from SagaRuns into this table. The table averages ~2.1 rows per saga run (Start + terminal state, with some having intermediate Rollback entries).

---

## 2. Business Logic

### 2.1 Status Transition Timeline

**What**: Each saga run produces a sequence of status history rows that reconstruct its lifecycle timeline.

**Columns/Parameters Involved**: `SagaRunId`, `SagaStatusTypeId`, `Created`

**Rules**:
- Every saga has at least one row (Start, created atomically with the SagaRuns row)
- Successful sagas have exactly 2 rows: Start -> Completed
- Failed sagas may have 2-4 rows: Start -> Rollback -> Completed (or Failed)
- Created timestamps enable duration calculation between transitions
- Live data: saga 17042 went Start (07:56) -> Completed (08:00), taking ~4 minutes
- Distribution: 17,042 Start entries (one per saga), 16,534 Completed, 1,948 Rollback, 11 Failed

### 2.2 Atomic Status Logging via OUTPUT Clause

**What**: InsertSagaRunStatus uses SQL OUTPUT clause to atomically capture status changes, ensuring the history is never out of sync with the current status.

**Columns/Parameters Involved**: `SagaRunId`, `Created`, `SagaStatusTypeId`

**Rules**:
- InsertSagaRunStatus UPDATEs SagaRuns.SagaStatusTypeId and uses `OUTPUT INSERTED.Id, GETUTCDATE(), @SagaStatusTypeId INTO Saga.SagaRunStatuses` to atomically log the transition
- This eliminates race conditions where the current status could be updated but the history insert fails
- The Created timestamp is set to GETUTCDATE() in the OUTPUT clause, not passed as parameter

---

## 3. Data Overview

| Id | SagaRunId | SagaStatusTypeId | Created | Meaning |
|----|-----------|------------------|---------|---------|
| 35534 | 17042 | 1 (Start) | 2026-04-15 07:56:42 | Saga 17042 initiated. First history entry, created atomically with the SagaRuns row by InsertSagaRunWithLeaseTime. |
| 35535 | 17042 | 3 (Completed) | 2026-04-15 08:00:27 | Saga 17042 completed successfully ~4 minutes after start. Terminal entry for this saga. |
| 35531 | 17040 | 2 (Rollback) | 2026-04-15 06:37:00 | Saga 17040 entered rollback - a step failed and compensation is executing. Will eventually get a Completed or Failed entry. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate primary key. Provides chronological ordering of all status transitions across all sagas. Indexed with SagaRunId for most-recent-status lookup. |
| 2 | SagaRunId | bigint | NO | - | VERIFIED | Foreign key to Saga.SagaRuns.Id identifying which saga run this status transition belongs to. Indexed for efficient history retrieval per saga. Multiple rows per SagaRunId (one per transition). |
| 3 | Created | datetime2(7) | NO | - | VERIFIED | UTC timestamp when the status transition occurred. Set to GETUTCDATE() either in InsertSagaRunWithLeaseTime (initial) or via OUTPUT clause in InsertSagaRunStatus (subsequent). Indexed with SagaRunId (DESC) for most-recent-first retrieval. |
| 4 | SagaStatusTypeId | tinyint | NO | - | VERIFIED | The status that was assigned during this transition. Values: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). Implicit FK to Saga.SagaStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaRunId | Saga.SagaRuns | Implicit FK | Links each status entry to its parent saga run via SagaRuns.Id |
| SagaStatusTypeId | Saga.SagaStatusTypes | Implicit FK (Lookup) | Status value assigned during this transition |

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
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | WRITER - inserts initial Start status row |
| Saga.InsertSagaRunStatus | Stored Procedure | WRITER - inserts transition rows via OUTPUT clause |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaRunStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_Saga_SagaRunStatuses__SagaRunId_Created | NC | SagaRunId ASC, Created DESC | - | - | Active |
| IX_Saga_SagaRunStatuses__SagaRunId_Id | NC | SagaRunId ASC, Id DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SagaRunStatuses | PRIMARY KEY | Identity-based PK for chronological ordering. DATA_COMPRESSION = PAGE. |

---

## 8. Sample Queries

### 8.1 Get full status history for a saga run
```sql
SELECT rs.Id, rs.SagaRunId, st.Name AS Status, rs.Created
FROM Saga.SagaRunStatuses rs WITH (NOLOCK)
INNER JOIN Saga.SagaStatusTypes st WITH (NOLOCK) ON st.Id = rs.SagaStatusTypeId
WHERE rs.SagaRunId = @SagaRunId
ORDER BY rs.Created ASC
```

### 8.2 Calculate duration between saga start and completion
```sql
SELECT s.SagaRunId, s.Created AS StartTime, c.Created AS CompletedTime,
       DATEDIFF(SECOND, s.Created, c.Created) AS DurationSeconds
FROM Saga.SagaRunStatuses s WITH (NOLOCK)
INNER JOIN Saga.SagaRunStatuses c WITH (NOLOCK)
    ON c.SagaRunId = s.SagaRunId AND c.SagaStatusTypeId = 3
WHERE s.SagaStatusTypeId = 1
ORDER BY s.SagaRunId DESC
```

### 8.3 Find sagas that went through rollback
```sql
SELECT DISTINCT rs.SagaRunId, sr.SagaName, sr.SagaKey
FROM Saga.SagaRunStatuses rs WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = rs.SagaRunId
WHERE rs.SagaStatusTypeId = 2
ORDER BY rs.SagaRunId DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaRunStatuses | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.SagaRunStatuses.sql*
