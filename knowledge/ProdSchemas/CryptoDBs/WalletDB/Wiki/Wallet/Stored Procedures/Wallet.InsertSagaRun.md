# Wallet.InsertSagaRun

> Creates a new saga (distributed transaction) run with idempotency protection via SagaKey, atomically inserting the saga record and its initial status within a transaction.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into SagaRuns + SagaRunStatuses (transactional, idempotent) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure initiates a new saga (distributed transaction) for multi-step wallet operations. The conversion, staking, and travel rule worker services call this when starting operations that require saga-based coordination. It's idempotent: duplicate SagaKeys are rejected with RAISERROR. The procedure atomically creates the saga run and its initial status (typically SagaStatusTypeId=1, Start).

---

## 2. Business Logic

### 2.1 Idempotent Saga Creation

**What**: Creates saga + initial status atomically, rejecting duplicate SagaKeys.

**Rules**:
- WHERE NOT EXISTS (SagaRuns WHERE SagaKey = @SagaKey)
- If duplicate (SCOPE_IDENTITY IS NULL), RAISERROR with SagaKey
- Initial SagaRunStatuses record created with the same SagaStatusTypeId

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaName | varchar(255) | NO | - | VERIFIED | Saga type/class name (e.g., 'SendCryptoSaga', 'RedemptionSaga'). |
| 2 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Unique saga instance ID. Idempotency key. |
| 3 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Initial status: 1=Start. FK to Dict.SagaStatusTypes. |
| 4 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID linking to Wallet.Requests. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SagaRuns | INSERT | Creates saga run |
| - | Wallet.SagaRunStatuses | INSERT | Creates initial status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | - | EXECUTE | Saga initiation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertSagaRun (procedure)
+-- Wallet.SagaRuns (table)
+-- Wallet.SagaRunStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | INSERT target + idempotency check |
| Wallet.SagaRunStatuses | Table | Initial status INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses BEGIN/COMMIT TRANSACTION.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a new saga run
```sql
EXEC Wallet.InsertSagaRun @SagaName = 'SendCryptoSaga', @SagaKey = 'NEW-GUID', @SagaStatusTypeId = 1, @CorrelationId = 'REQUEST-GUID';
```

### 8.2 Check saga status
```sql
SELECT * FROM Wallet.SagaRuns WITH (NOLOCK) WHERE SagaKey = 'YOUR-SAGA-KEY';
```

### 8.3 Full saga lifecycle
```sql
-- 1. InsertSagaRun (this SP - creates saga)
-- 2. InsertSagaStep (adds steps)
-- 3. InsertSagaStepStatus (updates step status)
-- 4. InsertSagaRunStatus (updates run status)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertSagaRun | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertSagaRun.sql*
