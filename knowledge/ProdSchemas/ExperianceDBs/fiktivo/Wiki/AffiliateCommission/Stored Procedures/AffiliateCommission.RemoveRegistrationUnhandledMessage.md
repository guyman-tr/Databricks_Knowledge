# AffiliateCommission.RemoveRegistrationUnhandledMessage

> Deletes a processed registration queue message from AffiliateTraderRegistrationQueue after the registration event has been successfully handled by the commission pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from AffiliateTraderRegistrationQueue by ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveRegistrationUnhandledMessage completes the registration message queue lifecycle. The AffiliateTraderRegistrationQueue acts as a durable message queue between the user registration system and the commission engine. When a new user signs up through an affiliate link, a registration message is enqueued. If the primary consumer fails, ReadRegistrationUnhandledMessages picks up stale messages for retry. Once a message is successfully processed, this procedure removes it from the queue.

The queue pattern mirrors the credit queue (AffiliateTraderCreditQueue / RemoveCreditUnhandledMessage) but is dedicated to registration events. Keeping the two event types in separate queues prevents a backlog in one type from blocking the other and allows independent scaling of consumers.

By deleting the queue row by its primary key ID, this procedure ensures precise cleanup. Even if the same registration is somehow enqueued multiple times (e.g., due to retry logic upstream), each queue entry is independently tracked and removed only when its specific processing attempt succeeds.

---

## 2. Business Logic

### 2.1 Queue Message Acknowledgment

**What**: Removes a registration queue message after successful processing, acknowledging receipt and completion.

**Columns/Parameters Involved**: `@ID`, `AffiliateTraderRegistrationQueue.ID`

**Rules**:
- DELETE FROM AffiliateTraderRegistrationQueue WHERE ID = @ID
- Called only after the registration event has been fully processed
- If no matching row exists, the DELETE is a no-op
- Acts as the "acknowledge" step in the message queue pattern

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | BIGINT (IN) | NO | - | CODE-BACKED | Primary key of the AffiliateTraderRegistrationQueue row to delete. Corresponds to the ID returned by ReadRegistrationUnhandledMessages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | AffiliateCommission.AffiliateTraderRegistrationQueue | WRITE (DELETE) | Removes the queue message by primary key |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline after successful registration event processing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveRegistrationUnhandledMessage (procedure)
+-- AffiliateCommission.AffiliateTraderRegistrationQueue (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.AffiliateTraderRegistrationQueue | Table | DELETE by primary key |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Acknowledges processed registration queue messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a processed registration queue message
```sql
EXEC [AffiliateCommission].[RemoveRegistrationUnhandledMessage] @ID = 30210
```

### 8.2 Check if a registration message is still in the queue
```sql
SELECT ID, RegistrationMessage, DateCreated, DateModified
FROM [AffiliateCommission].[AffiliateTraderRegistrationQueue] WITH (NOLOCK)
WHERE ID = 30210
```

### 8.3 Monitor registration queue depth and age
```sql
SELECT COUNT(*) AS QueueDepth,
    MIN(DateCreated) AS OldestMessage,
    MAX(DateCreated) AS NewestMessage,
    SUM(CASE WHEN DATEADD(MINUTE, 10, DateModified) < GETUTCDATE() THEN 1 ELSE 0 END) AS StaleMessages
FROM [AffiliateCommission].[AffiliateTraderRegistrationQueue] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveRegistrationUnhandledMessage | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveRegistrationUnhandledMessage.sql*
