# Wallet.InsertSagaStep

> Creates a new step within a saga run with idempotency protection, storing the step's request/response payloads and atomically inserting the initial step status.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into SagaSteps + SagaStepStatuses by SagaKey (transactional, idempotent) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure adds a new step to an existing saga run. Each saga consists of multiple sequential steps (e.g., validate, debit, submit, confirm). The conversion, staking, and travel rule services call this as each step begins execution. The procedure validates the saga exists (RAISERROR if not), is idempotent (duplicate StepIndex rejected), and atomically creates the step + initial status.

---

## 2. Business Logic

### 2.1 Saga Existence Validation + Idempotent Step Creation

**What**: Validates saga exists, creates step + status atomically.

**Rules**:
- Resolves SagaRunId from SagaRuns WHERE SagaKey = @SagaKey (RAISERROR if not found)
- WHERE NOT EXISTS (SagaSteps WHERE SagaRunId + StepIndex) for idempotency
- If duplicate (SCOPE_IDENTITY IS NULL), RAISERROR with step index
- Initial SagaStepStatuses record created with same StepStatusTypeId

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Parent saga instance. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | Zero-based step position within the saga. |
| 3 | @Request | varchar(max) | YES | - | CODE-BACKED | JSON request payload for this step. |
| 4 | @Response | varchar(max) | YES | - | CODE-BACKED | JSON response payload. NULL until step completes. |
| 5 | @StepStatusTypeId | tinyint | NO | - | VERIFIED | Initial status: 1=Start, 5=InProgress. FK to Dictionary.StepStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Wallet.SagaRuns | Lookup | Resolves SagaRunId |
| - | Wallet.SagaSteps | INSERT | Creates step record |
| - | Wallet.SagaStepStatuses | INSERT | Creates initial step status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | - | EXECUTE | Saga step creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertSagaStep (procedure)
+-- Wallet.SagaRuns (table)
+-- Wallet.SagaSteps (table)
+-- Wallet.SagaStepStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | SagaKey lookup |
| Wallet.SagaSteps | Table | INSERT + idempotency check |
| Wallet.SagaStepStatuses | Table | Initial status INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a saga step
```sql
EXEC Wallet.InsertSagaStep @SagaKey='SAGA-KEY', @StepIndex=0, @Request='{"walletId":"..."}', @Response=NULL, @StepStatusTypeId=1;
```

### 8.2 Check saga steps
```sql
SELECT ss.* FROM Wallet.SagaSteps ss WITH (NOLOCK) JOIN Wallet.SagaRuns sr WITH (NOLOCK) ON sr.Id = ss.SagaRunId WHERE sr.SagaKey = 'SAGA-KEY' ORDER BY ss.StepIndex;
```

### 8.3 Get step with status
```sql
EXEC Wallet.GetSagaStep @SagaKey = 'SAGA-KEY', @StepIndex = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertSagaStep | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertSagaStep.sql*
