# AffiliateCommission.ReadCreditUnhandledMessages

> Claims and returns stale credit queue messages that haven't been processed within 10 minutes, implementing a dead-letter recovery pattern for the credit commission pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns claimed DateCreated + CreditMessage from queue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ReadCreditUnhandledMessages is the dead-letter recovery consumer for the credit message queue. The AffiliateTraderCreditQueue table acts as a message queue for credit events (deposits, chargebacks) flowing from the trading platform to the commission system. When messages sit in the queue for more than 10 minutes without being processed, this procedure claims and returns them for retry.

This procedure exists as a reliability mechanism. In normal operation, credit messages are consumed quickly from the queue. However, if the primary consumer crashes or encounters errors, messages become stale. This procedure picks up those orphaned messages and returns them for reprocessing, ensuring no credit events are permanently lost.

The UPDATE-OUTPUT pattern sets DateModified to re-claim the message, preventing concurrent consumers from picking up the same message. Messages that fail retry will become eligible again after another 10 minutes.

---

## 2. Business Logic

### 2.1 Stale Message Recovery

**What**: Claims credit queue messages that haven't been processed within 10 minutes.

**Columns/Parameters Involved**: `DateModified`

**Rules**:
- UPDATE sets DateModified = GETUTCDATE() to claim stale messages
- OUTPUT returns DateCreated and CreditMessage for reprocessing
- Stale threshold: DATEADD(minute, 10, DateModified) < GETUTCDATE() (message is 10+ minutes old)
- No batch limit - claims all stale messages
- CreditMessage contains the full credit event payload (JSON/XML) for resubmission to the pipeline

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DateCreated | datetime | - | - | CODE-BACKED | When the credit message was originally enqueued. |
| 2 | CreditMessage | nvarchar(max) | - | - | CODE-BACKED | Full credit event payload for reprocessing. Contains all data needed to resubmit the event to the credit commission pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.AffiliateTraderCreditQueue | READ+WRITE (UPDATE OUTPUT) | Claims stale messages by setting DateModified; outputs message data |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by a scheduled job or health-check service to recover stuck messages.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ReadCreditUnhandledMessages (procedure)
+-- AffiliateCommission.AffiliateTraderCreditQueue (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.AffiliateTraderCreditQueue | Table | UPDATE + OUTPUT for stale message recovery |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit recovery job) | External | Reprocesses stuck credit messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Read unhandled credit messages
```sql
EXEC [AffiliateCommission].[ReadCreditUnhandledMessages]
```

### 8.2 Check for stale messages in the queue
```sql
SELECT COUNT(*) AS StaleCount
FROM [AffiliateCommission].[AffiliateTraderCreditQueue] WITH (NOLOCK)
WHERE DATEADD(MINUTE, 10, DateModified) < GETUTCDATE()
```

### 8.3 View queue health
```sql
SELECT
    COUNT(*) AS TotalMessages,
    SUM(CASE WHEN DATEADD(MINUTE, 10, DateModified) < GETUTCDATE() THEN 1 ELSE 0 END) AS StaleMessages,
    MIN(DateCreated) AS OldestMessage,
    MAX(DateCreated) AS NewestMessage
FROM [AffiliateCommission].[AffiliateTraderCreditQueue] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ReadCreditUnhandledMessages | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.ReadCreditUnhandledMessages.sql*
