# Billing.NotificationMessages

> Transient inbox table for inbound payment provider webhook/notification messages (WorldPay, Checkout.com), storing raw payloads for asynchronous processing by the billing notification pipeline before being purged after 31 days.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | MessageID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup (TEXTIMAGE_ON PRIMARY for varchar(max)) |
| **Indexes** | 2 active (PK clustered on MessageID + NC on Created PAGE-compressed) |

---

## 1. Business Meaning

Billing.NotificationMessages is the landing table for inbound webhook notifications from payment processors (WorldPay, Checkout.com). When a payment provider sends a callback - confirming a deposit was processed, flagging a failure, or notifying of a chargeback - the billing notification gateway service writes the raw message payload here immediately, then processes it asynchronously. This decouples message ingestion from message processing: the gateway acknowledges receipt to the provider quickly, then a background worker picks up StatusID=1 records, processes them (updating deposit/withdrawal statuses), and marks them StatusID=2.

The table is a short-lived staging buffer, not a long-term audit log. DelOld_NotificationMessages purges records older than 31 days in batches of 4500 to keep the table small and IX_NotificationMessages_Created efficient. The RawMessage is stored encrypted (varchar(max)) and is not human-readable directly.

Queue names pattern ("stg-checkout-notificationgateway", "stg-worldpay-notificationgateway") indicates this environment is a staging database; production queues would follow the same pattern without the "stg-" prefix.

---

## 2. Business Logic

### 2.1 Message Lifecycle (Pending -> Processed / Error)

**What**: Each inbound notification passes through three StatusID states: received (1), processed (2), or errored (5).

**Columns/Parameters Involved**: `StatusID`, `MessageID`, `Processed`

**Rules**:
- On INSERT via UpsertNotificationMessage: StatusID is hardcoded to 1 (pending) regardless of @StatusID parameter. Created = Processed = GETUTCDATE().
- On UPDATE via UpsertNotificationMessage: StatusID, Queue, Topic, Subscription, Provider, RawMessage can be updated selectively (ISNULL preservation). Processed is always set to GETUTCDATE() to record when processing completed.
- StatusID=2 (processed): The dominant state - 744,743 of 747,187 rows. Message was consumed successfully by the billing processor.
- StatusID=5 (error): 2,420 rows - processing failed. These are candidates for retry or manual investigation.
- StatusID=1 (pending): Only 24 rows - very short-lived. Workers consume them rapidly.

### 2.2 Provider Routing

**What**: Queue column identifies which service bus queue the message arrived on, allowing routing to the appropriate payment processor handler.

**Columns/Parameters Involved**: `Provider`, `Queue`, `Topic`, `Subscription`

**Rules**:
- Provider values observed: "checkout", "worldpay", "etorotest". Determines which provider's notification format the RawMessage follows.
- Queue: Message bus queue name (e.g., "stg-checkout-notificationgateway"). Provider-specific. Topic and Subscription are NULL in all observed records - likely reserved for pub/sub patterns not currently in use.
- The billing processor likely dispatches to different parsing logic per Provider value when consuming StatusID=1 rows.

### 2.3 Retention Policy

**What**: Old notifications are periodically purged to prevent unbounded growth.

**Columns/Parameters Involved**: `Created`

