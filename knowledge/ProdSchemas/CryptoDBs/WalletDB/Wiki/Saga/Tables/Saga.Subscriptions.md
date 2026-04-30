# Saga.Subscriptions

> Registry of message subscriptions used by the saga framework to manage topic-based pub/sub routing with lease expiration and soft delete.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 3 NC (Expired, IsDeleted, UNIQUE SubscriptionName) |

---

## 1. Business Meaning

This table manages message subscriptions within the saga framework's pub/sub infrastructure. Each row represents a subscription that binds a named subscriber to a specific topic and routing key combination, enabling the saga coordinator to route messages to the appropriate saga handlers. The subscription model allows saga services to dynamically register interest in specific message types at runtime.

Without this table, the saga framework would have no way to dynamically manage which services consume which message types. Static routing would require code changes and deployments for every new subscription, whereas this table enables runtime subscription management with automatic expiration to handle service restarts and failures gracefully.

Subscriptions are created by `Saga.AddSubscription` when a saga service starts and registers its message handlers. They are renewed by `Saga.UpdateSubscription` which extends the `Expired` timestamp (heartbeat pattern). Expired subscriptions can be reclaimed by `Saga.TryTakeSubscription` using an atomic UPDATE+OUTPUT pattern. Subscriptions are soft-deleted by `Saga.DeleteSubscription` (sets `IsDeleted=1`) when a service shuts down gracefully. The table is currently empty (0 rows), which may indicate this subscription mechanism is not actively used in the current deployment or was recently cleaned up.

---

## 2. Business Logic

### 2.1 Lease-Based Subscription Management

**What**: Subscriptions use a lease/heartbeat pattern where subscribers must periodically renew their subscription before the `Expired` timestamp to maintain active status.

**Columns/Parameters Involved**: `Expired`, `LastUpdated`, `IsDeleted`, `SubscriptionName`

**Rules**:
- A subscription is active when `IsDeleted = 0` AND `Expired > GETUTCDATE()`
- Subscribers renew by calling `Saga.UpdateSubscription` which extends `Expired` and updates `LastUpdated`
- If a subscriber crashes without graceful shutdown, its subscription naturally expires
- Expired subscriptions can be claimed by another instance via `Saga.TryTakeSubscription` (atomic row lock)
- Graceful shutdown calls `Saga.DeleteSubscription` to soft-delete immediately

### 2.2 Topic-Routing Message Binding

**What**: Each subscription binds a named subscriber to a specific topic + routing key combination for message delivery.

**Columns/Parameters Involved**: `Topic`, `Routing`, `SubscriptionName`

**Rules**:
- `Topic` identifies the message category (e.g., saga events, completion notifications)
- `Routing` identifies the specific routing key within the topic (e.g., a specific saga type or service instance)
- `SubscriptionName` is unique per subscriber (enforced by UNIQUE index) and identifies the consuming service instance
- `Saga.GetSubscriptionsByTopics` retrieves active subscriptions matching a given Topic + Routing pair

**Diagram**:
```
[Publisher] --Topic+Routing--> [Saga.Subscriptions] --match--> [Subscriber A (SubscriptionName)]
                                                    --match--> [Subscriber B (SubscriptionName)]

Subscription Lifecycle:
  AddSubscription --> [Active] --heartbeat--> [Active] --miss heartbeat--> [Expired]
                                   |                                           |
                                   +--graceful stop--> [IsDeleted=1]      TryTakeSubscription
                                                                          (reclaimed by new instance)
```

---

## 3. Data Overview

