# Saga.GetSubscriptionsByTopics

> Retrieves active, expired subscriptions matching a specific topic and routing key, for the subscription reclamation and message delivery system.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of matching subscriptions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds subscriptions that match a given topic and routing key combination, are not soft-deleted, and have expired before a given timestamp. It is used by the message delivery system to find which subscribers should receive messages for a specific topic+routing pair, and by the subscription reclamation system to find expired subscriptions eligible for renewal.

Results are ordered by `LastUpdated ASC` (oldest activity first), enabling fair distribution when multiple expired subscriptions compete for reclamation.

---

## 2. Business Logic

### 2.1 Topic-Routing Subscription Lookup

**What**: Finds active expired subscriptions for a specific message type.

**Columns/Parameters Involved**: `@Topic`, `@Routing`, `@Expired`

**Rules**:
- WHERE Topic = @Topic AND Routing = @Routing AND Expired < @Expired AND IsDeleted = 0
- Ordered by LastUpdated ASC (oldest first for fair reclamation)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Topic | nvarchar(256) | NO | - | CODE-BACKED | Message topic to match. |
| 2 | @Routing | nvarchar(256) | NO | - | CODE-BACKED | Routing key within the topic. |
| 3 | @Expired | datetime2(7) | NO | - | CODE-BACKED | Cutoff: returns subscriptions expired before this time. |
| 4-10 | (output columns) | - | - | - | CODE-BACKED | Id, Topic, Routing, SubscriptionName, Created, LastUpdated, Expired. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.Subscriptions | SELECT FROM | Reads matching subscriptions |

### 5.2 Referenced By (other objects point to this)

No callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSubscriptionsByTopics (procedure)
└── Saga.Subscriptions (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.Subscriptions | Table | SELECT FROM |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find expired subscriptions for a topic
```sql
EXEC Saga.GetSubscriptionsByTopics
    @Topic = N'saga.receive.transaction',
    @Routing = N'ExternalReceiveTransactionSaga',
    @Expired = '2026-04-15T12:00:00.000Z'
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
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSubscriptionsByTopics | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSubscriptionsByTopics.sql*
