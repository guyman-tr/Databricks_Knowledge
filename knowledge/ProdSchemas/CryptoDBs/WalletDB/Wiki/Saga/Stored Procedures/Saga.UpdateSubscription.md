# Saga.UpdateSubscription

> Renews a subscription's lease by updating its LastUpdated and Expired timestamps, serving as the heartbeat mechanism for subscription management.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: @@ROWCOUNT as Results (rows affected) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the subscription heartbeat mechanism. A service instance that holds a subscription must periodically call this procedure to extend its lease before the Expired timestamp passes. This is the subscription equivalent of `Saga.UpdateSagaLeaseTime` for saga processing.

Unlike the saga lease update which validates InstanceId ownership, this procedure identifies the subscription solely by SubscriptionName and does not verify ownership. The explicit transaction wrapping is functionally unnecessary for a single UPDATE but exists as a safety pattern.

---

## 2. Business Logic

### 2.1 Subscription Lease Renewal

**What**: Extends subscription expiry by updating timestamps.

**Columns/Parameters Involved**: `@SubscriptionName`, `@LastUpdated`, `@Expired`

**Rules**:
- UPDATE Subscriptions SET LastUpdated = @LastUpdated, Expired = @Expired WHERE SubscriptionName = @SubscriptionName
- Returns @@ROWCOUNT: 1 if updated, 0 if name not found
- Within explicit transaction (COMMIT after UPDATE)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SubscriptionName | nvarchar(256) | NO | - | CODE-BACKED | Unique subscription name to renew. |
| 2 | @LastUpdated | datetime2(7) | NO | - | CODE-BACKED | New LastUpdated timestamp (current time). |
| 3 | @Expired | datetime2(7) | NO | - | CODE-BACKED | New expiry timestamp (current time + lease duration). |
| 4 | Results (output) | int | - | - | CODE-BACKED | @@ROWCOUNT: 1 if found and updated, 0 if not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SubscriptionName | Saga.Subscriptions | UPDATE | Renews lease timestamps |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.UpdateSubscription (procedure)
└── Saga.Subscriptions (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.Subscriptions | Table | UPDATE - renews lease |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Explicit transaction (BEGIN/COMMIT).

---

## 8. Sample Queries

### 8.1 Renew a subscription lease
```sql
EXEC Saga.UpdateSubscription
    @SubscriptionName = N'receive-handler-pod-1',
    @LastUpdated = '2026-04-15T12:05:00.000Z',
    @Expired = '2026-04-15T12:10:00.000Z'
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.UpdateSubscription | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.UpdateSubscription.sql*
