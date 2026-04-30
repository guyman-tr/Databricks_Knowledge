# Saga.UpdateSagaLeaseTime

> Renews a saga's processing lease by extending the expiry timestamp, serving as the heartbeat mechanism for distributed saga locking.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: BIT LeaseStatus (1=renewed, 0=not found/wrong instance) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the heartbeat mechanism for the saga distributed locking system. A service instance that is actively processing a saga must periodically call this procedure to extend the lease before it expires. If the instance crashes or fails to renew, the lease naturally expires and another instance can claim the saga via `Saga.TakeSagaRun`.

Unlike `TakeSagaRun` which can be called by any instance for an expired lease, this procedure validates ownership: the WHERE clause checks both SagaKey AND InstanceId, ensuring only the current lease holder can renew. This prevents a race condition where an instance that lost its lease tries to renew after another instance has already claimed it.

---

## 2. Business Logic

### 2.1 Owner-Validated Lease Renewal

**What**: Extends the lease only for the current owner.

**Columns/Parameters Involved**: `@SagaKey`, `@InstanceId`, `@LeaseTimeInMs`

**Rules**:
- UPDATE SagaLeaseTime SET LeaseTime = now + @LeaseTimeInMs, LastUpdaed = now
- WHERE SagaKey = @SagaKey AND InstanceId = @InstanceId (owner check)
- Returns 1 if renewed, 0 if SagaKey not found or InstanceId doesn't match (lease was taken by another instance)
- If returns 0, the caller knows it has lost the lease and must stop processing

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Identifies the saga whose lease to renew. |
| 2 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Must match the current lease holder. Ownership validation prevents stolen-lease renewal. |
| 3 | @LeaseTimeInMs | bigint | NO | - | VERIFIED | New lease duration in milliseconds. LeaseTime = GETUTCDATE() + this value. |
| 4 | LeaseStatus (output) | bit | - | - | CODE-BACKED | 1 = lease renewed, 0 = SagaKey not found or InstanceId mismatch (lease lost). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey, @InstanceId | Saga.SagaLeaseTime | UPDATE (owner-validated) | Extends the lease time |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.UpdateSagaLeaseTime (procedure)
└── Saga.SagaLeaseTime (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaLeaseTime | Table | UPDATE - renews lease with owner validation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON.

---

## 8. Sample Queries

### 8.1 Renew a saga lease (heartbeat)
```sql
EXEC Saga.UpdateSagaLeaseTime
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @InstanceId = 'B7847679-A8DA-41F1-B42F-ABD7A5FEB5FA',
    @LeaseTimeInMs = 300000
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.UpdateSagaLeaseTime | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.UpdateSagaLeaseTime.sql*
