# Wallet.TakeSagaRun

> Attempts to acquire ownership of an existing saga run by updating its lease if the current lease has expired, enabling distributed saga processing with lease-based concurrency control.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE SagaLeaseTime with conditional lease acquisition |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements lease-based concurrency control for saga processing. When a service instance wants to take over processing of a saga (either initially or after the previous owner's lease expired), it calls this SP. The UPDATE only succeeds if the saga's lease has expired (LeaseTime < GETUTCDATE()). If successful, the new InstanceId and LeaseTime are set. Returns LeaseStatus: 1=acquired, 0=lease still held by another instance.

The conversion, staking, and travel rule worker services call this during saga framework startup and recovery.

---

## 2. Business Logic

### 2.1 Conditional Lease Acquisition

**What**: Acquires saga ownership only if the lease has expired.

**Columns/Parameters Involved**: `@SagaKey`, `@InstanceId`, `@LeaseTime`, `SagaLeaseTime.LeaseTime`

**Rules**:
- UPDATE SagaLeaseTime SET LeaseTime=@LeaseTime, InstanceId=@InstanceId, LastUpdaed=GETUTCDATE()
- WHERE SagaKey = @SagaKey AND LeaseTime < GETUTCDATE()
- @@ROWCOUNT = 0 means lease is still active (another instance owns it) -> LeaseStatus=0
- @@ROWCOUNT > 0 means lease acquired -> LeaseStatus=1
- This is the "take" counterpart to "InsertSagaRunWithLeaseTime" (create + lease)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Saga to take ownership of. |
| 2 | @InstanceId | uniqueidentifier | NO | - | VERIFIED | Service instance acquiring the lease. |
| 3 | @LeaseTime | datetime2(7) | NO | - | VERIFIED | New lease expiration time. |
| 4 | LeaseStatus (output) | bit | NO | - | CODE-BACKED | 1=lease acquired, 0=lease still held by another instance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Wallet.SagaLeaseTime | UPDATE | Conditional lease acquisition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Saga lease takeover |
| StakingUser | - | EXECUTE | Saga lease takeover |
| TravelRuleWorkerUser | - | EXECUTE | Saga lease takeover |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TakeSagaRun (procedure)
+-- Wallet.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SagaLeaseTime | Table | Conditional UPDATE |

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

### 8.1 Try to take a saga
```sql
EXEC Wallet.TakeSagaRun @SagaKey='SAGA-KEY', @InstanceId='MY-INSTANCE-GUID', @LeaseTime=DATEADD(MINUTE, 5, GETUTCDATE());
-- Returns LeaseStatus=1 if acquired, 0 if another instance holds the lease
```

### 8.2 Extend an existing lease
```sql
-- Use UpdateSagaLeaseTime instead for extending, or TakeSagaRun with longer LeaseTime
EXEC Wallet.TakeSagaRun @SagaKey='SAGA-KEY', @InstanceId='MY-INSTANCE-GUID', @LeaseTime=DATEADD(MINUTE, 10, GETUTCDATE());
```

### 8.3 Check current lease holder
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
*Object: Wallet.TakeSagaRun | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.TakeSagaRun.sql*
