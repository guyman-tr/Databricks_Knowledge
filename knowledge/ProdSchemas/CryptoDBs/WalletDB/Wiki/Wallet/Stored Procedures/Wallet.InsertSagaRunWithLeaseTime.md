# Wallet.InsertSagaRunWithLeaseTime

> Creates a new saga run with an associated distributed lease record for exclusive processing, combining saga creation (like InsertSagaRun) with lease management in a single atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into SagaRuns + SagaRunStatuses + SagaLeaseTime (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure extends InsertSagaRun by additionally creating a distributed processing lease in Wallet.SagaLeaseTime. The lease ensures only one service instance processes this saga at a time. The conversion, staking, and travel rule services call this when they need exclusive saga ownership. Idempotent via SagaKey uniqueness. Returns LeaseStatus (1=success, 0=failure/duplicate).

---

## 2. Business Logic

### 2.1 Atomic Saga + Lease Creation

**What**: Creates saga run, initial status, and lease record in one transaction.

**Rules**:
- Same idempotency as InsertSagaRun (WHERE NOT EXISTS on SagaKey)
- Additional INSERT into SagaLeaseTime with InstanceId (owning service instance) and LeaseTime (expiration)
- Returns CAST(1 AS BIT) LeaseStatus on success, CAST(0 AS BIT) on failure

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaName | varchar(255) | NO | - | VERIFIED | Saga type name. |
| 2 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Unique saga instance ID. |
| 3 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Service instance acquiring the lease. |
| 4 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Initial status (typically 1=Start). |
| 5 | @LeaseTime | datetime2(7) | NO | - | VERIFIED | Lease expiration time. |
| 6 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID. |
| 7 | LeaseStatus (output) | bit | NO | - | CODE-BACKED | 1=saga and lease created, 0=duplicate or error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SagaRuns | INSERT | Creates saga run |
| - | Wallet.SagaRunStatuses | INSERT | Creates initial status |
| - | Wallet.SagaLeaseTime | INSERT | Creates processing lease |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | - | EXECUTE | Saga creation with lease |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertSagaRunWithLeaseTime (procedure)
+-- Wallet.SagaRuns (table)
+-- Wallet.SagaRunStatuses (table)
+-- Wallet.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaRuns | Table | INSERT + idempotency check |
| Wallet.SagaRunStatuses | Table | Initial status INSERT |
| Wallet.SagaLeaseTime | Table | Lease record INSERT |

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

### 8.1 Create saga with lease
```sql
EXEC Wallet.InsertSagaRunWithLeaseTime @SagaName='SendCryptoSaga', @SagaKey='NEW-GUID', @InstanceId='INSTANCE-GUID', @SagaStatusTypeId=1, @LeaseTime='2026-04-15 12:00:00', @CorrelationId='REQUEST-GUID';
```

### 8.2 Check lease status
```sql
SELECT * FROM Wallet.SagaLeaseTime WITH (NOLOCK) WHERE SagaKey = 'YOUR-SAGA-KEY';
```

### 8.3 Compare with InsertSagaRun
```sql
-- Without lease: EXEC Wallet.InsertSagaRun @SagaName='...', @SagaKey='...', @SagaStatusTypeId=1, @CorrelationId='...';
-- With lease (this SP): EXEC Wallet.InsertSagaRunWithLeaseTime ... @InstanceId='...', @LeaseTime='...';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertSagaRunWithLeaseTime | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertSagaRunWithLeaseTime.sql*
