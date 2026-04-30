# Wallet.InsertSagaRunStatus

> Updates a saga run's lifecycle status (Start -> Completed/Rollback/Failed) by SagaKey, both updating the current status on the SagaRuns record and appending a status history event to SagaRunStatuses.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE SagaRuns + INSERT SagaRunStatuses by SagaKey (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure transitions a saga to a new lifecycle state. Unlike InsertSagaRun (which creates), this updates an existing saga's status. The conversion, staking, and travel rule services call this as sagas progress: Start(1) -> Completed(3) on success, or Start(1) -> Rollback(2) -> Failed(4) on failure. The procedure both UPDATEs the current status on SagaRuns and INSERTs a history record in SagaRunStatuses, within a transaction.

---

## 2. Business Logic

### 2.1 Dual-Write Status Update

**What**: Updates current status AND appends history event atomically.

**Rules**:
- UPDATE SagaRuns SET SagaStatusTypeId = @SagaStatusTypeId WHERE SagaKey = @SagaKey
- INSERT SagaRunStatuses(SagaRunId, SagaStatusTypeId) for the same run
- Transaction ensures both writes succeed or both roll back

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Saga instance to update. Matched against SagaRuns.SagaKey. |
| 2 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | New status: 1=Start, 2=Rollback, 3=Completed, 4=Failed. FK to Dict.SagaStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Wallet.SagaRuns | UPDATE | Updates current status |
| - | Wallet.SagaRunStatuses | INSERT | Appends status history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | - | EXECUTE | Saga lifecycle management |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertSagaRunStatus (procedure)
+-- Wallet.SagaRuns (table)
+-- Wallet.SagaRunStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | UPDATE target |
| Wallet.SagaRunStatuses | Table | INSERT target |

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

### 8.1 Mark saga as completed
```sql
EXEC Wallet.InsertSagaRunStatus @SagaKey = 'SAGA-KEY-GUID', @SagaStatusTypeId = 3;
```

### 8.2 Mark saga as failed
```sql
EXEC Wallet.InsertSagaRunStatus @SagaKey = 'SAGA-KEY-GUID', @SagaStatusTypeId = 4;
```

### 8.3 Check saga status history
```sql
SELECT srs.* FROM Wallet.SagaRunStatuses srs WITH (NOLOCK) JOIN Wallet.SagaRuns sr WITH (NOLOCK) ON sr.Id = srs.SagaRunId WHERE sr.SagaKey = 'SAGA-KEY-GUID' ORDER BY srs.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertSagaRunStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertSagaRunStatus.sql*
