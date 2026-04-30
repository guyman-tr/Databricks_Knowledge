# AffiliateCommission.RemoveCreditUnhandledMessage

> Deletes a processed credit queue message from AffiliateTraderCreditQueue after the credit event has been successfully handled by the commission pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from AffiliateTraderCreditQueue by CreditID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveCreditUnhandledMessage completes the credit message queue lifecycle. The AffiliateTraderCreditQueue acts as a durable message queue between the trading platform and the commission engine. Credit events (deposits, withdrawals, chargebacks) are enqueued by LoadAffiliateTraderCreditQueue, claimed by ReadCreditUnhandledMessages when they become stale, and ultimately processed by the commission pipeline. Once processing succeeds, this procedure removes the message from the queue.

The queue exists to bridge the gap between the high-throughput trading platform and the commission calculation engine. Without it, credit events could be lost during transient failures. The explicit delete-after-processing pattern provides at-least-once delivery semantics: a message remains in the queue until the consumer explicitly confirms success by calling this procedure.

By keying the delete on @CreditID rather than a queue row ID, this procedure naturally handles the case where a credit was requeued or retried - all queue entries for that credit are cleaned up in a single call.

---

## 2. Business Logic

### 2.1 Queue Message Acknowledgment

**What**: Removes a credit queue message after successful processing, acknowledging receipt and completion.

**Columns/Parameters Involved**: `@CreditID`, `AffiliateTraderCreditQueue.CreditID`

**Rules**:
- DELETE FROM AffiliateTraderCreditQueue WHERE CreditID = @CreditID
- Called only after the credit event has been fully processed
- If no matching row exists, the DELETE is a no-op
- Acts as the "acknowledge" step in the message queue pattern

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | bigint (IN) | NO | - | CODE-BACKED | The credit identifier whose queue message should be removed. Matches CreditID in AffiliateTraderCreditQueue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CreditID | AffiliateCommission.AffiliateTraderCreditQueue | WRITE (DELETE) | Removes the queue message by CreditID |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline after successful credit event processing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveCreditUnhandledMessage (procedure)
+-- AffiliateCommission.AffiliateTraderCreditQueue (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.AffiliateTraderCreditQueue | Table | DELETE by CreditID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Acknowledges processed credit queue messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a processed credit queue message
```sql
EXEC [AffiliateCommission].[RemoveCreditUnhandledMessage] @CreditID = 99501
```

### 8.2 Check if a credit still has a pending queue message
```sql
SELECT CreditID, CreditMessage, DateCreated, DateModified
FROM [AffiliateCommission].[AffiliateTraderCreditQueue] WITH (NOLOCK)
WHERE CreditID = 99501
```

### 8.3 Monitor queue depth and age
```sql
SELECT COUNT(*) AS QueueDepth,
    MIN(DateCreated) AS OldestMessage,
    MAX(DateCreated) AS NewestMessage,
    SUM(CASE WHEN DATEADD(MINUTE, 10, DateModified) < GETUTCDATE() THEN 1 ELSE 0 END) AS StaleMessages
FROM [AffiliateCommission].[AffiliateTraderCreditQueue] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveCreditUnhandledMessage | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveCreditUnhandledMessage.sql*
