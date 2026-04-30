# Saga.TryTakeSubscription

> Atomically claims an expired subscription by topic and routing, extending its lease and returning the claimed subscription details within a transaction.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set (claimed subscription or empty) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements optimistic concurrency for subscription reclamation. When a service instance needs to handle messages for a specific topic+routing, it calls this procedure to attempt to claim an expired subscription. The UPDATE TOP(1) with CROSS APPLY ensures atomic claim of exactly one expired subscription matching the criteria.

The transaction wrapping ensures that the claim is all-or-nothing. If the transaction fails (e.g., deadlock), the CATCH block rolls back cleanly. The procedure returns the full subscription details if a claim was made, or an empty result set if no eligible subscription was found.

---

## 2. Business Logic

### 2.1 Atomic Subscription Claim

**What**: Claims one expired subscription matching topic+routing.

**Columns/Parameters Involved**: `@Topic`, `@Routing`, `@LastUpdated`, `@Expired`

**Rules**:
- UPDATE TOP(1) with CROSS APPLY finds an expired, non-deleted subscription matching Topic+Routing
- Sets new LastUpdated and Expired timestamps (renewing the lease)
- Uses OUTPUT INTO @Result to capture the claimed subscription
- Returns the claimed subscription or empty result set
- Within explicit transaction with TRY/CATCH rollback

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Topic | nvarchar(256) | NO | - | CODE-BACKED | Topic to match for subscription claim. |
| 2 | @Routing | nvarchar(256) | NO | - | CODE-BACKED | Routing key to match. |
| 3 | @LastUpdated | datetime2(7) | NO | - | CODE-BACKED | New LastUpdated timestamp for the claimed subscription. |
| 4 | @Expired | datetime2(7) | NO | - | CODE-BACKED | New lease expiry for the claimed subscription. |
| 5-11 | (output columns) | - | - | - | CODE-BACKED | Id, Topic, Routing, SubscriptionName, Created, LastUpdated, Expired of the claimed subscription. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.Subscriptions | UPDATE TOP(1) + CROSS APPLY | Atomically claims an expired subscription |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.TryTakeSubscription (procedure)
└── Saga.Subscriptions (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.Subscriptions | Table | UPDATE (atomic claim) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Explicit transaction with TRY/CATCH. Uses UPDATE TOP(1) + CROSS APPLY for atomic single-row claim.

---

## 8. Sample Queries

### 8.1 Try to claim a subscription
```sql
EXEC Saga.TryTakeSubscription
    @Topic = N'saga.receive.transaction',
    @Routing = N'ExternalReceiveTransactionSaga',
    @LastUpdated = '2026-04-15T12:00:00.000Z',
    @Expired = '2026-04-15T12:05:00.000Z'
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
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.TryTakeSubscription | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.TryTakeSubscription.sql*
