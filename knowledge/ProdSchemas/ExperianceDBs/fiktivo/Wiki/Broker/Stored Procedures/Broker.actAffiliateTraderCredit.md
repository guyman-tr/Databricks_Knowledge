# Broker.actAffiliateTraderCredit

> Service Broker queue consumer that dequeues a single affiliate trader credit message from the receiver queue, returns it as XML via an OUTPUT parameter, and cleans up the conversation endpoint.

| Property | Value |
|----------|-------|
| **Schema** | Broker |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RECEIVE from Broker.queAffiliateTraderCreditReceiver |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Broker.actAffiliateTraderCredit is a SQL Server Service Broker activation procedure that dequeues one message at a time from the Broker.queAffiliateTraderCreditReceiver queue. Each message contains XML data representing an affiliate trader credit event (e.g., a customer's deposit or financial credit event that triggers affiliate commission processing). The dequeued message is returned via an OUTPUT parameter for the calling service to process.

This procedure exists as part of the event-driven affiliate commission pipeline. When a credit event occurs on the eToro platform, a Service Broker message is sent to this queue. The affiliate service continuously polls this procedure (or uses SqlDependency) to consume messages and process commission calculations. This is the real-time counterpart to the batch ADF pipeline (BILoad schema).

The procedure RECEIVEs a single message within a transaction, assigns the message body to the OUTPUT parameter, ends the conversation with CLEANUP, and commits. It also handles cleanup of stale conversation endpoints in the 'CD' (closed) state.

---

## 2. Business Logic

### 2.1 Single-Message Dequeue Pattern

**What**: Receives exactly one message per invocation from the Service Broker queue.

**Columns/Parameters Involved**: `@AffiliateTraderCreditInfo` (OUTPUT)

**Rules**:
- RECEIVE TOP (1) from Broker.queAffiliateTraderCreditReceiver
- Message body is assigned directly to the OUTPUT parameter as XML
- If no message is available, @AffiliateTraderCreditInfo remains NULL
- The conversation handle is captured for cleanup
- Entire operation runs within BEGIN TRAN / COMMIT with TRY/CATCH

### 2.2 Conversation Cleanup

**What**: Ends the conversation and cleans up stale endpoints.

**Columns/Parameters Involved**: `@ConversationHandle`

**Rules**:
- After RECEIVE: END CONVERSATION WITH CLEANUP (immediately closes the dialog)
- Post-transaction: checks sys.conversation_endpoints for stale 'CD' (closed) state conversations with the same handle
- If found, performs a second END CONVERSATION WITH CLEANUP to remove the endpoint
- This prevents sys.conversation_endpoints from growing unboundedly

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTraderCreditInfo | xml | YES | - (OUTPUT) | CODE-BACKED | OUTPUT parameter containing the dequeued message body as XML. Contains affiliate trader credit event data (customer credit/deposit details for commission processing). NULL if no message was available in the queue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Broker.queAffiliateTraderCreditReceiver | RECEIVE | Dequeues messages from this Service Broker queue |
| - | sys.conversation_endpoints | READ | Checks for stale conversation endpoints to clean up |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Affiliate Service (external) | - | Caller | Application service polls this procedure to consume credit events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Broker.actAffiliateTraderCredit (procedure)
+-- Broker.queAffiliateTraderCreditReceiver (Service Broker queue)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Broker.queAffiliateTraderCreditReceiver | Service Broker Queue | RECEIVE source for credit event messages |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate Service (external) | Application | Consumes credit events for commission processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRAN / COMMIT | Atomicity | RECEIVE and END CONVERSATION are atomic - message is either fully consumed or not at all |
| TRY/CATCH | Error Handling | Rolls back on error (IF @@TranCount = 1 ROLLBACK) to prevent message loss |
| END CONVERSATION WITH CLEANUP | Resource Management | Immediately cleans up conversation resources instead of waiting for normal dialog lifecycle |

---

## 8. Sample Queries

### 8.1 Consume one credit event message
```sql
DECLARE @CreditXML XML
EXEC Broker.actAffiliateTraderCredit @AffiliateTraderCreditInfo = @CreditXML OUTPUT
SELECT @CreditXML AS MessageContent
```

### 8.2 Check queue depth (how many messages pending)
```sql
SELECT COUNT(*) AS PendingMessages
FROM Broker.queAffiliateTraderCreditReceiver WITH (NOLOCK)
```

### 8.3 Check for stale conversation endpoints
```sql
SELECT conversation_handle, state, lifetime
FROM sys.conversation_endpoints WITH (NOLOCK)
WHERE state = 'CD'
ORDER BY lifetime DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| (SQL comment: Ran Ovadia, 24/05/2020) | Code Comment | Created for new Queue service |
| PART-4246 (referenced in actInitiator) | Jira | DisableAffiliateServiceBroker - Service Broker infrastructure being decommissioned (Apr 2025). This procedure may be affected by the phase-out. |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Broker.actAffiliateTraderCredit | Type: Stored Procedure | Source: fiktivo/Broker/Stored Procedures/Broker.actAffiliateTraderCredit.sql*
