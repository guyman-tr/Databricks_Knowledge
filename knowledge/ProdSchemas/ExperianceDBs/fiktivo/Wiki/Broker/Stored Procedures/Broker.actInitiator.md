# Broker.actInitiator

> **DISABLED** (PART-4246) - Service Broker initiator cleanup procedure that drained EndDialog messages from the queInitiator queue and completed conversations. Currently short-circuits with RETURN as part of the Service Broker decommissioning.

| Property | Value |
|----------|-------|
| **Schema** | Broker |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RECEIVE from Broker.queInitiator (DISABLED) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Broker.actInitiator was the Service Broker initiator-side conversation cleanup procedure. In the Service Broker message pattern, when a target service finishes processing a message and ends its side of the conversation, the initiator receives an EndDialog message. This procedure drained those EndDialog messages from Broker.queInitiator and completed the conversations on the initiator side, preventing the queue from accumulating unprocessed dialog-completion messages.

This procedure exists (existed) because Service Broker conversations require cleanup on both sides. Without this procedure, the queInitiator queue would fill with unprocessed EndDialog messages, and sys.conversation_endpoints would grow unboundedly with stale endpoints, eventually degrading Service Broker performance.

**CURRENTLY DISABLED**: As of April 2025 (PART-4246 - DisableAffiliateServiceBroker), the procedure immediately returns without processing. The entire Service Broker infrastructure for affiliate processing is being decommissioned, likely replaced by the AKS-based service architecture (e.g., aff-clicksimp) and the ADF batch pipeline (BILoad schema).

---

## 2. Business Logic

### 2.1 EndDialog Drain Loop (DISABLED)

**What**: Continuously receives and processes EndDialog messages from the initiator queue until empty.

**Columns/Parameters Involved**: `@ConversationHandle`, `@MessageTypeName`

**Rules**:
- **CURRENTLY DISABLED**: First executable line is `RETURN` - procedure exits immediately
- (Historical behavior below for reference)
- WHILE (1=1) loop with WAITFOR RECEIVE, TIMEOUT 500ms
- Receives one message at a time from Broker.queInitiator
- If @@ROWCOUNT = 0 (timeout with no message): COMMIT and BREAK (loop exits)
- If message type is 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog': END CONVERSATION to complete the dialog
- Other message types are silently consumed (no action beyond COMMIT)
- Each iteration runs within its own BEGIN TRANSACTION / COMMIT

### 2.2 Service Broker Decommissioning

**What**: The entire Broker schema's Service Broker infrastructure is being phased out.

**Columns/Parameters Involved**: N/A

**Rules**:
- PART-4246 (Apr 2025, Noga): Added `RETURN` before the WHILE loop to disable the procedure
- Comment: "Before dropping PART-4246_DisableAffiliateServiceBroker"
- This suggests the procedure will eventually be dropped entirely
- The Service Broker pattern is being replaced by AKS microservices and ADF batch pipelines

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure takes no parameters. It operates on the Service Broker queue directly.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | Procedure has no input or output parameters. It operates on the Broker.queInitiator queue internally. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Broker.queInitiator | RECEIVE (DISABLED) | Would drain EndDialog messages from the initiator queue |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Service Broker Activation (internal) | - | Queue Activation | Would be activated by messages arriving on queInitiator (currently disabled) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Broker.actInitiator (procedure - DISABLED)
+-- Broker.queInitiator (Service Broker queue)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Broker.queInitiator | Service Broker Queue | RECEIVE source (currently disabled) |

### 6.2 Objects That Depend On This

No active dependents (procedure is disabled).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN (line 16) | Disabled | Procedure exits immediately without processing - part of PART-4246 decommissioning |
| WAITFOR TIMEOUT 500 | Polling Interval | (Historical) 500ms wait before breaking the drain loop when no messages are available |

---

## 8. Sample Queries

### 8.1 Check if the procedure is disabled (verify RETURN exists)
```sql
SELECT OBJECT_DEFINITION(OBJECT_ID('Broker.actInitiator'))
```

### 8.2 Check queue depth on the initiator queue
```sql
SELECT COUNT(*) AS PendingMessages
FROM Broker.queInitiator WITH (NOLOCK)
```

### 8.3 Check for stale conversation endpoints (accumulated since disabling)
```sql
SELECT state, COUNT(*) AS EndpointCount
FROM sys.conversation_endpoints WITH (NOLOCK)
GROUP BY state
ORDER BY EndpointCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-4246 (referenced in SQL comments) | Jira | DisableAffiliateServiceBroker - disabled this procedure as part of Service Broker decommissioning (Apr 2025, Noga) |

No Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Broker.actInitiator | Type: Stored Procedure | Source: fiktivo/Broker/Stored Procedures/Broker.actInitiator.sql*
