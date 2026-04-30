# Wallet.InsertSagaStepStatus

> Updates a saga step's execution status by SagaKey and StepIndex, both updating the current status on the step record and appending a history event, with validation that both saga and step exist.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE SagaSteps + INSERT SagaStepStatuses by SagaKey + StepIndex |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure transitions a saga step to a new status (e.g., Start -> InProgress -> Done or Failed). The conversion, staking, and travel rule services call this as steps execute. It validates both the saga run and step exist (RAISERROR if not), then atomically UPDATEs the step's current status and INSERTs a history record.

---

## 2. Business Logic

### 2.1 Validated Dual-Write Step Status Update

**What**: Validates saga+step exist, then updates current + appends history.

**Rules**:
- Resolves SagaRunId from SagaRuns WHERE SagaKey (RAISERROR if not found)
- Resolves SagaStepId from SagaSteps WHERE SagaRunId + StepIndex (RAISERROR if not found)
- UPDATE SagaSteps SET StepStatusTypeId WHERE Id = @SagaStepId
- INSERT SagaStepStatuses(SagaStepId, StepStatusTypeId)
- Transaction ensures both succeed or both roll back

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Saga instance containing the step. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | Zero-based step position to update. |
| 3 | @StepStatusTypeId | tinyint | NO | - | VERIFIED | New status: 1=Start, 2=Failed, 3=Retry, 4=Done, 5=InProgress. FK to Dictionary.StepStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Wallet.SagaRuns | Lookup | Resolves SagaRunId |
| SagaRunId + @StepIndex | Wallet.SagaSteps | UPDATE | Updates current step status |
| - | Wallet.SagaStepStatuses | INSERT | Appends status history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | - | EXECUTE | Step lifecycle management |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertSagaStepStatus (procedure)
+-- Wallet.SagaRuns (table)
+-- Wallet.SagaSteps (table)
+-- Wallet.SagaStepStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | SagaKey lookup |
| Wallet.SagaSteps | Table | Step lookup + UPDATE |
| Wallet.SagaStepStatuses | Table | History INSERT |

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

### 8.1 Mark step as done
```sql
EXEC Wallet.InsertSagaStepStatus @SagaKey='SAGA-KEY', @StepIndex=0, @StepStatusTypeId=4;
```

### 8.2 Mark step as failed
```sql
EXEC Wallet.InsertSagaStepStatus @SagaKey='SAGA-KEY', @StepIndex=2, @StepStatusTypeId=2;
```

### 8.3 Check step status history
```sql
SELECT sss.* FROM Wallet.SagaStepStatuses sss WITH (NOLOCK) JOIN Wallet.SagaSteps ss WITH (NOLOCK) ON ss.Id = sss.SagaStepId JOIN Wallet.SagaRuns sr WITH (NOLOCK) ON sr.Id = ss.SagaRunId WHERE sr.SagaKey = 'SAGA-KEY' AND ss.StepIndex = 0 ORDER BY sss.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertSagaStepStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertSagaStepStatus.sql*
