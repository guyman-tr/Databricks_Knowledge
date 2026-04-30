# Saga.SagaStatusTypes

> Lookup table defining the lifecycle states of a distributed saga (multi-step transactional workflow) within the wallet platform.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

This table defines the finite set of states that a saga run can occupy during its lifecycle. A saga is a distributed transaction pattern used to coordinate multi-step wallet operations (e.g., crypto receive, auto crypto-to-position conversion) that span multiple services and require compensating rollback actions if any step fails. Each status represents a distinct phase in the saga's progression from initiation through terminal completion or failure.

Without this table, the system would have no way to classify or query sagas by their current lifecycle phase. Status-based filtering is fundamental to saga infrastructure: the recovery service uses status to find stuck or failed sagas, the monitoring layer reports on saga throughput by state, and the saga coordinator transitions runs through states as steps execute or fail.

Data flows into consumers rather than into this table - it is a static reference. The `SagaStatusTypeId` column in `Saga.SagaRuns` and `Saga.SagaRunStatuses` references these values. Procedures like `Saga.InsertSagaRunWithLeaseTime` set the initial status (1=Start), `Saga.InsertSagaRunStatus` transitions to subsequent states, and recovery procedures like `Saga.GetSagaRunsForRecovery` filter by Start and Rollback statuses to find sagas needing intervention.

---

## 2. Business Logic

### 2.1 Saga Lifecycle State Machine

**What**: Each saga progresses through defined status transitions from creation to a terminal state.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- Status 1 (Start): Saga has been initiated; forward steps are executing sequentially
- Status 2 (Rollback): A step failed; the saga coordinator is executing compensating transactions to undo completed steps in reverse order
- Status 3 (Completed): All forward steps completed successfully; the distributed transaction is fully committed
- Status 4 (Failed): Rollback completed (or rollback itself failed); the saga has reached a permanent failure state
- Status 5 (ForceStop): The saga was manually terminated by an operator or system intervention before reaching a natural terminal state
- Statuses 3, 4, and 5 are terminal - no further transitions occur
- A saga stuck in status 1 beyond a configured threshold indicates a processing problem and triggers recovery

**Diagram**:
```
[1: Start] --success--> [3: Completed]
    |
    +--step fails--> [2: Rollback] --rollback done--> [4: Failed]
    |                     |
    +--force stop--> [5: ForceStop]
    +--force stop--> [5: ForceStop]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|----|------|---------|
| 1 | Start | Saga initiated and forward steps are executing. Recovery services monitor sagas in this state for staleness - if a saga remains in Start beyond a configured threshold, it may be picked up for retry or escalation. |
| 2 | Rollback | A forward step failed and the saga coordinator is executing compensating actions in reverse order to undo completed steps. This is a transient state - the saga will transition to Failed once rollback completes. |
| 3 | Completed | All saga steps executed successfully. Terminal state indicating the distributed transaction committed fully - e.g., a crypto receive passed AML, travel rule checks, and balance was credited. |
| 4 | Failed | The saga failed and rollback has been executed (or attempted). Terminal state - operations teams investigate these for stuck funds or incomplete transactions that need manual resolution. |
| 5 | ForceStop | The saga was forcibly terminated by an operator or automated circuit breaker before reaching a natural terminal state. Used for emergency intervention when a saga is stuck or causing issues. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | VERIFIED | Primary key and status identifier. Used as the FK value in `Saga.SagaRuns.SagaStatusTypeId` and `Saga.SagaRunStatuses.SagaStatusTypeId`. Values: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | Name | varchar(64) | NO | - | VERIFIED | Human-readable label for the saga lifecycle state. Used in monitoring dashboards and operational logs to display the current phase of a saga run without requiring a JOIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Saga.SagaRuns | SagaStatusTypeId | Implicit FK (Lookup) | Current lifecycle state of the saga run - denormalized for fast status-based filtering |
| Saga.SagaRunStatuses | SagaStatusTypeId | Implicit FK (Lookup) | Historical status entry recording a specific state transition event |
| Wallet.SagaRuns | SagaStatusTypeId | Implicit FK (Lookup) | Same role as Saga.SagaRuns but in the Wallet schema's parallel saga infrastructure |
| Wallet.SagaRunStatuses | SagaStatusTypeId | Implicit FK (Lookup) | Same role as Saga.SagaRunStatuses but in the Wallet schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SagaStatusTypeId references this lookup for current saga state |
| Saga.SagaRunStatuses | Table | SagaStatusTypeId references this lookup for status history entries |
| Saga.InsertSagaRunWithLeaseTime | Stored Procedure | Sets initial SagaStatusTypeId on saga creation |
| Saga.InsertSagaRunStatus | Stored Procedure | Inserts status transition with SagaStatusTypeId and updates SagaRuns.SagaStatusTypeId |
| Saga.GetSagaRunsByStatus | Stored Procedure | Filters SagaRuns by SagaStatusTypeId |
| Saga.GetAllAbandonedSagaRuns | Stored Procedure | Filters for SagaStatusTypeId=1 (Start) to find stuck sagas |
| Saga.GetSagaRunsForRecovery | Stored Procedure | Filters for Start and Rollback statuses for recovery processing |
| Saga.GetSagaRunsByStatusAndName | Stored Procedure | Filters by SagaStatusTypeId and SagaName for targeted retrieval |
| Saga.ReinitiateSaga | Stored Procedure | Resets saga to SagaStatusTypeId=1 (Start) for retry |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaStatusTypes | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all saga status types
```sql
SELECT Id, Name
FROM Saga.SagaStatusTypes WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Count active sagas by status
```sql
SELECT sst.Id, sst.Name, COUNT(sr.Id) AS SagaCount
FROM Saga.SagaStatusTypes sst WITH (NOLOCK)
LEFT JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
GROUP BY sst.Id, sst.Name
ORDER BY sst.Id
```

### 8.3 Find sagas needing attention (Start or Rollback)
```sql
SELECT sr.Id, sr.SagaName, sr.SagaKey, sr.Created, sst.Name AS Status
FROM Saga.SagaRuns sr WITH (NOLOCK)
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
WHERE sr.SagaStatusTypeId IN (1, 2)
ORDER BY sr.Created ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Saga Split Architecture (TransactionHandler)](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14194180097) | Confluence | Saga factory pattern: multi-step distributed transactions (11-17 steps) with shared "lego block" step implementations, HA recovery by saga name, and status-based lifecycle management |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaStatusTypes | Type: Table | Source: WalletDB/Saga/Tables/Saga.SagaStatusTypes.sql*
