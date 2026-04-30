# Saga.InsertSagaRunStatus

> Transitions a saga's status by atomically updating SagaRuns and inserting a history record into SagaRunStatuses using the OUTPUT clause.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: BIT UpdateStatus (1=success, 0=not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the core status transition mechanism for saga runs. It atomically performs two operations in a single statement: (1) updates the denormalized `SagaStatusTypeId` and `LastUpdated` on `Saga.SagaRuns`, and (2) inserts a history record into `Saga.SagaRunStatuses` via the OUTPUT clause. This atomic pattern ensures the current status and history are always consistent.

Called by the saga coordinator whenever a saga transitions state (Start -> Completed, Start -> Rollback, Rollback -> Failed, etc.). The OUTPUT INTO pattern means there is no window where the status and history can be out of sync.

---

## 2. Business Logic

### 2.1 Atomic Status Transition via OUTPUT

**What**: Updates current status and writes history in a single atomic statement.

**Columns/Parameters Involved**: `@SagaKey`, `@SagaStatusTypeId`

**Rules**:
- UPDATE SagaRuns SET SagaStatusTypeId = @SagaStatusTypeId, LastUpdated = GETUTCDATE()
- OUTPUT INSERTED.Id, GETUTCDATE(), @SagaStatusTypeId INTO Saga.SagaRunStatuses
- WHERE SagaKey = @SagaKey
- Returns BIT: 1 if the saga was found and updated, 0 if @SagaKey doesn't match any row
- No transaction wrapping needed - the OUTPUT clause makes it atomic

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Technical saga instance GUID. Matches `Saga.SagaRuns.SagaKey`. |
| 2 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | New status to transition to: 1=Start, 2=Rollback, 3=Completed, 4=Failed, 5=ForceStop. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 3 | UpdateStatus (output) | bit | - | - | CODE-BACKED | 1 if the saga was found and updated, 0 if the SagaKey was not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | UPDATE | Updates SagaStatusTypeId and LastUpdated |
| OUTPUT | Saga.SagaRunStatuses | INSERT (via OUTPUT INTO) | Inserts status history record atomically |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.InsertSagaRunStatus (procedure)
├── Saga.SagaRuns (table) [UPDATE]
└── Saga.SagaRunStatuses (table) [OUTPUT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | UPDATE - changes current status |
| Saga.SagaRunStatuses | Table | OUTPUT INTO - writes history record |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON. No explicit transaction (OUTPUT INTO provides atomicity).

---

## 8. Sample Queries

### 8.1 Transition a saga to Completed
```sql
EXEC Saga.InsertSagaRunStatus
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @SagaStatusTypeId = 3
```

### 8.2 Transition a saga to Rollback
```sql
EXEC Saga.InsertSagaRunStatus
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @SagaStatusTypeId = 2
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.InsertSagaRunStatus | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.InsertSagaRunStatus.sql*
