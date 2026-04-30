# Wallet.UpdateSagaLeaseTime

> Extends a saga's processing lease time for the owning instance, allowing the current owner to keep exclusive access by updating the expiration time.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE SagaLeaseTime WHERE SagaKey AND InstanceId match |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure extends a saga's processing lease. Unlike TakeSagaRun (which acquires an expired lease from any instance), this only succeeds if the caller is the current lease owner (InstanceId must match). The conversion, staking, and travel rule services call this periodically to prevent their lease from expiring during long-running saga processing. Returns LeaseStatus: 1=extended, 0=not owner (someone else took it).

---

## 2. Business Logic

### 2.1 Owner-Only Lease Extension

**What**: Only the current lease holder can extend.

**Rules**:
- UPDATE WHERE SagaKey = @SagaKey AND InstanceId = @InstanceId
- Unlike TakeSagaRun which checks LeaseTime < now, this checks InstanceId
- Returns 1 if updated (owner confirmed), 0 if not owner

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Saga instance. |
| 2 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Calling service instance (must be current owner). |
| 3 | @LeaseTime | datetime2(7) | NO | - | VERIFIED | New lease expiration time. |
| 4 | LeaseStatus (output) | bit | NO | - | CODE-BACKED | 1=extended, 0=not owner. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey + @InstanceId | Wallet.SagaLeaseTime | UPDATE | Lease extension |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser, StakingUser, TravelRuleWorkerUser | - | EXECUTE | Saga lease heartbeat |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateSagaLeaseTime (procedure)
+-- Wallet.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaLeaseTime | Table | Owner-validated UPDATE |

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

### 8.1 Extend a saga lease
```sql
EXEC Wallet.UpdateSagaLeaseTime @SagaKey='SAGA-KEY', @InstanceId='MY-INSTANCE', @LeaseTime=DATEADD(MINUTE, 5, GETUTCDATE());
```

### 8.2 Saga lease lifecycle
```sql
-- Create with lease: EXEC Wallet.InsertSagaRunWithLeaseTime ...
-- Extend lease (this SP): EXEC Wallet.UpdateSagaLeaseTime ...
-- Take expired lease: EXEC Wallet.TakeSagaRun ...
```

### 8.3 Check lease status
```sql
SELECT * FROM Wallet.SagaLeaseTime WITH (NOLOCK) WHERE SagaKey = 'SAGA-KEY';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateSagaLeaseTime | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpdateSagaLeaseTime.sql*