Table is currently empty (0 rows). No sample data available. This may indicate the subscription mechanism is not actively used in the current deployment, or subscriptions are ephemeral and cleaned up on service shutdown.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key. Used internally for row identification and the atomic TryTakeSubscription UPDATE pattern. |
| 2 | Topic | nvarchar(256) | NO | - | CODE-BACKED | Message topic category the subscription is bound to. Matched by `GetSubscriptionsByTopics` and `TryTakeSubscription` to find subscriptions for a given message type. Combined with Routing for precise message targeting. |
| 3 | Routing | nvarchar(256) | NO | - | CODE-BACKED | Routing key within the topic. Provides a second-level filter for message delivery, enabling different saga types or service instances to subscribe to the same topic but different routing keys. |
| 4 | SubscriptionName | nvarchar(256) | NO | - | CODE-BACKED | Unique name identifying the subscriber (enforced by UNIQUE index `UX_Saga_Subscriptions_SubscriptionName`). Used as the lookup key for `UpdateSubscription` and `DeleteSubscription`. Typically the service instance name or saga handler identifier. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the subscription was first registered via `Saga.AddSubscription`. |
| 6 | LastUpdated | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of the most recent heartbeat renewal via `Saga.UpdateSubscription`. NULL if never renewed after creation. Used by `GetSubscriptionsByTopics` for ordering (oldest-first) and by `TryTakeSubscription` to claim the most recently active expired subscription. |
| 7 | Expired | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp when this subscription lease expires. The subscription is considered active only when `Expired > GETUTCDATE()`. Updated by `UpdateSubscription` (heartbeat renewal) and `TryTakeSubscription` (lease reclaim). Indexed for efficient expiration checks. |
| 8 | IsDeleted | bit | NO | 0 | CODE-BACKED | Soft delete flag. 0 = active subscription, 1 = subscription has been gracefully removed by `Saga.DeleteSubscription`. All query procedures filter on `IsDeleted = 0`. Indexed for efficient filtering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

This is a standalone table with no inbound FK references from other tables.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.AddSubscription | Stored Procedure | WRITER - inserts new subscription rows |
| Saga.UpdateSubscription | Stored Procedure | MODIFIER - extends lease by updating LastUpdated and Expired |
| Saga.DeleteSubscription | Stored Procedure | MODIFIER - soft deletes by setting IsDeleted=1 |
| Saga.TryTakeSubscription | Stored Procedure | MODIFIER - atomically claims expired subscriptions |
| Saga.GetAllSubscriptions | Stored Procedure | READER - retrieves all subscriptions |
| Saga.GetSubscriptionsByTopics | Stored Procedure | READER - retrieves active subscriptions by Topic+Routing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Saga_Subscriptions | CLUSTERED PK | Id ASC | - | - | Active |
| UX_Saga_Subscriptions_Expired | NC | Expired ASC | - | - | Active |
| UX_Saga_Subscriptions_IsDeleted | NC | IsDeleted ASC | - | - | Active |
| UX_Saga_Subscriptions_SubscriptionName | NC UNIQUE | SubscriptionName ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_IsDeleted | DEFAULT | `((0))` for IsDeleted - new subscriptions are active by default |

---

## 8. Sample Queries

### 8.1 Find all active (non-expired, non-deleted) subscriptions
```sql
SELECT Id, Topic, Routing, SubscriptionName, Created, LastUpdated, Expired
FROM Saga.Subscriptions WITH (NOLOCK)
WHERE IsDeleted = 0 AND Expired > GETUTCDATE()
ORDER BY Topic, Routing
```

### 8.2 Find expired but not deleted subscriptions (eligible for reclaim)
```sql
SELECT Id, Topic, Routing, SubscriptionName, Expired,
       DATEDIFF(MINUTE, Expired, GETUTCDATE()) AS MinutesSinceExpiry
FROM Saga.Subscriptions WITH (NOLOCK)
WHERE IsDeleted = 0 AND Expired < GETUTCDATE()
ORDER BY Expired ASC
```

### 8.3 Subscription activity summary by topic
```sql
SELECT Topic, Routing,
       COUNT(*) AS TotalSubscriptions,
       SUM(CASE WHEN IsDeleted = 0 AND Expired > GETUTCDATE() THEN 1 ELSE 0 END) AS Active,
       SUM(CASE WHEN IsDeleted = 1 THEN 1 ELSE 0 END) AS Deleted,
       SUM(CASE WHEN IsDeleted = 0 AND Expired < GETUTCDATE() THEN 1 ELSE 0 END) AS Expired
FROM Saga.Subscriptions WITH (NOLOCK)
GROUP BY Topic, Routing
ORDER BY Topic, Routing
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.Subscriptions | Type: Table | Source: WalletDB/Saga/Tables/Saga.Subscriptions.sql*
