# Saga.UpdateSagaLeaseTime

> Renews an active saga lease for the current owner instance, extending the expiry to prevent the saga from being classified as abandoned during long-running step execution.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: LeaseStatus BIT (1=renewed, 0=lost ownership) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

UpdateSagaLeaseTime is the lease renewal mechanism called periodically by the worker instance that currently owns a saga run. While processing saga steps, the worker must keep its lease alive to prevent other workers from assuming the saga has been abandoned. This procedure extends the lease expiry by the specified duration, but only if the caller is still the rightful owner (matching InstanceId).

Without this procedure, a worker processing a long-running step would see its lease expire, causing another worker to take over via TakeSagaRun. This would result in two workers processing the same saga simultaneously, leading to duplicate operations or conflicts.

The ConversionWorkerUser has explicit EXECUTE permission on this procedure, confirming it is called by the conversion worker application service.

---

## 2. Business Logic

### 2.1 Owner-Verified Lease Renewal

**What**: Extends the lease only if the caller's InstanceId matches the current lease owner, preventing stale instances from renewing lost leases.

**Columns/Parameters Involved**: `@SagaKey`, `@InstanceId`, `@LeaseTimeInMs`

**Rules**:
- UPDATE SagaLeaseTime SET LeaseTime = GETUTCDATE() + @LeaseTimeInMs, LastUpdaed = GETUTCDATE()
- WHERE SagaKey = @SagaKey AND InstanceId = @InstanceId
- Returns @@ROWCOUNT-based BIT: 1 if renewed, 0 if ownership was lost (another instance took over)
- If LeaseStatus = 0, the worker should stop processing this saga immediately
- Uses SET NOCOUNT ON to suppress row count messages

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level identifier of the saga run whose lease to renew. |
| 2 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Identifier of the worker instance requesting renewal. Must match the current InstanceId in SagaLeaseTime or the renewal is rejected. |
| 3 | @LeaseTimeInMs | bigint | NO | - | VERIFIED | New lease duration in milliseconds from now. Typically ~300,000 (5 minutes). |

**Return:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | LeaseStatus | BIT | VERIFIED | 1 = lease renewed (caller still owns the saga), 0 = ownership lost (caller should stop processing immediately) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaLeaseTime | UPDATE target | Renews lease expiry and LastUpdaed timestamp |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.UpdateSagaLeaseTime (procedure)
└── Saga.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaLeaseTime | Table | UPDATE target - renews lease for current owner |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Renew a lease for the current instance
```sql
EXEC Saga.UpdateSagaLeaseTime
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @InstanceId = 'EC3FDAF2-C03E-47A1-8025-E42050D8EA4A',
    @LeaseTimeInMs = 300000 -- 5 minutes
```

### 8.2 Check current lease state before renewal
```sql
SELECT SagaKey, InstanceId, LastUpdaed, LeaseTime,
       CASE WHEN LeaseTime > GETUTCDATE() THEN 'Active' ELSE 'Expired' END AS Status
FROM Saga.SagaLeaseTime WITH (NOLOCK)
WHERE SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
```

### 8.3 Verify renewal updated the lease
```sql
SELECT LeaseTime, LastUpdaed, InstanceId
FROM Saga.SagaLeaseTime WITH (NOLOCK)
WHERE SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.UpdateSagaLeaseTime | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.UpdateSagaLeaseTime.sql*