**Rules**:
- DelOld_NotificationMessages @DaysToKeep=31 (default): deletes in batches of 4500 WHERE Created < DATEADD(DD, -31, GETUTCDATE()).
- Batch deletion prevents excessive log growth during cleanup.
- The NC index on Created (PAGE compressed) makes the WHERE Created < threshold scan efficient.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | ~747,187 |
| StatusID=1 (Pending) | 24 (0.003%) |
| StatusID=2 (Processed) | 744,743 (99.7%) |
| StatusID=5 (Error) | 2,420 (0.3%) |
| Providers observed | checkout, worldpay, etorotest |
| Date range | Up to 2025-10-22 (staging env - 31-day rolling window) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. NOT FOR REPLICATION - identity values are not replicated to subscribers (each replica generates its own IDs). Used as the handle passed between the ingestion service and processor worker. |
| 2 | Provider | varchar(100) | YES | - | CODE-BACKED | Payment provider that sent the notification. Observed values: "checkout" (Checkout.com), "worldpay" (WorldPay), "etorotest" (internal test harness). Determines which message schema the RawMessage follows. NULL would indicate a corrupt or unknown inbound message. |
| 3 | RawMessage | varchar(max) | YES | - | CODE-BACKED | The full encrypted raw notification payload from the payment provider. Stored as varchar(max); content is encrypted and not human-readable directly. Contains the provider's webhook body (JSON or XML depending on provider). TEXTIMAGE_ON PRIMARY means large payloads are stored in the LOB segment. |
| 4 | StatusID | tinyint | NO | - | CODE-BACKED | Processing lifecycle state. Values: 1=Pending (newly inserted, awaiting processing), 2=Processed (successfully consumed), 5=Error (processing failed). Note: UpsertNotificationMessage hardcodes StatusID=1 on INSERT regardless of the @StatusID parameter passed. |
| 5 | Queue | varchar(100) | YES | - | CODE-BACKED | Message bus queue name the notification arrived on. Pattern: "{env}-{provider}-notificationgateway" (e.g., "stg-checkout-notificationgateway"). Used to identify the delivery channel and route back responses. NULL for etorotest provider records. |
| 6 | Topic | varchar(100) | YES | - | CODE-BACKED | Message bus topic name. NULL in all observed records - field is populated when using a pub/sub topic delivery model rather than direct queue delivery. Reserved for future use or alternate provider configurations. |
| 7 | Subscription | varchar(100) | YES | - | CODE-BACKED | Message bus subscription name for topic-based delivery. NULL in all observed records alongside Topic. Populated when a topic/subscription model is used instead of direct queuing. |
| 8 | Created | smalldatetime | NO | - | CODE-BACKED | UTC timestamp when the notification was received and inserted. Set to GETUTCDATE() on INSERT by UpsertNotificationMessage. Used by DelOld_NotificationMessages for the 31-day retention cutoff. NC index lead column for efficient purge queries. Smalldatetime = 1-minute precision. |
| 9 | Processed | smalldatetime | NO | - | CODE-BACKED | UTC timestamp of the last state change. Set to GETUTCDATE() on both INSERT and UPDATE by UpsertNotificationMessage. On INSERT = Created (same moment). On UPDATE = when the processor marked the message processed or errored. Delta between Created and Processed = processing latency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No declared FK constraints. Provider values implicitly reference Dictionary.Protocol (checkout=43, worldpay=23) but no FK is enforced.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UpsertNotificationMessage | MessageID, StatusID, Provider, RawMessage, Queue, Topic, Subscription | UPSERT writer | Primary writer. INSERT hardcodes StatusID=1. UPDATE sets Processed=GETUTCDATE(). Returns @NotificationID on insert. |
| Billing.DelOld_NotificationMessages | Created | DELETE writer | Purges records older than @DaysToKeep (default 31) in batches of @BatchSize (default 4500) using a WHILE loop. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.NotificationMessages (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpsertNotificationMessage | Stored Procedure | UPSERT writer - inserts new notifications and updates processing state |
| Billing.DelOld_NotificationMessages | Stored Procedure | Purges old records by Created date |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingNotificationMessages | CLUSTERED PK | MessageID ASC | - | - | Active (FILLFACTOR=95) |
| IX_NotificationMessages_Created | NC | Created ASC | - | - | Active (PAGE compressed) - supports efficient age-based purge by DelOld_NotificationMessages |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingNotificationMessages | PRIMARY KEY | MessageID clustered |

---

## 8. Sample Queries

### 8.1 Check pending (unprocessed) notifications

```sql
SELECT MessageID, Provider, Queue, Created, Processed
FROM Billing.NotificationMessages WITH (NOLOCK)
WHERE StatusID = 1  -- Pending
ORDER BY Created ASC
```

### 8.2 Find failed notifications for investigation

```sql
SELECT MessageID, Provider, Queue, Created, Processed
FROM Billing.NotificationMessages WITH (NOLOCK)
WHERE StatusID = 5  -- Error
  AND Created >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY Created DESC
```

### 8.3 Notification volume by provider and status

```sql
SELECT Provider, StatusID, COUNT(1) AS cnt
FROM Billing.NotificationMessages WITH (NOLOCK)
WHERE Created >= DATEADD(DAY, -1, GETUTCDATE())
GROUP BY Provider, StatusID
ORDER BY Provider, StatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.NotificationMessages | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.NotificationMessages.sql*
