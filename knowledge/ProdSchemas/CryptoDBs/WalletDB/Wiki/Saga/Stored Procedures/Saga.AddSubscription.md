# Saga.AddSubscription

> Registers a new message subscription by inserting a topic/routing binding into the subscription registry, returning the new subscription ID.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: SCOPE_IDENTITY() as Results (new subscription Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure registers a new subscription in the saga framework's pub/sub infrastructure. A subscription binds a named subscriber to a specific topic and routing key, enabling the saga coordinator to route messages to the appropriate saga handlers. The subscription includes a lease expiration timestamp that must be periodically renewed to remain active.

The procedure is called when a saga service instance starts up and registers its message handlers. Each subscription must have a unique `SubscriptionName` (enforced by a UNIQUE index on the table). The returned SCOPE_IDENTITY() value is the new subscription's Id, which the caller can use for subsequent operations.

The procedure performs a simple INSERT with no duplicate checking beyond the UNIQUE index constraint. If a subscription with the same name already exists, the INSERT will fail with a unique constraint violation.

---

## 2. Business Logic

No complex business logic. Direct INSERT with parameter-to-column mapping. The lease pattern (Created/LastUpdated/Expired) is managed by the caller - this procedure just stores the initial values.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Topic | nvarchar(256) | NO | - | CODE-BACKED | Message topic category the subscription binds to. Combined with @Routing for precise message targeting. |
| 2 | @Routing | nvarchar(256) | NO | - | CODE-BACKED | Routing key within the topic. Second-level filter for message delivery. |
| 3 | @SubscriptionName | nvarchar(256) | NO | - | CODE-BACKED | Unique name identifying the subscriber. Must be unique across all subscriptions (UNIQUE index enforced). Typically the service instance name or saga handler identifier. |
| 4 | @Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp of subscription creation. Passed by the application. |
| 5 | @LastUpdated | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp of last renewal. Set to creation time initially. |
| 6 | @Expired | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the subscription lease expires. The subscription is active only when Expired > GETUTCDATE(). |
| 7 | Results (output) | bigint | - | - | CODE-BACKED | Returns SCOPE_IDENTITY() - the auto-generated Id of the newly inserted subscription row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all params) | Saga.Subscriptions | INSERT INTO | Creates a new subscription record |

### 5.2 Referenced By (other objects point to this)

No callers found within the Saga schema stored procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.AddSubscription (procedure)
└── Saga.Subscriptions (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.Subscriptions | Table | INSERT INTO - creates new subscription records |

### 6.2 Objects That Depend On This

No dependents found within the schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No transaction wrapping, no duplicate checks (relies on UNIQUE index for constraint enforcement).

---

## 8. Sample Queries

### 8.1 Register a new subscription
```sql
EXEC Saga.AddSubscription
    @Topic = N'saga.receive.transaction',
    @Routing = N'ExternalReceiveTransactionSaga',
    @SubscriptionName = N'receive-handler-pod-1',
    @Created = '2026-04-15T10:00:00.000Z',
    @LastUpdated = '2026-04-15T10:00:00.000Z',
    @Expired = '2026-04-15T10:05:00.000Z'
```

### 8.2 Verify the subscription was created
```sql
SELECT * FROM Saga.Subscriptions WITH (NOLOCK)
WHERE SubscriptionName = N'receive-handler-pod-1'
```

### 8.3 N/A
N/A - single code path.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.AddSubscription | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.AddSubscription.sql*
