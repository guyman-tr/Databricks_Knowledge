# Dictionary.StepStatusTypes

> Lookup table defining the statuses for individual steps within a distributed saga transaction, tracking each step's progress independently.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the statuses for individual steps within a saga. While SagaStatusTypes tracks the overall saga lifecycle, this table tracks each atomic step independently. A saga may contain multiple steps (e.g., debit source, credit target, update balances), and each step has its own status tracking.

The table is FK-referenced by `Wallet.SagaSteps` and `Wallet.SagaStepStatuses`.

---

## 2. Business Logic

### 2.1 Step Execution States

**What**: Four-state lifecycle for individual saga steps.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Start` (1): Step execution initiated
- `Failed` (2): Step execution failed - saga may rollback this step's effects
- `Retry` (3): Step is being retried after a transient failure
- `Done` (4): Step completed successfully

**Diagram**:
```
Start (1) --success--> Done (4)
    |
    +--failure--> Failed (2)
    |               |
    |               +--retryable--> Retry (3) --> Start (1) [loop]
    |               |
    |               +--permanent--> [saga rollback triggered]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Start | Step execution has begun. The atomic operation for this step is in progress. |
| 2 | Failed | Step execution failed. The saga controller decides whether to retry this step or trigger a full saga rollback. |
| 3 | Retry | Step is being retried after a transient failure (e.g., timeout, temporary lock). The system will re-attempt the operation. |
| 4 | Done | Step completed successfully. Its effects are committed. The saga can proceed to the next step. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1=Start, 2=Failed, 3=Retry, 4=Done. FK target for Wallet.SagaSteps and Wallet.SagaStepStatuses. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Status label for saga step monitoring. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.SagaSteps | StepStatusTypeId | FK | Current status of each saga step |
| Wallet.SagaStepStatuses | StepStatusTypeId | FK | Status transition history for saga steps |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaSteps | Table | FK on StepStatusTypeId |
| Wallet.SagaStepStatuses | Table | FK on StepStatusTypeId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StepStatusTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all step statuses
```sql
SELECT Id, Name FROM Dictionary.StepStatusTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find failed saga steps
```sql
SELECT ss.SagaStepId, sst.Name AS Status, ss.Created
FROM Wallet.SagaSteps ss WITH (NOLOCK)
JOIN Dictionary.StepStatusTypes sst WITH (NOLOCK) ON ss.StepStatusTypeId = sst.Id
WHERE sst.Id = 2 ORDER BY ss.Created DESC
```

### 8.3 Step status distribution
```sql
SELECT sst.Name, COUNT(*) AS Count FROM Wallet.SagaStepStatuses ssr WITH (NOLOCK)
JOIN Dictionary.StepStatusTypes sst WITH (NOLOCK) ON ssr.StepStatusTypeId = sst.Id
GROUP BY sst.Name ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.StepStatusTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.StepStatusTypes.sql*
