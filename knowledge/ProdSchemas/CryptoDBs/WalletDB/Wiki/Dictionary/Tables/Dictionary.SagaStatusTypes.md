# Dictionary.SagaStatusTypes

> Lookup table defining the lifecycle statuses for distributed saga transactions that coordinate multi-step wallet operations.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the statuses for saga-pattern distributed transactions in the wallet system. Sagas coordinate multi-step operations (e.g., a conversion that involves debiting one crypto and crediting another) where each step must either all succeed or all be rolled back.

The saga pattern ensures data consistency across multiple operations without requiring distributed locks. Each saga run progresses through Start, may Rollback on failure, reaches Completed on success, or ends in Failed if unrecoverable.

The table is FK-referenced by `Wallet.SagaRuns` and `Wallet.SagaRunStatuses`.

---

## 2. Business Logic

### 2.1 Saga Lifecycle

**What**: Four-state lifecycle for distributed saga transactions.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Start` (1): Saga initiated - first step is being executed
- `Rollback` (2): A step failed and compensating transactions are being executed to undo completed steps
- `Completed` (3): All saga steps completed successfully - the multi-step operation is fully settled
- `Failed` (4): Saga could not be completed or rolled back - requires manual intervention

**Diagram**:
```
Start (1) --all steps pass--> Completed (3)
    |
    +--step fails--> Rollback (2) --compensated--> Failed (4)
                         |
                         +--compensation fails--> Failed (4) [manual fix needed]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Start | Saga execution has begun. Steps are being processed in order. If any step fails, the saga transitions to Rollback. |
| 2 | Rollback | A step failed and the system is executing compensating transactions to undo all previously completed steps. Ensures consistency. |
| 3 | Completed | All steps in the saga completed successfully. The multi-step operation is fully settled and consistent. Terminal success state. |
| 4 | Failed | Saga could not complete or rollback cleanly. Requires manual investigation and resolution by the operations team. Terminal failure state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1=Start, 2=Rollback, 3=Completed, 4=Failed. FK target for Wallet.SagaRuns and Wallet.SagaRunStatuses. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Status label for saga monitoring dashboards and operational alerts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SagaRuns | SagaStatusTypeId | FK | Current status of each saga run |
| Wallet.SagaRunStatuses | SagaStatusTypeId | FK | Status transition history for saga runs |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | FK on SagaStatusTypeId |
| Wallet.SagaRunStatuses | Table | FK on SagaStatusTypeId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaStatusTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all saga statuses
```sql
SELECT Id, Name FROM Dictionary.SagaStatusTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find stuck sagas
```sql
SELECT sr.SagaRunId, sst.Name AS Status, sr.Created
FROM Wallet.SagaRuns sr WITH (NOLOCK)
JOIN Dictionary.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
WHERE sst.Id = 1 AND sr.Created < DATEADD(HOUR, -1, GETUTCDATE())
```

### 8.3 Saga completion rate
```sql
SELECT sst.Name, COUNT(*) AS Count FROM Wallet.SagaRuns sr WITH (NOLOCK)
JOIN Dictionary.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
GROUP BY sst.Name ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.SagaStatusTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.SagaStatusTypes.sql*
