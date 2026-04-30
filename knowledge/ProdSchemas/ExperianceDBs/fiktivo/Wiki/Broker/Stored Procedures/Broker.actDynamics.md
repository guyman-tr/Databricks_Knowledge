# Broker.actDynamics

> Service Broker queue consumer that dequeues a single dynamics/lead message from the queDynamics queue, returning it as an NVARCHAR(MAX) OUTPUT parameter for the affiliate server to process registration and lead tracking events.

| Property | Value |
|----------|-------|
| **Schema** | Broker |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RECEIVE from Broker.queDynamics |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Broker.actDynamics is a SQL Server Service Broker activation procedure that dequeues messages from the Broker.queDynamics queue. Per the inline documentation, this queue receives data from Customer.RegisterReal/Demo procedures when new customer registrations occur. The affiliate server continuously listens for arrivals in this queue (using SqlDependency or scheduled polling) to process lead and registration events for affiliate tracking.

This procedure exists to bridge the customer registration system with the affiliate tracking system. When a customer registers (real or demo account), the registration procedure sends a Service Broker message containing the lead/registration details. This procedure dequeues that message so the affiliate server can attribute the registration to the correct affiliate, update tracking records, and trigger any registration-based commission events.

The procedure checks for message availability before opening a transaction (EXISTS guard on queDynamics), RECEIVEs a single message, casts the body to XML then to NVARCHAR(MAX) for the OUTPUT parameter, ends the conversation with CLEANUP, and commits.

---

## 2. Business Logic

### 2.1 Lead/Registration Event Dequeue

**What**: Consumes registration event messages posted by Customer.RegisterReal/Demo.

**Columns/Parameters Involved**: `@LeadInfo` (OUTPUT)

**Rules**:
- EXISTS guard: only enters the transaction if the queue has messages (avoids unnecessary transaction overhead)
- RECEIVE TOP(1) from Broker.queDynamics
- Message body is cast to XML, then to NVARCHAR(MAX) for the OUTPUT parameter
- If no message exists (guard fails), @LeadInfo remains at its initial value (NULL or caller-set)
- Single message per invocation - the caller loops externally

### 2.2 Message Processing Pipeline

**What**: Part of the registration-to-affiliate attribution pipeline.

**Columns/Parameters Involved**: `@LeadInfo`

**Rules**:
- Initiator: Customer.RegisterReal or Customer.RegisterDemo sends message to Service Broker
- Queue: Broker.queDynamics receives and stores the message
- Consumer: This procedure (actDynamics) dequeues the message
- Processor: Affiliate Server reads the @LeadInfo XML and creates tracking/registration records
- The message contains lead information including customer details, referral affiliate, banner, campaign

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LeadInfo | nvarchar(max) | YES | - (OUTPUT) | CODE-BACKED | OUTPUT parameter containing the dequeued message as an NVARCHAR(MAX) string (originally XML). Contains lead/registration event data from Customer.RegisterReal/Demo: customer details, referral affiliate, banner, campaign. NULL if no message was available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Broker.queDynamics | RECEIVE | Dequeues lead/registration event messages |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Affiliate Server (external) | - | Caller | Polls this procedure (SqlDependency or scheduled) to consume registration events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Broker.actDynamics (procedure)
+-- Broker.queDynamics (Service Broker queue)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Broker.queDynamics | Service Broker Queue | RECEIVE source for lead/registration event messages |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate Server (external) | Application | Consumes registration events for affiliate tracking and attribution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXISTS guard | Optimization | Skips transaction entirely if queue is empty - avoids unnecessary lock acquisition |
| BEGIN TRANSACTION / COMMIT | Atomicity | RECEIVE and END CONVERSATION are atomic |
| END CONVERSATION WITH CLEANUP | Resource Management | Immediately cleans up conversation resources |

---

## 8. Sample Queries

### 8.1 Consume one dynamics/lead message
```sql
DECLARE @LeadXML NVARCHAR(MAX)
EXEC Broker.actDynamics @LeadInfo = @LeadXML OUTPUT
SELECT @LeadXML AS MessageContent
```

### 8.2 Check queue depth
```sql
SELECT COUNT(*) AS PendingMessages
FROM Broker.queDynamics WITH (NOLOCK)
```

### 8.3 Parse the XML content from a dequeued message
```sql
DECLARE @LeadXML NVARCHAR(MAX)
EXEC Broker.actDynamics @LeadInfo = @LeadXML OUTPUT
IF @LeadXML IS NOT NULL
    SELECT CAST(@LeadXML AS XML).value('(/Root/CID)[1]', 'BIGINT') AS CID,
           CAST(@LeadXML AS XML).value('(/Root/AffiliateID)[1]', 'INT') AS AffiliateID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| (Inline SQL comments) | Code Comment | Describes the full pipeline: Customer.RegisterReal/Demo initiates -> queDynamics receives -> Affiliate Server consumes via SqlDependency or polling |
| PART-4246 (referenced in actInitiator) | Jira | DisableAffiliateServiceBroker - Service Broker infrastructure being decommissioned. This procedure may be affected. |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Broker.actDynamics | Type: Stored Procedure | Source: fiktivo/Broker/Stored Procedures/Broker.actDynamics.sql*
